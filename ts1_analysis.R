#################################
#   TRADING STRATEGY ANALYSIS   #
#       PART 2 - ANALYSIS       #
#################################

# An academic paper entitled "Analyst Bias and Mispricing" by Mark Grinblatt, Gergana Jostova, 
# and Alexander Philipov (http://bit.ly/2hsspAw), posits that stock analyst optimism can influence 
# investor behavior and create predictable patterns in asset prices. 

# Using a few main themes of this paper as a background, this project produces preliminary empirical 
# data on a trading strategy based on sell-side analyst rating dispersion and optimism.

# This analysis was conducted in two parts: 1) data gathering, and 2) analysis. Additional details
# on the methodology used in part 2 follows here:

suppressMessages(library(xts))
suppressMessages(library(PerformanceAnalytics))
suppressMessages(library(PortfolioAnalytics))
suppressMessages(library(ROI))


### Read in SPY ETF return data collected in Part 1
SPY <- xts(read.zoo("C:/Users/jtryker/Documents/R/ts1/SPY.csv", 
                    header = TRUE,
                    sep = ",",
                    FUN = as.Date))

colnames(SPY) <- "SPY"


### Read in ticker returns data collected in Part 1, and format for analysis
returns <- xts(read.zoo("C:/Users/jtryker/Documents/R/ts1/returns.csv",
                        header = TRUE,
                        sep = ",",
                        FUN = as.Date))

exclude <- which(index(returns) == as.Date("2015-06-28"))
returns <- returns[-exclude,] # Remove erroneous row (duplicate June 2015 values)

returns.trim <- returns[, colSums(is.na(returns)) == 0]
tickers.trim <- colnames(returns.trim) # Remove tickers with insufficient return histories

index(SPY) <- index(returns) # Ensure date formats are consistent


### Read in analyst and market cap data from Part 1, and format for analysis
analysts <- read.csv("C:/Users/jtryker/Documents/R/ts1/analysts.csv", 
                     header = TRUE,
                     stringsAsFactors = FALSE)
analysts[,c("average", "low", "high")] <- suppressWarnings(sapply(analysts[,c("average", "low", "high")], 
                                                                  as.numeric))

mktcap <- read.csv("C:/Users/jtryker/Documents/R/ts1/mktcap.csv", 
                   header = TRUE,
                   stringsAsFactors = FALSE) 

mktcap$mktcap <- suppressWarnings(sapply(mktcap$mktcap, as.numeric))

ticker_data <- merge(analysts, mktcap, by = "ticker") # Create combined table with all data
ticker_data <- ticker_data[, !colnames(ticker_data) %in% c("X.x", "X.y")]
ticker_data <- na.omit(ticker_data)
ticker_data <- ticker_data[ticker_data$ticker %in% tickers.trim, ]


### Calculate measures of analyst rating dispersion and optimism
ticker_data$dispersion <- (sqrt((ticker_data$low - ticker_data$average)^2) + 
                          sqrt((ticker_data$high - ticker_data$average)^2)) / 
                          abs(ticker_data$average)

ticker_data$hipct <- ((ticker_data$high - ticker_data$average)^2 / abs(ticker_data$average))
ticker_data$lopct <- ((ticker_data$low - ticker_data$average)^2 / abs(ticker_data$average))

ticker_data$optimism <- ticker_data$hipct / ticker_data$lopct


### Select firms for investment, LOW dispersion and LOW optimism = Long; and HIGH dispersion and HIGH
### optimism = Short
long <- ticker_data[ticker_data$number >= 5 & 
                       ticker_data$dispersion <= quantile(ticker_data$dispersion, 0.05) &
                       !is.infinite(ticker_data$optimism),]
long <- head(long[order(long$optimism), "ticker"], n = 10)

short <- ticker_data[ticker_data$number >= 5 & 
                    ticker_data$dispersion >= quantile(ticker_data$dispersion, 0.95) & 
                    !is.infinite(ticker_data$optimism),]
short <- tail(short[order(short$optimism), "ticker"], n = 10)


### Create various portfolios to test Long / Short investment strategy

longret <- returns[,long] 
shortret <- returns[,short]

# Construct long portfolio such that the Sharpe ratio is maximized
long_port <- portfolio.spec(assets = long) 
long_port <- add.constraint(portfolio = long_port, type = "long_only")
long_port <- add.constraint(portfolio = long_port, type = "full_investment")
long_port <- add.constraint(portfolio = long_port, type = "box", min = 0.025, max = 0.25)
long_port <- add.objective(portfolio = long_port, type = "risk", name = "StdDev")
long_port <- add.objective(portfolio = long_port, type = "return", name = "mean")

long_opt <- optimize.portfolio(R = longret,
                               portfolio = long_port,
                               optimize_method = "ROI",
                               maxSR = TRUE)

# Construct short portfolio such that the Sharpe ratio is maximized
short_port <- portfolio.spec(assets = short)
short_port <- add.constraint(portfolio = short_port, type = "long_only")
short_port <- add.constraint(portfolio = short_port, type = "full_investment")
short_port <- add.constraint(portfolio = short_port, type = "box", min = 0.025, max = 0.25)
short_port <- add.objective(portfolio = short_port, type = "risk", name = "StdDev")
short_port <- add.objective(portfolio = short_port, type = "return", name = "mean")

short_opt <- optimize.portfolio(R = shortret,
                               portfolio = short_port,
                               optimize_method = "ROI",
                               maxSR = TRUE)

# Calculate max Sharpe (optimal) portfolio returns
longret_opt <- Return.portfolio(longret, long_opt$weights, rebalance_on = "quarters")
shortret_opt <- Return.portfolio(shortret, short_opt$weights, rebalance_on = "quarters")
long_short_opt <- longret_opt - shortret_opt

# Calculate equal-weighted portfolio returns
longret_eq <- Return.portfolio(longret, 
                               rep(1/length(long), times = length(long)), 
                               rebalance_on = "quarters")
shortret_eq <- Return.portfolio(shortret, 
                                rep(1/length(short), times = length(short)), 
                                rebalance_on = "quarters")
long_short_eq <- longret_eq - shortret_eq

# Combine data - all & optimized only
combined_all <- cbind(long_short_opt, longret_opt, shortret_opt,
                     long_short_eq, longret_eq, shortret_eq,
                     SPY)
colnames(combined_all) <- c("Long-Short (Opt)", "Long (Opt)", "Short (Opt)",
                            "Long-Short (Eq)", "Long (Eq)", "Short (Eq)",
                            "SPY")

combined_opt <- cbind(long_short_opt, longret_opt, shortret_opt, SPY)
colnames(combined_opt) <- c("Long-Short (Opt)", "Long (Opt)", "Short (Opt)", "SPY")


### Visualize return distribution and risk/return for all portfolios 
chart.Boxplot(combined_all, main = "Exhibit 1: Return Distribution Comparison")
chart.RiskReturnScatter(combined_all, Rf = 0.01/12, xlim = c(0.00, 0.35), 
                        main = "Exhibit 2: Annualized Return and Risk Comparison")


### Visualize cumulative returns, monthly returns & volatility, and drawdown for optimized portfolios
charts.PerformanceSummary(combined_opt,
                          Rf = 0.01/12,
                          methods = "StdDev", width = 12,
                          ylog = TRUE, 
                          main = "Exhibit 3: Performance Summary - Optimized Portfolios")


