from datetime import date
from decimal import Decimal

import pytest

from fundamental_worker import Formula, compile_formulas, transform


def row(metric, value, period="annual", symbol="BMW.DE", day="2025-12-31", currency="EUR"):
    return dict(symbol=symbol, period_type=period, report_date=day, metric=metric, value=value, currency=currency)


def test_groups_never_share_inputs():
    sources = {"income": [row("GrossProfit", -20), row("TotalRevenue", 100),
                          row("DilutedAverageShares", 10), row("GrossProfit", 8, "quarterly"),
                          row("TotalRevenue", 2, symbol="OTHER"),
                          row("TotalRevenue", 3, day="2024-12-31")],
               "cashflow": [row("OperatingCashFlow", 50), row("OperatingCashFlow", 30, "quarterly")],
               "balance": []}
    formulas = {"ratio": Formula("income.GrossProfit/income.TotalRevenue"),
                "cps": Formula("cashflow.OperatingCashFlow/income.DilutedAverageShares"),
                "complex": Formula("(abs(income.GrossProfit))^2")}
    results = {(r['symbol'], r['period_type'], r['report_date']): r for r in transform(sources, formulas)}
    assert len(results) == 4
    annual = results['BMW.DE', 'annual', date(2025, 12, 31)]
    assert (annual['ratio'], annual['cps'], annual['complex']) == (Decimal('-.2'), 5, 400)
    quarterly = results['BMW.DE', 'quarterly', date(2025, 12, 31)]
    assert quarterly['ratio'] is None and quarterly['cps'] is None
    assert quarterly['complex'] == 64


@pytest.mark.parametrize('expression', ['__import__("os")', 'income.__class__.__name__',
                                      'income.x[0]', 'sum(income.x)', 'income.x > 2', 'abs(x=1)'])
def test_rejects_unsafe_formulas(expression):
    with pytest.raises(ValueError):
        Formula(expression)


@pytest.mark.parametrize('expression', ['1/0', 'income.Missing+1', '2^101', '(-1)^0.5'])
def test_undefined_results_are_null(expression):
    assert Formula(expression).evaluate({}) is None


def test_zero_and_decimal_precision():
    assert Formula('income.a-income.b').evaluate({'income': {'a': '0.3', 'b': '0.3'}}) == 0
    assert Formula('2+3*4^2').evaluate({}) == 50


def test_duplicate_metric_is_rejected():
    with pytest.raises(ValueError, match='Duplicate'):
        transform({'income': [row('A', 1), row('A', 2)], 'balance': [], 'cashflow': []}, {'x': Formula('income.A')})


def test_currency_is_part_of_group_and_always_written():
    sources = {'income': [row('Profit', 10), row('Revenue', 20),
                          row('Profit', 30, currency='USD')],
               'balance': [], 'cashflow': []}
    results = {r['currency']: r for r in transform(sources, {'ratio': Formula('income.Profit/income.Revenue')})}
    assert len(results) == 2
    assert results['EUR']['ratio'] == Decimal('.5')
    assert results['USD']['ratio'] is None


@pytest.mark.parametrize('currency', [None, '', ' '])
def test_missing_currency_is_rejected(currency):
    with pytest.raises(ValueError, match='Missing currency'):
        transform({'income': [row('A', 1, currency=currency)], 'balance': [], 'cashflow': []}, {'x': Formula('income.A')})


def test_output_cannot_replace_group_keys():
    with pytest.raises(ValueError):
        compile_formulas({'fundamental': {'transformations': {'fundamental.symbol': '1'}}})


def test_mysql_wide_upsert_and_null_refresh():
    import os
    import uuid
    from sqlalchemy import create_engine, text
    from sqlalchemy.engine import make_url
    from mylib.yahoo_db import Database
    from fundamental_worker import update

    url = os.environ.get('MYSQL_TEST_URL')
    if not url:
        pytest.skip('Set MYSQL_TEST_URL for isolated MySQL integration')
    parsed = make_url(url)
    assert parsed.database.startswith('test_')
    prefix = 'etl_' + uuid.uuid4().hex[:10]
    tables = {key: prefix + '_' + key for key in ('income_2', 'balance_2', 'cashflow_2', 'fun')}
    config = {'database': dict(host=parsed.host, port=parsed.port, schema=parsed.database,
                              user=parsed.username, password=parsed.password, tables=tables),
              'fundamental': {'transformations': {'ratio': 'income.Profit/income.Revenue'}}}
    engine = create_engine(url)
    db = Database(config)
    try:
        with engine.begin() as c:
            for name in ('income_2', 'balance_2', 'cashflow_2'):
                c.execute(text(f'CREATE TABLE `{tables[name]}` (symbol VARCHAR(32), period_type VARCHAR(16), report_date DATE, metric VARCHAR(128), value DECIMAL(30,6), currency VARCHAR(10))'))
            c.execute(text(f'CREATE TABLE `{tables["fun"]}` (id BIGINT AUTO_INCREMENT PRIMARY KEY, symbol VARCHAR(32) NOT NULL, period_type VARCHAR(16) NOT NULL, report_date DATE NOT NULL, currency VARCHAR(10) NOT NULL, ratio DECIMAL(30,6), UNIQUE(symbol,period_type,report_date,currency))'))
            for period in ('annual', 'quarterly'):
                for metric, value in (('Profit', 10), ('Revenue', 20)):
                    c.execute(text(f'INSERT INTO `{tables["income_2"]}` VALUES (:s,:p,:d,:m,:v,\'EUR\')'), dict(s='BMW.DE', p=period, d='2025-12-31', m=metric, v=value))
            for metric, value in (('Profit', 60), ('Revenue', 20)):
                c.execute(text(f'INSERT INTO `{tables["income_2"]}` VALUES (:s,:p,:d,:m,:v,:c)'), dict(s='BMW.DE', p='annual', d='2025-12-31', m=metric, v=value, c='USD'))
        assert update(config, db) == 3
        assert update(config, db) == 3
        assert len(db.rows('fun')) == 3
        assert {r['currency'] for r in db.rows('fun')} == {'EUR', 'USD'}
        with engine.begin() as c:
            c.execute(text(f'UPDATE `{tables["income_2"]}` SET value=0 WHERE metric="Revenue" AND period_type="annual" AND currency="EUR"'))
        update(config, db)
        result = {(r['period_type'], r['currency']): r['ratio'] for r in db.rows('fun')}
        assert result == {('annual', 'EUR'): None, ('quarterly', 'EUR'): Decimal('.5'), ('annual', 'USD'): Decimal('3')}
    finally:
        db.close()
        with engine.begin() as c:
            for table in tables.values():
                c.execute(text(f'DROP TABLE IF EXISTS `{table}`'))
        engine.dispose()
