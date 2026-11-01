"""Transform grouped row-per-metric statements into one wide fundamental row."""

from __future__ import annotations

import argparse
import ast
import operator
import time
from datetime import date, datetime
from decimal import Decimal, DecimalException, localcontext

from sqlalchemy import select
from sqlalchemy.dialects.mysql import insert

from mylib.config import load_config, validate_identifier
from mylib.write_log import create_logger
from mylib.yahoo_db import Database

KEY = ("symbol", "period_type", "report_date", "currency")
SOURCES = ("income", "balance", "cashflow")
OPS = {ast.Add: operator.add, ast.Sub: operator.sub, ast.Mult: operator.mul,
       ast.Div: operator.truediv, ast.Pow: operator.pow}


class Formula:
    """Validated expression interpreter; never executes Python code."""

    def __init__(self, expression):
        if not isinstance(expression, str) or len(expression) > 2048:
            raise ValueError("Formula must be a string of at most 2048 characters")
        self.tree = ast.parse(expression.replace("^", "**"), mode="eval").body
        if sum(1 for _ in ast.walk(self.tree)) > 256:
            raise ValueError("Formula is too complex")
        self.validate(self.tree)

    def validate(self, node):
        if isinstance(node, ast.Constant) and type(node.value) in (int, float):
            if not Decimal(str(node.value)).is_finite():
                raise ValueError("Non-finite constant")
        elif isinstance(node, ast.Attribute) and isinstance(node.value, ast.Name) and node.value.id in SOURCES:
            validate_identifier(node.attr)
        elif isinstance(node, ast.BinOp) and type(node.op) in OPS:
            self.validate(node.left)
            self.validate(node.right)
        elif isinstance(node, ast.UnaryOp) and isinstance(node.op, (ast.UAdd, ast.USub)):
            self.validate(node.operand)
        elif (isinstance(node, ast.Call) and isinstance(node.func, ast.Name)
              and not node.keywords and (
                  (node.func.id == "abs" and len(node.args) == 1)
                  or (node.func.id == "coalesce" and len(node.args) >= 2))):
            for argument in node.args:
                self.validate(argument)
        else:
            raise ValueError("Formula supports source.metric, numbers, + - * / ^ **, abs() and coalesce(a, b, ...) only")

    def evaluate(self, sources):
        def visit(node):
            if isinstance(node, ast.Constant):
                return Decimal(str(node.value))
            if isinstance(node, ast.Attribute):
                value = sources.get(node.value.id, {}).get(node.attr)
                if value is None:
                    raise LookupError(node.attr)
                number = Decimal(str(value))
                if not number.is_finite():
                    raise LookupError(node.attr)
                return number
            if isinstance(node, ast.UnaryOp):
                value = visit(node.operand)
                return -value if isinstance(node.op, ast.USub) else value
            if isinstance(node, ast.Call):
                if node.func.id == "coalesce":
                    for argument in node.args:
                        try:
                            value = visit(argument)
                            if value.is_finite():
                                return value
                        except (LookupError, ArithmeticError, DecimalException, ValueError):
                            continue
                    raise LookupError("All coalesce arguments are NULL")
                return abs(visit(node.args[0]))
            left, right = visit(node.left), visit(node.right)
            if isinstance(node.op, ast.Pow) and abs(right) > 100:
                raise ArithmeticError("Exponent exceeds limit")
            return OPS[type(node.op)](left, right)

        try:
            with localcontext() as context:
                context.prec = 38
                value = visit(self.tree)
                return value if value.is_finite() else None
        except (LookupError, ArithmeticError, DecimalException, ValueError):
            return None


def compile_formulas(config):
    transformations = config.get("fundamental", {}).get("transformations")
    if not isinstance(transformations, dict) or not transformations:
        raise ValueError("yahoo.fundamental.transformations must be a nonempty object")
    result = {}
    for target, expression in transformations.items():
        column = target.removeprefix("fundamental.")
        validate_identifier(column)
        if column in KEY or column in result:
            raise ValueError(f"Reserved or duplicate output column: {column}")
        result[column] = Formula(expression)
    return result


def transform(source_rows, formulas):
    groups = {}
    for source in SOURCES:
        for row in source_rows[source]:
            key = tuple(row[name] for name in KEY)
            symbol, period, report_date, currency = key
            if isinstance(report_date, datetime):
                report_date = report_date.date()
            elif isinstance(report_date, str):
                report_date = date.fromisoformat(report_date)
            if not symbol or period not in ("annual", "quarterly") or not isinstance(report_date, date):
                raise ValueError(f"Invalid statement group: {key}")
            if not isinstance(currency, str) or not currency.strip():
                raise ValueError(f"Missing currency in statement group: {key}")
            key = symbol, period, report_date, currency
            metrics = groups.setdefault(key, {}).setdefault(source, {})
            if row["metric"] in metrics:
                raise ValueError(f"Duplicate {source} metric in group {key}: {row['metric']}")
            metrics[row["metric"]] = row["value"]
    return [dict(zip(KEY, key), **{name: formula.evaluate(values) for name, formula in formulas.items()})
            for key, values in groups.items()]


def update(config, database):
    formulas = compile_formulas(config)
    table = database.table("fun")
    required = set(KEY) | set(formulas)
    if not required.issubset(table.c.keys()):
        raise ValueError(f"Destination is missing columns: {sorted(required - set(table.c.keys()))}")
    if table.c.currency.nullable:
        raise ValueError("Destination currency must be NOT NULL to guarantee unique groups")
    keys = database._unique_candidates(table)
    if set(KEY) not in keys:
        raise ValueError("Destination requires UNIQUE(symbol, period_type, report_date, currency)")
    # Other uniqueness rules must not cause two different groups to collide.
    for key in keys:
        if not set(KEY).issubset(key) and not (
            len(key) == 1 and table.c[next(iter(key))].primary_key
            and table.c[next(iter(key))].autoincrement is True
            and next(iter(key)) not in required
        ):
            raise ValueError(f"Destination unique key can mix groups: {sorted(key)}")
    with database.engine.begin() as connection:
        rows = {}
        for source in SOURCES:
            source_table = database.table(f"{source}_2")
            rows[source] = list(connection.execute(select(source_table)).mappings())
        records = transform(rows, formulas)
        for record in records:
            statement = insert(table).values(**record)
            connection.execute(statement.on_duplicate_key_update(
                **{name: statement.inserted[name] for name in formulas}))
    return len(records)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", default="config.json")
    parser.add_argument("--once", action="store_true")
    args = parser.parse_args(argv)
    config = load_config(args.config)
    config["database"]["tables"].setdefault("fun", "raw_fun_2")
    logger = create_logger(config)
    delay = float(config["control"].get("fundamental_delay", 3600))
    if delay <= 0:
        raise ValueError("fundamental_delay must be positive")
    database = Database(config)
    try:
        while True:
            try:
                logger.info("Fundamental ETL: wrote %s groups", update(config, database))
            except Exception:
                logger.exception("Fundamental ETL failed")
                if args.once:
                    raise
            if args.once:
                return
            time.sleep(delay)
    except KeyboardInterrupt:
        logger.info("Fundamental ETL stopped")
    finally:
        database.close()


if __name__ == "__main__":
    main()
