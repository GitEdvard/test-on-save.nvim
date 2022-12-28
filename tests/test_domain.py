import pytest
from datetime import datetime
from stock_winners.domain import StockExchange
from stock_winners.domain import StockValue
from stock_winners.repository import StockRepository


@pytest.fixture
def stock_exchange_with_entire_list():
    stock_values = [
            StockValue("ABB", 217, datetime(2017, 1, 1, 12, 0, 0)),
            StockValue("NCC", 122, datetime(2017, 1, 1, 12, 0, 1)),
            StockValue("ABB", 218, datetime(2017, 1, 1, 12, 0, 2)),
            StockValue("NCC", 123, datetime(2017, 1, 1, 12, 0, 3)),
            StockValue("NCC", 121, datetime(2017, 1, 1, 12, 0, 4)),
            StockValue("AddLife B", 21, datetime(2017, 1, 1, 12, 0, 5)),
            StockValue("NCC", 121, datetime(2017, 1, 1, 12, 0, 6)),
            StockValue("SSAB B", 221, datetime(2017, 1, 1, 12, 0, 6)),
            StockValue("8TRA", 226, datetime(2017, 1, 1, 12, 1, 4)),
            StockValue("AddLife B", 27, datetime(2017, 1, 1, 12, 1, 5)),
            StockValue("NCC", 119, datetime(2017, 1, 1, 12, 1, 6)),
            StockValue("ABB", 219, datetime(2017, 1, 1, 12, 1, 7)),
            StockValue("ABB", 222, datetime(2017, 1, 2, 12, 0, 7)),
            StockValue("NCC", 117, datetime(2017, 1, 2, 12, 0, 8)),
            StockValue("NCC", 116, datetime(2017, 1, 2, 12, 0, 9)),
            StockValue("8TRA", 225, datetime(2017, 1, 2, 12, 0, 10)),
            StockValue("SSAB B", 209, datetime(2017, 1, 2, 12, 0, 23)),
            StockValue("AddLife B", 38, datetime(2017, 1, 2, 12, 1, 10)),
            StockValue("NCC", 116, datetime(2017, 1, 2, 12, 1, 9)),
            StockValue("NCC", 118, datetime(2017, 1, 2, 12, 2, 9)),
            StockValue("NCC", 121, datetime(2017, 1, 2, 12, 3, 9)),
        ]
    return StockExchange(stock_values)


def test_daily_winners__is_3_items(stock_exchange_with_entire_list):
    daily_winners = stock_exchange_with_entire_list.get_daily_winners()

    assert len(daily_winners) == 3


def test_daily_winners__first_item(stock_exchange_with_entire_list):
    daily_winners = stock_exchange_with_entire_list.get_daily_winners()

    assert daily_winners[0].company_abbr == "AddLife B"
    assert round(daily_winners[0].change_in_percent, 2) == 40.74
    assert daily_winners[0].latest == 38


def test_daily_winners__second_item(stock_exchange_with_entire_list):
    daily_winners = stock_exchange_with_entire_list.get_daily_winners()

    assert daily_winners[1].company_abbr == "NCC"
    assert round(daily_winners[1].change_in_percent, 2) == 1.68
    assert daily_winners[1].latest == 121


def test_daily_winners__third_item(stock_exchange_with_entire_list):
    daily_winners = stock_exchange_with_entire_list.get_daily_winners()

    assert daily_winners[2].company_abbr == "ABB"
    assert round(daily_winners[2].change_in_percent, 2) == 1.37
    assert daily_winners[2].latest == 222
