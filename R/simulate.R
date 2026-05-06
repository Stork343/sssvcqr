simulate_sssvcqr_data <- function(n = 120,
                                  q = 2,
                                  p = 3,
                                  tau = 0.5,
                                  noise_sd = 0.4,
                                  seed = NULL,
                                  graph_k = 8L) {
  if (!is.null(seed)) {
    set.seed(seed)
  }
  if (n < 10L) {
    stop("n must be at least 10.", call. = FALSE)
  }
  if (q < 0L || p < 1L) {
    stop("q must be non-negative and p must be positive.", call. = FALSE)
  }
  if (!is.numeric(tau) || length(tau) != 1L || tau <= 0 || tau >= 1) {
    stop("tau must be a scalar in (0, 1).", call. = FALSE)
  }

  u <- matrix(stats::runif(n * 2L), ncol = 2L)
  colnames(u) <- c("u1", "u2")

  Z <- if (q == 0L) {
    matrix(nrow = n, ncol = 0L)
  } else {
    matrix(stats::rnorm(n * q), nrow = n, ncol = q)
  }
  X <- matrix(stats::rnorm(n * p), nrow = n, ncol = p)
  colnames(Z) <- if (q > 0L) paste0("z", seq_len(q)) else character()
  colnames(X) <- paste0("x", seq_len(p))

  alpha_true <- if (q == 0L) numeric() else seq(1.0, length.out = q, by = -0.4)
  beta_G_true <- seq(1.5, length.out = p, by = -0.5)

  active <- rep(FALSE, p)
  active[1L] <- TRUE
  if (p >= 3L) {
    active[3L] <- TRUE
  }
  names(active) <- colnames(X)

  delta_true <- matrix(0, nrow = n, ncol = p)
  colnames(delta_true) <- colnames(X)
  delta_true[, 1L] <- 2.0 * sin(2 * pi * u[, 1L]) * cos(2 * pi * u[, 2L])
  if (p >= 3L) {
    delta_true[, 3L] <- 8.0 * exp(-18 * ((u[, 1L] - 0.65)^2 + (u[, 2L] - 0.35)^2))
  }

  graph <- build_graph_laplacian(u, k = min(graph_k, n - 1L))
  for (j in seq_len(p)) {
    delta_true[, j] <- project_D_centered(delta_true[, j], graph$D_vec, graph$components_list)
  }
  beta_spatial_true <- matrix(beta_G_true, nrow = n, ncol = p, byrow = TRUE) + delta_true
  colnames(beta_spatial_true) <- colnames(X)

  eta <- as.numeric(if (q > 0L) Z %*% alpha_true else rep(0, n)) +
    as.numeric(X %*% beta_G_true) + rowSums(X * delta_true)
  errors <- stats::rnorm(n, sd = noise_sd) - stats::qnorm(tau) * noise_sd
  y <- eta + errors

  list(
    y = y,
    Z = Z,
    X = X,
    u = u,
    eta = eta,
    alpha_true = alpha_true,
    beta_G_true = beta_G_true,
    delta_true = delta_true,
    beta_spatial_true = beta_spatial_true,
    active = active,
    tau = tau,
    seed = seed,
    alpha = alpha_true,
    beta_G = beta_G_true,
    delta = delta_true
  )
}
