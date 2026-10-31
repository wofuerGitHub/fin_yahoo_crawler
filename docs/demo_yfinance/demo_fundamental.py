import yfinance as yf
import pandas as pd

def get_fundamental_data(ticker):
    """
    Fetches and prints key financial data (Balance Sheet, Income Statement, Cash Flow).
    """
    print(f"--- Fetching fundamental data for {ticker} ---")

    try:
        # Download the ticker object
        stock = yf.Ticker(ticker)

        # 1. Balance Sheet
        print("\n===================================================")
        print("               BALANCE SHEET (BS)")
        print("===================================================")
        balance_sheet = stock.balance_sheet
        if not balance_sheet.empty:
            # Display the latest few years/quarters
            print(balance_sheet)
        else:
            print("Could not retrieve Balance Sheet data.")

        # 2. Income Statement
        print("\n===================================================")
        print("             INCOME STATEMENT (IS)")
        print("===================================================")
        income_statement = stock.income_stmt
        if not income_statement.empty:
            # Display the latest few years/quarters
            print(income_statement)
        else:
            print("Could not retrieve Income Statement data.")

        # 3. Cash Flow Statement
        print("\n===================================================")
        print("             CASH FLOW STATEMENT (CF)")
        print("===================================================")
        cash_flow = stock.cashflow
        if not cash_flow.empty:
            # Display the latest few years/quarters
            print(cash_flow)
        else:
            print("Could not retrieve Cash Flow Statement data.")

        print("\n--- Fundamental data demonstration complete ---")

    except Exception as e:
        print(f"An error occurred while fetching data for {ticker}: {e}")


if __name__ == "__main__":
    # Replace 'MSFT' with the ticker you wish to analyze
    TICKER_SYMBOL = "BMW.DE" 
    get_fundamental_data(TICKER_SYMBOL)