library(sssvcqr)

data(lucas_housing_sample)
housing <- lucas_housing_sample

y <- housing$log_price
Z <- model.matrix(~ log_TLA + log_lotsize + sale_year, data = housing)
X <- as.matrix(housing[, c("age_scaled", "age2_scaled")])
u <- scale(as.matrix(housing[, c("longitude", "latitude")]))

fit <- ss_svcqr(
  y = y,
  Z = Z,
  X = X,
  u = u,
  tau = 0.5,
  lambda1 = 3,
  lambda2 = 1,
  k_nn = 8,
  control = list(max_iter = 100, warn_nonconvergence = FALSE)
)

print(summary(fit))
