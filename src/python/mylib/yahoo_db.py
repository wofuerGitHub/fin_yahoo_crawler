"""Schema-reflecting MySQL access for reference reads and raw-only upserts."""

from __future__ import annotations

from typing import Any, Iterable

from sqlalchemy import MetaData, Table, create_engine, inspect, select, update
from sqlalchemy.dialects.mysql import insert as mysql_insert
from sqlalchemy.engine import URL

from mylib.config import validate_identifier


class Database:
    def __init__(self, config: dict[str, Any]):
        db = config["database"]
        self.schema = validate_identifier(db["schema"])
        self.tables = {key: validate_identifier(value) for key, value in db["tables"].items()}
        url = URL.create(
            "mysql+mysqlconnector",
            username=str(db["user"]),
            password=str(db["password"]),
            host=str(db["host"]),
            port=int(db["port"]),
            database=self.schema,
        )
        self.engine = create_engine(url, pool_pre_ping=True, future=True)
        self.metadata = MetaData()
        self._reflected: dict[str, Table] = {}

    def close(self) -> None:
        self.engine.dispose()

    def table(self, logical_name: str) -> Table:
        if logical_name not in self.tables:
            raise KeyError(f"No table mapping configured for {logical_name}")
        table_name = self.tables[logical_name]
        if table_name not in self._reflected:
            inspector = inspect(self.engine)
            if not inspector.has_table(table_name, schema=self.schema):
                raise RuntimeError(f"Required MySQL table {self.schema}.{table_name} does not exist")
            self._reflected[table_name] = Table(table_name, self.metadata, schema=self.schema, autoload_with=self.engine)
        return self._reflected[table_name]

    @staticmethod
    def _unique_candidates(table: Table) -> list[set[str]]:
        candidates = []
        primary_key = {column.name for column in table.primary_key.columns}
        if primary_key:
            candidates.append(primary_key)
        for constraint in table.constraints:
            if getattr(constraint, "unique", False):
                candidate = {column.name for column in constraint.columns}
                if candidate:
                    candidates.append(candidate)
        for index in table.indexes:
            if index.unique:
                candidate = {column.name for column in index.columns}
                if candidate:
                    candidates.append(candidate)
        if not candidates:
            raise RuntimeError(f"Table {table.fullname} has no primary or unique key; refusing unsafe upsert")
        return candidates

    def upsert(self, logical_name: str, records: Iterable[dict[str, Any]]) -> int:
        table = self.table(logical_name)
        unique_candidates = self._unique_candidates(table)
        accepted = []
        table_columns = set(table.c.keys())
        for original in records:
            record = {key: value for key, value in original.items() if key in table_columns}
            if record:
                key = next((candidate for candidate in unique_candidates if candidate.issubset(record)), None)
                if key is None:
                    choices = [sorted(candidate) for candidate in unique_candidates]
                    raise RuntimeError(f"Cannot identify an upsert row for {table.fullname}; available unique keys: {choices}")
                accepted.append((record, key))
        if not accepted:
            return 0

        written = 0
        with self.engine.begin() as connection:
            for record, unique_columns in accepted:
                statement = mysql_insert(table).values(**record)
                updates = {
                    key: statement.inserted[key]
                    for key in record
                    if key not in unique_columns and record[key] is not None
                }
                if updates:
                    statement = statement.on_duplicate_key_update(**updates)
                connection.execute(statement)
                written += 1
        return written

    def rows(self, logical_name: str) -> list[dict[str, Any]]:
        table = self.table(logical_name)
        with self.engine.connect() as connection:
            return [dict(row) for row in connection.execute(select(table)).mappings().all()]

    def update_reference_flag(self, logical_name: str, key_name: str, key_value: Any, flag_name: str, value: bool) -> bool:
        table = self.table(logical_name)
        if key_name not in table.c or flag_name not in table.c:
            return False
        with self.engine.begin() as connection:
            result = connection.execute(update(table).where(table.c[key_name] == key_value).values({flag_name: value}))
        return result.rowcount > 0

    def existing_symbols(self, logical_name: str) -> dict[str, Any]:
        table = self.table(logical_name)
        if "symbol" not in table.c:
            raise RuntimeError(f"Expected a symbol column in {table.fullname}")
        selected = [table.c.symbol]
        if "updated" in table.c:
            selected.append(table.c.updated)
        with self.engine.connect() as connection:
            return {str(row["symbol"]): row.get("updated") for row in connection.execute(select(*selected)).mappings()}