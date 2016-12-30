cat('HELLO R!\n')

ranrw <- function(mu, sigma, p0=100, T=100) {
  cumprod(c(p0, 1 + (rnorm(n=T, mean=mu, sd=sigma)/100)))
}
p <- ranrw(0.05, 1.4, p0=1500, T=25)
    # gives you a 25-long series, starting with a price of 1500, where
    # one-period returns are N(0.05,1.4^2) percent.
print(p)

