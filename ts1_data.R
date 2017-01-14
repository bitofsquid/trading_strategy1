#################################
#   TRADING STRATEGY ANALYSIS   #
#    PART 1 - DATA GATHERING    #
#################################

# An academic paper entitled "Analyst Bias and Mispricing" by Mark Grinblatt, Gergana Jostova, 
# and Alexander Philipov (http://bit.ly/2hsspAw), posits that stock analyst optimism can influence 
# investor behavior and create predictable patterns in asset prices. 

# Using a few main themes of this paper as a background, this project produces preliminary empirical 
# data on a trading strategy based on sell-side analyst rating dispersion and optimism.

# This analysis was conducted in two parts: 1) data gathering, and 2) analysis. Additional details
# on the methodology used in part 1 follows here:

library(quantmod)
library(Quandl)
library(httr)
library(rvest)
library(stringr)

# DEFINE INVESTMENT UNIVERSE
#   Load ticker list of largest 1000 firms in the US (by market cap as of 11/30/2016) using data from
#   the Center for Research in Security Prices accessed at the following URL:
#   http://www.crsp.com/indexes-pages/returns-and-constituents

tickers <- read.csv("C:/Users/jtryker/Documents/R/ts1/tickers.csv", 
                    header = FALSE,
                    stringsAsFactors = FALSE)

tickers_y <- tickers$V1


# DEFINE TIME HORIZON
#   Set date parameters TO collect 20 years of monthly returns via adjusted closing prices from 
#   quantmod --> Yahoo finance

start_date = "1996-11-30"
end_date = "2016-11-30"

returns <- xts()
  
for(i in 1:length(tickers_y)) {
  temp <- getSymbols(tickers_y[i], from = start_date, to = end_date, auto.assign = FALSE)
  returns <- merge.xts(returns, monthlyReturn(Ad(temp)))
}

colnames(returns) <- tickers_y
returns <- xts(returns, tz = "EST") # Set time zone to ensure date-times are consistent


# DEFINE A RELEVANT BENCHMARK
#   Collect monthly returns for SPY, an S&P 500 Index ETF

SPY <- monthlyReturn(Ad(getSymbols("SPY", from = start_date, to = end_date, auto.assign = FALSE)))


# OBTAIN ADDITIONAL DATA
#   Use Intrinio (a 3rd party data vendor) to gather market capitalizations as of 11/30/2016. 
#     NOTE: The below code uses Intrinio's API service and was adapted from sample code provided here: 
#     http://bit.ly/2dPCP7X
#     ADDITIONAL NOTE: API call limit of 500, so collecting all data  must be in 2 batches

username <- "dfdf441d1ac3801de14a15bcf3d1e30c"
password <- "97d2c9a734f7588be071eaaba8fdec30"

base <- "https://api.intrinio.com/"
endpoint <- "historical_data"
item <- "marketcap"

mktcap <- data.frame(tickers = tickers_y, mktcap = numeric(length(tickers_y)))

for(i in 1:length(tickers_y)) {
  
  call <- paste(base, endpoint, "?", "identifier", "=", tickers_y[i], "&", "item", "=", item, "&", 
                "start_date", "=", end_date, "&",
                "end_date", "=", end_date,
                sep = "")
  
  get <- GET(call, authenticate(username, password, type = "basic"))
  response <- unlist(content(get, "parsed"))
  
  mktcap$mktcap[i] <- response["data.value"]
  
}


# OBTAIN ANALYST ESTIMATES
#   This code makes use of web-scraping to collect analyst coverage from Yahoo finance; upon review of
#   Yahoo's terms of service, this was done in accordance with Yahoo's usage policies

#   Data points of interest include the number of analysts covering each firm, as well as the average, 
#   high, and low estimates for the most recent year-end EPS

#     TECHNICAL NOTE: This portion of the script takes a long time to run (about 3 hours) - breaking 
#     the call into smaller batches seemed to produce the best results

analysts <- data.frame(ticker = tickers_y,
                       number = numeric(length(tickers_y)), 
                       average = numeric(length(tickers_y)), 
                       low = numeric(length(tickers_y)), 
                       high = numeric(length(tickers_y)))

analysts.url <- "http://finance.yahoo.com/quote/AAPL/analysts?p=AAPL"

for(i in 1:length(tickers_y)) {

  url.temp <- str_replace_all(analysts.url, "AAPL", tickers_y[i])
  
  writeLines(sprintf("var url = '%s'; 
                      var page = new WebPage()
                      var fs = require('fs');
                     
                      page.open(url, function (status) {
                      just_wait();
                      });
                     
                      function just_wait() {
                      setTimeout(function () {
                      fs.write('scrape.html', page.content, 'w');
                      phantom.exit();
                      }, 5000);
                      }", 
                     url.temp), 
              con = "scrape.js")
  
  system("phantomjs scrape.js")
  
  html <- read_html("scrape.html") %>%
            html_nodes("table") %>%
            html_table(fill = TRUE)
  
  df <- tryCatch(html[[2]], error = function(e) { data.frame("Current Year" = rep("NA", times = 5),
                                                             check.names = FALSE) })
  
  analysts$number[i] <- df$"Current Year"[1]
  analysts$average[i] <- df$"Current Year"[2]
  analysts$low[i] <- df$"Current Year"[3]
  analysts$high[i] <- df$"Current Year"[4]
  
}


# Write files to disk for use in Part 2 of this project

write.zoo(returns, file = "C:/Users/jtryker/Documents/R/ts1/returns.csv", sep = ",")
write.zoo(SPY, file = "C:/Users/jtryker/Documents/R/ts1/SPY.csv", sep = ",")
write.zoo(market, file = "C:/Users/jtryker/Documents/R/ts1/market.csv", sep = ",")
write.csv(mktcap, file = "C:/Users/jtryker/Documents/R/ts1/mktcap.csv")
write.csv(analysts, file = "C:/Users/jtryker/Documents/R/ts1/analysts.csv")

