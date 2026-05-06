test_that("simulation helper returns coherent dimensions", {
  dat <- simulate_sssvcqr_data(n = 30, q = 1, p = 2, seed = 42)

  expect_length(dat$y, 30)
  expect_equal(dim(dat$Z), c(30, 1))
  expect_equal(dim(dat$X), c(30, 2))
  expect_equal(dim(dat$u), c(30, 2))
  expect_equal(dim(dat$delta), c(30, 2))
})

test_that("ss_svcqr fits and predicts on a small synthetic data set", {
  dat <- simulate_sssvcqr_data(n = 35, q = 1, p = 2, seed = 123)

  fit <- suppressWarnings(ss_svcqr(
    y = dat$y,
    Z = dat$Z,
    X = dat$X,
    u = dat$u,
    tau = 0.5,
    lambda1 = 2,
    lambda2 = 1,
    k_nn = 5,
    control = list(max_iter = 25, warn_nonconvergence = FALSE)
  ))

  expect_s3_class(fit, "sssvcqr")
  expect_equal(length(fitted(fit)), length(dat$y))
  expect_equal(length(residuals(fit)), length(dat$y))
  expect_equal(dim(predict(fit, type = "coefficients")), dim(dat$X))
  expect_false(anyNA(predict(fit)))
  expect_equal(length(predict(fit, Xnew = dat$X[1:3, ], Znew = dat$Z[1:3, ],
    unew = dat$u[1:3, ], k = 2)), 3)

  png_file <- tempfile(fileext = ".png")
  grDevices::png(png_file)
  expect_invisible(plot(fit, type = "deviation", index = 1))
  expect_invisible(plot(fit, type = "convergence"))
  grDevices::dev.off()
})

test_that("blocked cross-validation returns a best parameter pair", {
  dat <- simulate_sssvcqr_data(n = 30, q = 1, p = 2, seed = 7)

  cv <- suppressWarnings(cv_ss_svcqr(
    y = dat$y,
    Z = dat$Z,
    X = dat$X,
    u = dat$u,
    tau = 0.5,
    lambda1_seq = c(1, 2),
    lambda2_seq = c(0.5, 1),
    K_folds = 3,
    adaptive_weights = FALSE,
    control = list(max_iter = 15, warn_nonconvergence = FALSE)
  ))

  expect_s3_class(cv, "sssvcqr_cv")
  expect_true(cv$best$lambda1 %in% c(1, 2))
  expect_true(cv$best$lambda2 %in% c(0.5, 1))
  expect_true(is.finite(cv$best$cv_mean))
})

test_that("adaptive blocked cross-validation runs without validation leakage", {
  dat <- simulate_sssvcqr_data(n = 36, q = 1, p = 2, seed = 17)

  cv <- suppressWarnings(cv_ss_svcqr(
    y = dat$y,
    Z = dat$Z,
    X = dat$X,
    u = dat$u,
    tau = 0.5,
    lambda1_seq = c(1),
    lambda2_seq = c(1),
    K_folds = 3,
    adaptive_weights = TRUE,
    control = list(max_iter = 10, warn_nonconvergence = FALSE)
  ))

  expect_s3_class(cv, "sssvcqr_cv")
  expect_equal(length(cv$weights), ncol(dat$X))
  expect_true(all(is.finite(cv$weights)))
})

test_that("invalid model inputs fail early with clear errors", {
  dat <- simulate_sssvcqr_data(n = 20, q = 1, p = 2, seed = 9)
  bad_y <- dat$y
  bad_y[1] <- NA_real_

  expect_error(ss_svcqr(bad_y, dat$Z, dat$X, dat$u, lambda1 = 1, lambda2 = 1),
    "finite")
  expect_error(ss_svcqr(dat$y, dat$Z, dat$X, dat$u, tau = 1, lambda1 = 1, lambda2 = 1),
    "tau")
  expect_error(ss_svcqr(dat$y, dat$Z, dat$X, dat$u, lambda1 = -1, lambda2 = 1),
    "lambda1")
  expect_error(ss_svcqr(dat$y, dat$Z, dat$X, dat$u, lambda1 = 1, lambda2 = 1,
    control = list(extra = TRUE)), "Unknown control")
  fit <- ss_svcqr(dat$y, dat$Z, dat$X, dat$u, lambda1 = 1, lambda2 = 1,
    control = list(max_iter = 10, warn_nonconvergence = FALSE))
  expect_error(predict(fit, Xnew = dat$X[1:2, ], Znew = dat$Z[1:2, ],
    unew = dat$u[1:2, ], k = NA_real_), "k")
  expect_error(cv_ss_svcqr(dat$y, dat$Z, dat$X, dat$u,
    lambda1_seq = c(1, NA), lambda2_seq = 1), "lambda1_seq")
})
