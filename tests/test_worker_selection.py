from mylib.worker_common import select_fundamental_symbols


def test_fundamental_selection_uses_fmp_reference_semantics():
    rows = [
        {"symbol": "ABC", "symbol_fundamental": "ABC.A"},
        {"symbol": "XYZ", "symbol_fundamental": None},
    ]

    assert select_fundamental_symbols(rows, update_all=False) == ["ABC.A", "XYZ"]
    assert select_fundamental_symbols(rows, update_all=True) == ["ABC", "XYZ"]