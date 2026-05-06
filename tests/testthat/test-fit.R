centering_violation <- function(fit) {
  graph <- build_graph_laplacian(
    fit$u,
    k = fit$graph$k,
    normalized = fit$graph$normalized,
    symmetrize = fit$graph$symmetrize,
    sigma = fit$graph$sigma
  )
  vapply(seq_len(ncol(fit$delta)), function(j) {
    max(vapply(graph$components_list, function(idx) {
      weights <- graph$D_vec[idx]
      if (sum(weights) <= 0) {
        weights <- rep(1, length(idx))
      }
      abs(sum(weights * fit$delta[idx, j]))
    }, numeric(1)))
  }, numeric(1))
}

truth_centering_violation <- function(dat, graph_k = 8L) {
  graph <- build_graph_laplacian(dat$u, k = min(graph_k, nrow(dat$u) - 1L))
  vapply(seq_len(ncol(dat$delta_true)), function(j) {
    max(vapply(graph$components_list, function(idx) {
      weights <- graph$D_vec[idx]
      if (sum(weights) <= 0) {
        weights <- rep(1, length(idx))
      }
      abs(sum(weights * dat$delta_true[idx, j]))
    }, numeric(1)))
  }, numeric(1))
}

test_that("simulation helper returns coherent dimensions", {
  dat <- simulate_sssvcqr_data(n = 30, q = 1, p = 3, seed = 42)

  expect_length(dat$y, 30)
  expect_equal(dim(dat$Z), c(30, 1))
  expect_equal(dim(dat$X), c(30, 3))
  expect_equal(dim(dat$u), c(30, 2))
  expect_equal(dim(dat$delta_true), c(30, 3))
  expect_equal(dim(dat$beta_spatial_true), c(30, 3))
  expect_equal(length(dat$alpha), 1)
  expect_equal(length(dat$alpha_true), 1)
  expect_equal(length(dat$beta_G_true), 3)
  expect_equal(length(dat$active), 3)
  expect_length(dat$eta, 30)
  expect_equal(dat$tau, 0.5)
  expect_equal(dat$seed, 42)
  expect_identical(dat$alpha, dat$alpha_true)
  expect_identical(dat$beta_G, dat$beta_G_true)
  expect_identical(dat$delta, dat$delta_true)
})

test_that("simulation helper is reproducible for a fixed seed", {
  dat1 <- simulate_sssvcqr_data(n = 35, q = 2, p = 3, seed = 2026)
  dat2 <- simulate_sssvcqr_data(n = 35, q = 2, p = 3, seed = 2026)

  expect_identical(dat1, dat2)
})

test_that("default simulation design has centered active and inactive truth", {
  dat <- simulate_sssvcqr_data(n = 45, q = 2, p = 3, seed = 2027)
  true_norm <- apply(dat$delta_true, 2, function(v) sqrt(sum(v^2)))

  expect_identical(unname(dat$active), c(TRUE, FALSE, TRUE))
  expect_gt(true_norm[1], 0)
  expect_equal(unname(true_norm[2]), 0)
  expect_gt(true_norm[3], 0)
  expect_lt(max(truth_centering_violation(dat)), 1e-8)
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
  expect_lt(max(centering_violation(fit)), 1e-8)

  selection <- selection_recovery_table(fit, dat)
  expect_equal(selection$covariate_index, seq_len(ncol(dat$X)))
  expect_equal(selection$true_active, unname(dat$active))
  expect_equal(selection$true_deviation_norm,
    unname(apply(dat$delta_true, 2, function(v) sqrt(sum(v^2)))))
  expect_equal(selection$selected_active,
    selection$estimated_deviation_norm > 1e-6)

  png_file <- tempfile(fileext = ".png")
  grDevices::png(png_file)
  expect_invisible(plot(fit, type = "deviation", index = 1))
  expect_invisible(plot(fit, type = "coefficient", index = 1))
  expect_invisible(plot(fit, type = "residual"))
  expect_invisible(plot(fit, type = "convergence"))
  grDevices::dev.off()
})

test_that("prediction validates training, new-location, and invalid inputs", {
  dat <- simulate_sssvcqr_data(n = 34, q = 1, p = 2, seed = 24)

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

  expect_equal(length(predict(fit)), length(dat$y))
  expect_equal(
    length(predict(
      fit,
      Znew = dat$Z[1:4, , drop = FALSE],
      Xnew = dat$X[1:4, , drop = FALSE],
      unew = dat$u[1:4, , drop = FALSE],
      k = 2
    )),
    4
  )
  expect_error(predict(fit, Xnew = dat$X[1:4, 1, drop = FALSE]),
    "Xnew must have")
  expect_error(predict(fit, Xnew = dat$X[1:4, , drop = FALSE]),
    "Znew is required")
  expect_error(predict(fit, Xnew = dat$X[1:4, , drop = FALSE],
    Znew = dat$Z[1:3, , drop = FALSE]), "Znew must have")
  expect_error(predict(fit, Xnew = dat$X[1:4, , drop = FALSE],
    Znew = dat$Z[1:4, , drop = FALSE],
    unew = dat$u[1:3, , drop = FALSE]), "unew must have")
  expect_error(predict(fit, Xnew = dat$X[1:4, , drop = FALSE],
    Znew = dat$Z[1:4, , drop = FALSE],
    unew = dat$u[1:4, , drop = FALSE], k = 0), "k")
})

