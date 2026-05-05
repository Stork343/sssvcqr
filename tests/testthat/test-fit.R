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
