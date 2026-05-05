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

  alpha <- if (q == 0L) numeric() else seq(1.0, length.out = q, by = -0.4)
  beta_G <- seq(1.5, length.out = p, by = -0.5)

  delta <- matrix(0, nrow = n, ncol = p)
  delta[, 1L] <- 0.9 * sin(2 * pi * u[, 1L]) * cos(2 * pi * u[, 2L])
  if (p >= 3L) {
    delta[, 3L] <- 0.7 * exp(-18 * ((u[, 1L] - 0.65)^2 + (u[, 2L] - 0.35)^2))
  }

  graph <- build_graph_laplacian(u, k = min(graph_k, n - 1L))
  for (j in seq_len(p)) {
    delta[, j] <- project_D_centered(delta[, j], graph$D_vec, graph$components_list)
  }

  eta <- as.numeric(if (q > 0L) Z %*% alpha else rep(0, n)) +
    as.numeric(X %*% beta_G) + rowSums(X * delta)
  errors <- stats::rnorm(n, sd = noise_sd) - stats::qnorm(tau) * noise_sd
  y <- eta + errors

  list(
    y = y,
    Z = Z,
    X = X,
    u = u,
    eta = eta,
    alpha = alpha,
    beta_G = beta_G,
    delta = delta,
    tau = tau
  )
}
