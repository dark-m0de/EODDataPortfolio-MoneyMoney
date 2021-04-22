-- Inofficial EODData  Extension for MoneyMoney
-- Supporting sources such as Singapore, Hong Kong and Toronto stock exchange
-- Fetches End of day ticker prices via EODData website
-- Fetches exchange rate via exchangeratesapi.io API
-- Returns tickers as securities
--
-- Username: Comma seperated stock symbol with number of shares and currency in brackets (Example: "NASDAQ/AAPL(10)[USD],TSX/APHA(100)[CAD]")
-- Password: No password required.

-- MIT License

-- Modified work Copyright 2021 Conrad Reisch
-- Original work Copyright (c) 2017 Jacubeit
-- Original work Copyright 2020 tobiasdueser

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.


WebBanking{
  version = 1.3,
  country = "de",
  description = "Include your stock portfolio in MoneyMoney by providing the stock symbols, the number of shares and the currency as username. Example: NASDAQ/AAPL(10)[USD],TSX/APHA(100)[CAD]",
  services= { "EODDataPortfolio" }
}

local stockSymbols
local connection = Connection()
local currency = "EUR"

function SupportsBank (protocol, bankCode)
  return protocol == ProtocolWebBanking and bankCode == "EODDataPortfolio"
end

function InitializeSession (protocol, bankCode, username, username2, password, username3)
        stockSymbols = username:gsub("%s+", "")
end

function ListAccounts (knownAccounts)
  local account = {
    name = "EODDataPortfolio",
    accountNumber = "EODDataPortfolio",
    currency = currency,
    portfolio = true,
    type = "AccountTypePortfolio"
  }

  return {account}
end


function RefreshAccount (account, since)
        local s = {}

        -- Create substring with stock information from comma separated input
        for stock in string.gmatch(stockSymbols, '([^,]+)') do

                -- Extract Market, Ticker, Quantity and Currency from substring
                -- Pattern: NASDAQ/AAPL(10)[USD],TSX/APHA(100)[CAD]
                stockURI=stock:match("([^(]+)")
                stockMarket=stock:match("([^/]+)")
                stockTicker=stock:match("%/(%S+)%(")
                stockQuantity=stock:match("%((%S+)%)")
                stockCurrency=stock:match("%[(%S+)%]")

                -- Retrieve HTML from EODData as a basis for extracting price and name
                stockHtml = requestCurrentStockDataHtml(stockURI)

                -- Create new stock item and put is to the list
                s[#s+1] = {
                        name = requestCurrentStockName(stockHtml),
                        securityNumber = stockTicker,
                        market = stockMarket,
                        currency = nil,
                        quantity = stockQuantity,
                        price = requestCurrentStockPrice(stockHtml),
                        currencyOfPrice = stockCurrency,
                        exchangeRate = requestCurrentExchangeRate(stockCurrency)
                }

        end

        return {securities = s}
end


function EndSession ()
        connection:close()
end



-- Query Functions
function requestCurrentStockDataHtml(stockSymbol)
        return HTML(connection:request("GET", stockDataRequestUrl(stockSymbol)))
end

function requestCurrentStockName(stockDataHtml)
        -- Extract stock name from html input with xpath
        return stockDataHtml:xpath("//div[@id='ctl00_cph1_qp1_div1']/div[1]/div/div/div/table/tr/td[2]"):text()
end

function requestCurrentStockPrice(stockDataHtml)
        -- Extract stock price from html input with xpath
                price = string.gsub(stockDataHtml:xpath("//div[@id='ctl00_cph1_qp1_div1']/div[2]/table/tr[1]/td[1]/b"):text(),",","")
        return tonumber (price)
end

function requestCurrentExchangeRate(stockCurrency)
        if (stockCurrency == currency) or (stockCurrency == nil)
        then
                return 1
        else
            currencyDataHtml = HTML(connection:request("GET", exchangeRateRequestUrl(stockCurrency)))
                        return requestCurrentStockPrice(currencyDataHtml)
        end
end


-- URL Helper Functions
function stockDataRequestUrl(stockSymbol)
        return "http://eoddata.com/stockquote/" .. stockSymbol .. ".htm"
end

function exchangeRateRequestUrl(stockCurrency)
        return "http://eoddata.com/stockquote/FOREX/EUR" .. stockCurrency .. ".htm"
end

-- SIGNATURE: MCwCFDqMaHJT2EBf5E3QlMDgyLIO5teNAhQFJoGrIJ/VNlKiM5fjRe6nVACoEA==
