library(sssvcqr)

set.seed(20260505)
dat <- simulate_sssvcqr_data(n = 100, q = 2, p = 3, seed = 20260505)

fit <- ss_svcqr(
  y = dat$y,
  Z = dat$Z,
  X = dat$X,
  u = dat$u,
  tau = 0.5,
  lambda1 = 2,
  lambda2 = 1,
  k_nn = 8,
  control = list(max_iter = 100, warn_nonconvergence = FALSE)
)

print(summary(fit))
print(kkt_sssvcqr(dat$y, dat$Z, dat$X, fit)$max_violation)