test_that("KKT diagnostics report small centering violation", {
  dat <- simulate_sssvcqr_data(n = 32, q = 1, p = 2, seed = 31)

  fit <- suppressWarnings(ss_svcqr(
    y = dat$y,
    Z = dat$Z,
    X = dat$X,
    u = dat$u,
    tau = 0.5,
    lambda1 = 2,
    lambda2 = 1,
    k_nn = 5,
    control = list(max_iter = 30, warn_nonconvergence = FALSE)
  ))
  diag <- kkt_sssvcqr(dat$y, dat$Z, dat$X, fit)

  expect_length(diag$centering_violation, ncol(dat$X))
  expect_lt(diag$max_centering_violation, 1e-8)
})

test_that("large sparsity penalty shrinks deviation fields to zero", {
  dat <- simulate_sssvcqr_data(n = 30, q = 1, p = 2, seed = 42)

  fit <- suppressWarnings(ss_svcqr(
    y = dat$y,
    Z = dat$Z,
    X = dat$X,
    u = dat$u,
    tau = 0.5,
    lambda1 = 1e6,
    lambda2 = 1,
    k_nn = 5,
    control = list(max_iter = 40, warn_nonconvergence = FALSE)
  ))

  expect_lt(max(abs(fit$delta)), 1e-8)
  expect_lt(max(centering_violation(fit)), 1e-8)
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

test_that("adaptive CV fold-wise fits exclude held-out validation responses", {
  dat <- simulate_sssvcqr_data(n = 30, q = 1, p = 1, seed = 18)
  folds <- c(rep(1L, 4), rep(2L, 9), rep(3L, 17))
  sentinel <- 1e6
  dat$y[folds == 1L] <- sentinel
  heldout_training_n <- length(dat$y) - sum(folds == 1L)

  original_ss_svcqr <- ss_svcqr
  calls <- new.env(parent = emptyenv())
  calls$n <- integer()
  calls$has_sentinel <- logical()

  suppressWarnings(testthat::with_mocked_bindings(
    ss_svcqr = function(y, ...) {
      calls$n <- c(calls$n, length(y))
      calls$has_sentinel <- c(calls$has_sentinel, any(y == sentinel))
      original_ss_svcqr(y = y, ...)
    },
    cv_ss_svcqr(
      y = dat$y,
      Z = dat$Z,
      X = dat$X,
      u = dat$u,
      tau = 0.5,
      lambda1_seq = 1,
      lambda2_seq = 1,
      folds = folds,
      k_nn = 4,
      adaptive_weights = TRUE,
      control = list(max_iter = 2, warn_nonconvergence = FALSE)
    ),
    .package = "sssvcqr"
  ))

  expect_true(any(calls$n == heldout_training_n))
  expect_false(any(calls$has_sentinel[calls$n == heldout_training_n]))
})

test_that("cross-validation validates lambda grids early", {
  dat <- simulate_sssvcqr_data(n = 24, q = 1, p = 2, seed = 19)

  expect_error(cv_ss_svcqr(dat$y, dat$Z, dat$X, dat$u,
    lambda1_seq = c(1, NA), lambda2_seq = 1), "lambda1_seq")
  expect_error(cv_ss_svcqr(dat$y, dat$Z, dat$X, dat$u,
    lambda1_seq = 1, lambda2_seq = c(1, -1)), "lambda2_seq")
  expect_error(cv_ss_svcqr(dat$y, dat$Z, dat$X, dat$u,
    lambda1_seq = numeric(), lambda2_seq = 1), "lambda1_seq")
})

test_that("nonconverged fits warn but return valid objects", {
  dat <- simulate_sssvcqr_data(n = 28, q = 1, p = 2, seed = 20)

  expect_warning(
    fit <- ss_svcqr(
      y = dat$y,
      Z = dat$Z,
      X = dat$X,
      u = dat$u,
      tau = 0.5,
      lambda1 = 2,
      lambda2 = 1,
      k_nn = 5,
      control = list(max_iter = 1, warn_nonconvergence = TRUE)
    ),
    "ADMM reached max_iter"
  )

  expect_s3_class(fit, "sssvcqr")
  expect_false(fit$converged)
  expect_equal(fit$iterations, 1L)
  expect_equal(length(fitted(fit)), length(dat$y))
  expect_equal(dim(fit$delta), dim(dat$X))
  expect_false(anyNA(fit$fitted.values))
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
  expect_error(selection_recovery_table(list(), dat), "fit")
  expect_error(selection_recovery_table(fit, list()), "delta_true")
  expect_error(selection_recovery_table(fit, dat, tol = -1), "tol")
})
