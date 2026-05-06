.as_matrix <- function(x, n = NULL, name = deparse(substitute(x))) {
  x <- as.matrix(x)
  if (!is.null(n) && nrow(x) != n) {
    stop(name, " must have ", n, " rows.", call. = FALSE)
  }
  storage.mode(x) <- "double"
  if (anyNA(x) || any(!is.finite(x))) {
    stop(name, " must contain only finite numeric values.", call. = FALSE)
  }
  x
}

.check_nonnegative_scalar <- function(x, name) {
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x < 0) {
    stop(name, " must be a non-negative finite scalar.", call. = FALSE)
  }
  invisible(x)
}

.sparse_diagonal <- function(n, x = 1.0) {
  Matrix::Diagonal(n = n, x = x)
}

check_loss_vec <- function(r, tau) {
  r * (tau - as.numeric(r < 0))
}

make_spatial_folds <- function(u,
                               K = 5L,
                               method = c("kmeans", "grid"),
                               seed = NULL) {
  method <- match.arg(method)
  u <- .as_matrix(u, name = "u")
  n <- nrow(u)
  if (K < 2L || K > n) {
    stop("K must be between 2 and the number of observations.", call. = FALSE)
  }
  if (!is.null(seed)) {
    set.seed(seed)
  }

  if (method == "kmeans") {
    stats::kmeans(u, centers = K, nstart = 10L)$cluster
  } else {
    Kx <- floor(sqrt(K))
    Ky <- ceiling(K / Kx)
    x_breaks <- unique(stats::quantile(u[, 1L], probs = seq(0, 1, length.out = Kx + 1L)))
    y_breaks <- unique(stats::quantile(u[, 2L], probs = seq(0, 1, length.out = Ky + 1L)))
    if (length(x_breaks) < 2L || length(y_breaks) < 2L) {
      return(stats::kmeans(u, centers = K, nstart = 10L)$cluster)
    }
    ix <- cut(u[, 1L], breaks = x_breaks, include.lowest = TRUE, labels = FALSE)
    iy <- cut(u[, 2L], breaks = y_breaks, include.lowest = TRUE, labels = FALSE)
    folds <- as.integer((ix - 1L) * Ky + iy)
    old <- sort(unique(folds))
    map <- rep(seq_len(K), length.out = length(old))
    as.integer(map[match(folds, old)])
  }
}

build_graph_laplacian <- function(u,
                                  k = 10L,
                                  normalized = TRUE,
                                  symmetrize = c("union", "mutual"),
                                  sigma = NULL) {
  symmetrize <- match.arg(symmetrize)
  u <- .as_matrix(u, name = "u")
  n <- nrow(u)
  if (n < 2L) {
    stop("u must contain at least two locations.", call. = FALSE)
  }
  if (ncol(u) < 1L) {
    stop("u must contain at least one coordinate column.", call. = FALSE)
  }
  if (!is.logical(normalized) || length(normalized) != 1L || is.na(normalized)) {
    stop("normalized must be a single TRUE or FALSE value.", call. = FALSE)
  }
  if (!is.numeric(k) || length(k) != 1L || !is.finite(k) || is.na(k) || k < 1) {
    stop("k must be a positive finite scalar.", call. = FALSE)
  }
  k <- as.integer(min(floor(k), n - 1L))
  if (!is.null(sigma) &&
      (!is.numeric(sigma) || length(sigma) != 1L || !is.finite(sigma) || sigma <= 0)) {
    stop("sigma must be a positive finite scalar when supplied.", call. = FALSE)
  }

  edge_n <- as.double(n) * k
  if (edge_n > .Machine$integer.max) {
    stop("n * k is too large to construct the requested graph.", call. = FALSE)
  }
  edge_n <- as.integer(edge_n)
  search_k <- min(n, k + 1L)
  nn <- FNN::get.knnx(data = u, query = u, k = search_k)
  directed_i <- integer(edge_n)
  directed_j <- integer(edge_n)
  directed_dist <- numeric(edge_n)
  pos <- 0L

  for (i in seq_len(n)) {
    keep <- nn$nn.index[i, ] != i
    idx_i <- nn$nn.index[i, keep]
    dist_i <- nn$nn.dist[i, keep]

    if (length(idx_i) < k) {
      nn_i <- FNN::get.knnx(data = u, query = u[i, , drop = FALSE], k = n)
      keep <- nn_i$nn.index[1L, ] != i
      idx_i <- nn_i$nn.index[1L, keep]
      dist_i <- nn_i$nn.dist[1L, keep]
    }
    if (length(idx_i) < k) {
      stop("Could not identify k nearest neighbors for every location.", call. = FALSE)
    }

    edge_idx <- pos + seq_len(k)
    directed_i[edge_idx] <- i
    directed_j[edge_idx] <- idx_i[seq_len(k)]
    directed_dist[edge_idx] <- dist_i[seq_len(k)]
    pos <- pos + k
  }

  positive_d2 <- directed_dist[directed_dist > 0]^2
  sigma2 <- if (is.null(sigma)) {
    if (length(positive_d2)) stats::median(positive_d2) else 1
  } else {
    sigma^2
  }
  if (!is.finite(sigma2) || sigma2 <= 0) {
    sigma2 <- 1
  }
  directed_weight <- exp(-directed_dist^2 / sigma2)

  pair_i <- pmin(directed_i, directed_j)
  pair_j <- pmax(directed_i, directed_j)
  pair_key <- as.double(pair_i) + (as.double(pair_j) - 1) * n
  pair_order <- order(pair_key)
  pair_key <- pair_key[pair_order]
  pair_i <- pair_i[pair_order]
  pair_j <- pair_j[pair_order]
  directed_weight <- directed_weight[pair_order]

  group_start <- c(1L, which(diff(pair_key) != 0) + 1L)
  group_count <- diff(c(group_start, length(pair_key) + 1L))
  keep_group <- if (symmetrize == "union") {
    rep(TRUE, length(group_start))
  } else {
    group_count > 1L
  }
  group_start <- group_start[keep_group]
  if (length(group_start)) {
    edge_i <- pair_i[group_start]
    edge_j <- pair_j[group_start]
    edge_weight <- directed_weight[group_start]
    W <- Matrix::sparseMatrix(
      i = c(edge_i, edge_j),
      j = c(edge_j, edge_i),
      x = c(edge_weight, edge_weight),
      dims = c(n, n)
    )
  } else {
    W <- Matrix::sparseMatrix(
      i = integer(0),
      j = integer(0),
      x = numeric(0),
      dims = c(n, n)
    )
  }
  W <- Matrix::drop0(Matrix::forceSymmetric(W, uplo = "U"))
  W <- methods::as(W, "dsCMatrix")

  D_vec <- as.numeric(Matrix::rowSums(W))
  if (normalized) {
    inv_sqrt_d <- ifelse(D_vec > 0, 1 / sqrt(D_vec), 0)
    S <- .sparse_diagonal(n, inv_sqrt_d)
    L_sp <- .sparse_diagonal(n, 1) - S %*% W %*% S
  } else {
    L_sp <- .sparse_diagonal(n, D_vec) - W
  }

  L_sp <- Matrix::drop0(L_sp)
  L_sp <- Matrix::forceSymmetric(L_sp)
  L_sp <- methods::as(L_sp, "dsCMatrix")

  graph <- igraph::make_empty_graph(n = n, directed = FALSE)
  if (length(group_start)) {
    graph <- igraph::add_edges(graph, as.vector(rbind(edge_i, edge_j)))
  }
  comp <- igraph::components(graph)$membership
  components_list <- split(seq_len(n), comp)

  list(
    W = W,
    D_vec = D_vec,
    L_sym = L_sp,
    L = L_sp,
    components_list = components_list,
    k = k,
    sigma = sqrt(sigma2),
    normalized = normalized,
    symmetrize = symmetrize
  )
}

project_D_centered <- function(v, D_vec, components_list) {
  v_proj <- as.numeric(v)
  for (comp_idx in components_list) {
    D_comp <- D_vec[comp_idx]
    denom <- sum(D_comp)
    if (denom > 0) {
      v_proj[comp_idx] <- v_proj[comp_idx] - sum(D_comp * v_proj[comp_idx]) / denom
    } else {
      v_proj[comp_idx] <- v_proj[comp_idx] - mean(v_proj[comp_idx])
    }
  }
  v_proj
}

.make_constraint_matrix <- function(D_vec, components_list) {
  n <- length(D_vec)
  m <- length(components_list)
  if (m == 0L) {
    return(Matrix::sparseMatrix(
      i = integer(0),
      j = integer(0),
      x = numeric(0),
      dims = c(n, 0L)
    ))
  }

  nnz <- sum(lengths(components_list))
  row_idx <- integer(nnz)
  col_idx <- integer(nnz)
  values <- numeric(nnz)
  pos <- 0L

  for (col in seq_along(components_list)) {
    comp_idx <- components_list[[col]]
    weights <- D_vec[comp_idx]
    if (sum(weights) <= 0) {
      weights <- rep(1, length(comp_idx))
    }

    idx <- pos + seq_along(comp_idx)
    row_idx[idx] <- comp_idx
    col_idx[idx] <- col
    values[idx] <- weights
    pos <- pos + length(comp_idx)
  }

  Matrix::sparseMatrix(
    i = row_idx,
    j = col_idx,
    x = values,
    dims = c(n, m)
  )
}

.solve_centered_system <- function(A, b, C, ridge) {
  n <- length(b)
  m <- ncol(C)
  if (m == 0L) {
    return(as.numeric(Matrix::solve(A, b)))
  }

  zero_block <- Matrix::sparseMatrix(
    i = integer(0),
    j = integer(0),
    x = numeric(0),
    dims = c(m, m)
  )
  kkt <- rbind(cbind(A, C), cbind(Matrix::t(C), zero_block))
  kkt <- methods::as(kkt, "dgCMatrix")
  rhs <- c(b, rep(0, m))

  # The KKT matrix is symmetric indefinite, so sparse Cholesky is not
  # appropriate here. Matrix::solve() on a dgCMatrix uses a sparse general
  # solver and keeps the centering constraints inside the linear system.
  sol <- tryCatch(
    Matrix::solve(kkt, rhs),
    error = function(e) {
      A_ridge <- A + ridge * .sparse_diagonal(n, 1)
      kkt_ridge <- rbind(cbind(A_ridge, C), cbind(Matrix::t(C), zero_block))
      Matrix::solve(methods::as(kkt_ridge, "dgCMatrix"), rhs)
    }
  )
  as.numeric(sol[seq_len(n)])
}

prox_check <- function(v, gamma, tau) {
  pmin(pmax(v - gamma * tau, 0), v + gamma * (1 - tau))
}

group_shrink <- function(v, kappa) {
  v_norm <- sqrt(sum(v^2))
  if (v_norm == 0 || v_norm <= kappa) {
    return(rep(0, length(v)))
  }
  (1 - kappa / v_norm) * v
}

ss_svcqr <- function(y,
                     Z,
                     X,
                     u,
                     tau = 0.5,
                     lambda1,
                     lambda2,
                     k_nn = 10L,
                     w = NULL,
                     control = list(),
                     graph_normalized = TRUE,
                     graph_symmetrize = c("union", "mutual"),
                     graph_sigma = NULL) {
  graph_symmetrize <- match.arg(graph_symmetrize)
  y <- as.numeric(y)
  n <- length(y)
  if (n < 2L) {
    stop("y must contain at least two observations.", call. = FALSE)
  }
  if (anyNA(y) || any(!is.finite(y))) {
    stop("y must contain only finite numeric values.", call. = FALSE)
  }
  if (!is.numeric(tau) || length(tau) != 1L || tau <= 0 || tau >= 1) {
    stop("tau must be a scalar in (0, 1).", call. = FALSE)
  }
  if (missing(lambda1) || missing(lambda2)) {
    stop("lambda1 and lambda2 are required.", call. = FALSE)
  }
  .check_nonnegative_scalar(lambda1, "lambda1")
  .check_nonnegative_scalar(lambda2, "lambda2")
  if (!is.null(graph_sigma)) {
    .check_nonnegative_scalar(graph_sigma, "graph_sigma")
    if (graph_sigma == 0) {
      stop("graph_sigma must be positive when supplied.", call. = FALSE)
    }
  }

  Z <- if (missing(Z) || is.null(Z)) matrix(nrow = n, ncol = 0L) else .as_matrix(Z, n, "Z")
  X <- .as_matrix(X, n, "X")
  u <- .as_matrix(u, n, "u")
  q <- ncol(Z)
  p <- ncol(X)
  if (p < 1L) {
    stop("X must contain at least one potentially local covariate.", call. = FALSE)
  }
  if (nrow(u) != n || ncol(u) < 2L) {
    stop("u must be an n x d coordinate matrix with d >= 2.", call. = FALSE)
  }

  if (is.null(w)) {
    w <- rep(1, p)
  }
  w <- as.numeric(w)
  if (length(w) != p || any(!is.finite(w)) || any(w < 0)) {
    stop("w must be a non-negative numeric vector with length ncol(X).", call. = FALSE)
  }

  ctrl <- list(
    max_iter = 500L,
    tol_pri = 1e-4,
    tol_dual = 1e-3,
    rho_s = 1,
    rho_z = 1,
    ridge = 1e-6,
    verbose = FALSE,
    warn_nonconvergence = TRUE
  )
  unknown_control <- setdiff(names(control), names(ctrl))
  if (length(unknown_control)) {
    stop("Unknown control entries: ", paste(unknown_control, collapse = ", "), ".", call. = FALSE)
  }
  ctrl[names(control)] <- control
  ctrl$max_iter <- as.integer(ctrl$max_iter)
  if (is.na(ctrl$max_iter) || ctrl$max_iter < 1L) {
    stop("control$max_iter must be a positive integer.", call. = FALSE)
  }
  for (nm in c("tol_pri", "tol_dual", "rho_s", "rho_z", "ridge")) {
    .check_nonnegative_scalar(ctrl[[nm]], paste0("control$", nm))
  }
  if (ctrl$tol_pri == 0 || ctrl$tol_dual == 0 || ctrl$rho_s == 0 ||
      ctrl$rho_z == 0 || ctrl$ridge == 0) {
    stop("control tolerances, ADMM penalties, and ridge must be positive.", call. = FALSE)
  }

  graph_data <- build_graph_laplacian(
    u,
    k = k_nn,
    normalized = graph_normalized,
    symmetrize = graph_symmetrize,
    sigma = graph_sigma
  )
  L_sym <- graph_data$L_sym
  D_vec <- graph_data$D_vec
  components_list <- graph_data$components_list
  C_center <- .make_constraint_matrix(D_vec, components_list)

  alpha <- rep(0, q)
  beta_G <- rep(0, p)
  delta <- matrix(0, nrow = n, ncol = p)
  s <- rep(0, n)
  z <- matrix(0, nrow = n, ncol = p)
  u_dual <- rep(0, n)
  v_dual <- matrix(0, nrow = n, ncol = p)

  G <- cbind(Z, X)
  GtG <- crossprod(G)
  L_cholesky <- tryCatch(
    chol(GtG),
    error = function(e) chol(GtG + diag(ctrl$ridge, nrow = q + p))
  )

  Aj_list <- vector("list", p)
  for (j in seq_len(p)) {
    A_j <- 2 * lambda2 * L_sym +
      ctrl$rho_s * .sparse_diagonal(n, X[, j]^2) +
      ctrl$rho_z * .sparse_diagonal(n, 1)
    Aj_list[[j]] <- Matrix::drop0(methods::as(A_j, "dsCMatrix"))
  }

  history <- list(
    r_norm_s = rep(NA_real_, ctrl$max_iter),
    r_norm_z = rep(NA_real_, ctrl$max_iter),
    d_norm_s = rep(NA_real_, ctrl$max_iter),
    d_norm_z = rep(NA_real_, ctrl$max_iter)
  )

  eps_abs <- ctrl$tol_pri
  eps_rel <- ctrl$tol_dual
  converged <- FALSE

  for (iter in seq_len(ctrl$max_iter)) {
    s_prev <- s
    z_prev <- z
    X_delta_all <- rowSums(X * delta)

    b_rhs_vec <- y - X_delta_all - s + u_dual
    Gt_b_rhs <- crossprod(G, b_rhs_vec)
    theta_P <- backsolve(L_cholesky, backsolve(L_cholesky, Gt_b_rhs, transpose = TRUE))

    if (q > 0L) {
      alpha <- as.numeric(theta_P[seq_len(q)])
    }
    beta_G <- as.numeric(theta_P[seq.int(q + 1L, q + p)])

    Z_alpha <- if (q > 0L) as.numeric(Z %*% alpha) else rep(0, n)
    X_beta_G <- as.numeric(X %*% beta_G)

    v_s <- y - Z_alpha - X_beta_G - X_delta_all + u_dual
    s <- prox_check(v_s, 1 / ctrl$rho_s, tau)

    for (j in seq_len(p)) {
      X_delta_minus_j <- X_delta_all - X[, j] * delta[, j]
      resid_j <- y - Z_alpha - X_beta_G - X_delta_minus_j - s + u_dual
      b_j <- ctrl$rho_s * (X[, j] * resid_j) + ctrl$rho_z * (z[, j] - v_dual[, j])

      delta[, j] <- .solve_centered_system(Aj_list[[j]], b_j, C_center, ctrl$ridge)
      X_delta_all <- X_delta_minus_j + X[, j] * delta[, j]

      z[, j] <- group_shrink(delta[, j] + v_dual[, j], lambda1 * w[j] / ctrl$rho_z)
      z[, j] <- project_D_centered(z[, j], D_vec, components_list)
    }

    r_s_vec <- y - Z_alpha - X_beta_G - X_delta_all - s
    u_dual <- u_dual + r_s_vec

    r_z_mat <- delta - z
    v_dual <- v_dual + r_z_mat

    history$r_norm_s[iter] <- sqrt(sum(r_s_vec^2))
    history$r_norm_z[iter] <- sqrt(sum(r_z_mat^2))
    history$d_norm_s[iter] <- ctrl$rho_s * sqrt(sum((s - s_prev)^2))
    history$d_norm_z[iter] <- sqrt(sum((ctrl$rho_z * (z - z_prev))^2))

    if (isTRUE(ctrl$verbose) && (iter == 1L || iter %% 25L == 0L)) {
      message(
        "ADMM iter ", iter,
        ": r_s=", signif(history$r_norm_s[iter], 4),
        ", r_z=", signif(history$r_norm_z[iter], 4),
        ", d_s=", signif(history$d_norm_s[iter], 4),
        ", d_z=", signif(history$d_norm_z[iter], 4)
      )
    }

    norm_Ax_s <- sqrt(sum((y - Z_alpha - X_beta_G - X_delta_all)^2))
    norm_Bz_s <- sqrt(sum(s^2))
    eps_pri_s <- sqrt(n) * eps_abs + eps_rel * max(norm_Ax_s, norm_Bz_s)
    eps_dual_s <- sqrt(n) * eps_abs + eps_rel * sqrt(sum((ctrl$rho_s * u_dual)^2))

    norm_delta <- sqrt(sum(delta^2))
    norm_z <- sqrt(sum(z^2))
    eps_pri_z <- sqrt(n * p) * eps_abs + eps_rel * max(norm_delta, norm_z)
    eps_dual_z <- sqrt(n * p) * eps_abs + eps_rel * sqrt(sum((ctrl$rho_z * as.vector(v_dual))^2))

    if (iter > 1L &&
        history$r_norm_s[iter] < eps_pri_s &&
        history$r_norm_z[iter] < eps_pri_z &&
        history$d_norm_s[iter] < eps_dual_s &&
        history$d_norm_z[iter] < eps_dual_z) {
      converged <- TRUE
      break
    }
  }

  if (!converged && isTRUE(ctrl$warn_nonconvergence)) {
    warning("ADMM reached max_iter without satisfying the stopping rule.", call. = FALSE)
  }

  delta <- z
  delta[abs(delta) < 1e-8] <- 0
  beta_spatial <- matrix(beta_G, nrow = n, ncol = p, byrow = TRUE) + delta
  fitted_values <- as.numeric(if (q > 0L) Z %*% alpha else rep(0, n)) +
    as.numeric(X %*% beta_G) + rowSums(X * delta)

  history <- lapply(history, function(x) x[seq_len(iter)])

  out <- list(
    alpha = alpha,
    beta_G = beta_G,
    delta = delta,
    beta_spatial = beta_spatial,
    fitted.values = fitted_values,
    residuals = y - fitted_values,
    tau = tau,
    lambda1 = lambda1,
    lambda2 = lambda2,
    weights = w,
    iterations = iter,
    converged = converged,
    convergence_history = history,
    graph = list(
      k = graph_data$k,
      sigma = graph_data$sigma,
      normalized = graph_data$normalized,
      symmetrize = graph_data$symmetrize
    ),
    u = u,
    n = n,
    q = q,
    p = p,
    call = match.call()
  )
  class(out) <- "sssvcqr"
  out
}

predict.sssvcqr <- function(object,
                            Znew = NULL,
                            Xnew = NULL,
                            unew = NULL,
                            k = 1L,
                            type = c("response", "coefficients"),
                            ...) {
  type <- match.arg(type)
  if (is.null(Xnew)) {
    if (type == "coefficients") {
      return(object$beta_spatial)
    }
    return(object$fitted.values)
  }

  Xnew <- .as_matrix(Xnew, name = "Xnew")
  n_new <- nrow(Xnew)
  if (ncol(Xnew) != object$p) {
    stop("Xnew must have ", object$p, " columns.", call. = FALSE)
  }
  Znew <- if (object$q == 0L) {
    matrix(nrow = n_new, ncol = 0L)
  } else if (is.null(Znew)) {
    stop("Znew is required because the fitted model has global Z covariates.", call. = FALSE)
  } else {
    .as_matrix(Znew, n_new, "Znew")
  }

  if (is.null(unew)) {
    if (n_new == nrow(object$delta)) {
      delta_new <- object$delta
    } else {
      stop("unew is required for prediction at new locations.", call. = FALSE)
    }
  } else {
    unew <- .as_matrix(unew, n_new, "unew")
    if (!is.numeric(k) || length(k) != 1L || !is.finite(k) || k < 1) {
      stop("k must be a positive finite scalar.", call. = FALSE)
    }
    k <- max(1L, min(as.integer(k), nrow(object$u)))
    nn <- FNN::get.knnx(data = object$u, query = unew, k = k)
    if (k == 1L) {
      idx <- nn$nn.index[, 1L]
      delta_new <- object$delta[idx, , drop = FALSE]
    } else {
      weights <- 1 / pmax(nn$nn.dist, .Machine$double.eps)
      weights <- weights / rowSums(weights)
      delta_new <- matrix(0, nrow = n_new, ncol = object$p)
      for (i in seq_len(n_new)) {
        delta_new[i, ] <- colSums(object$delta[nn$nn.index[i, ], , drop = FALSE] * weights[i, ])
      }
    }
  }

  beta_local <- matrix(object$beta_G, nrow = n_new, ncol = object$p, byrow = TRUE) + delta_new
  if (type == "coefficients") {
    return(beta_local)
  }
  as.numeric(if (object$q > 0L) Znew %*% object$alpha else rep(0, n_new)) +
    rowSums(Xnew * beta_local)
}

fitted.sssvcqr <- function(object, ...) {
  object$fitted.values
}

residuals.sssvcqr <- function(object, ...) {
  object$residuals
}

coef.sssvcqr <- function(object, ...) {
  list(alpha = object$alpha, beta_G = object$beta_G, delta = object$delta)
}

.add_value_colorbar <- function(pal, value_range, label) {
  usr <- graphics::par("usr")
  x_span <- diff(usr[1:2])
  y_span <- diff(usr[3:4])
  xleft <- usr[2] + 0.05 * x_span
  xright <- usr[2] + 0.08 * x_span
  ybottom <- usr[3] + 0.12 * y_span
  ytop <- usr[4] - 0.12 * y_span
  y_breaks <- seq(ybottom, ytop, length.out = length(pal) + 1L)

  old_xpd <- graphics::par("xpd")
  graphics::par(xpd = NA)
  on.exit(graphics::par(xpd = old_xpd), add = TRUE)

  graphics::rect(
    xleft = xleft,
    ybottom = y_breaks[-length(y_breaks)],
    xright = xright,
    ytop = y_breaks[-1L],
    col = pal,
    border = NA
  )
  graphics::rect(xleft, ybottom, xright, ytop, border = "grey30")

  if (diff(value_range) == 0) {
    tick_values <- value_range[1L]
    tick_y <- (ybottom + ytop) / 2
  } else {
    tick_values <- pretty(value_range, n = 4L)
    tick_values <- tick_values[tick_values >= value_range[1L] & tick_values <= value_range[2L]]
    if (!length(tick_values)) {
      tick_values <- value_range
    }
    tick_y <- ybottom + (tick_values - value_range[1L]) / diff(value_range) * (ytop - ybottom)
  }

  graphics::segments(
    x0 = xright,
    y0 = tick_y,
    x1 = xright + 0.012 * x_span,
    y1 = tick_y,
    col = "grey30"
  )
  graphics::text(
    x = xright + 0.018 * x_span,
    y = tick_y,
    labels = format(signif(tick_values, 4), trim = TRUE),
    adj = c(0, 0.5),
    cex = 0.75
  )
  graphics::mtext(label, side = 4L, line = 3.1, cex = 0.8)
  invisible(NULL)
}

plot.sssvcqr <- function(x,
                         type = c("deviation", "coefficient", "residual", "convergence"),
                         index = 1L,
                         ...) {
  type <- match.arg(type)
  index <- as.integer(index)[1L]

  if (type %in% c("deviation", "coefficient") && (index < 1L || index > x$p)) {
    stop("index must be between 1 and the number of candidate local covariates.", call. = FALSE)
  }

  if (type == "convergence") {
    history <- x$convergence_history
    history <- lapply(history, function(v) pmax(v, .Machine$double.eps))
    ylim <- range(unlist(history), finite = TRUE)
    graphics::plot(
      seq_along(history$r_norm_s), history$r_norm_s,
      type = "l", log = "y", ylim = ylim,
      xlab = "Iteration", ylab = "Residual norm",
      main = "ADMM convergence", ...
    )
    graphics::lines(seq_along(history$r_norm_z), history$r_norm_z, lty = 2)
    graphics::lines(seq_along(history$d_norm_s), history$d_norm_s, lty = 3)
    graphics::lines(seq_along(history$d_norm_z), history$d_norm_z, lty = 4)
    graphics::legend(
      "topright",
      legend = c("primal s", "primal z", "dual s", "dual z"),
      lty = 1:4,
      bty = "n"
    )
    return(invisible(x))
  }

  coords <- x$u[, 1:2, drop = FALSE]
  values <- switch(
    type,
    deviation = x$delta[, index],
    coefficient = x$beta_spatial[, index],
    residual = x$residuals
  )
  main <- switch(
    type,
    deviation = paste0("Spatial deviation ", index),
    coefficient = paste0("Local coefficient ", index),
    residual = "Residuals"
  )
  colorbar_label <- switch(
    type,
    deviation = "Deviation",
    coefficient = "Coefficient",
    residual = "Residual"
  )
  pal <- grDevices::colorRampPalette(c("#2166AC", "#F7F7F7", "#B2182B"))(100L)
  value_range <- range(values, finite = TRUE)
  if (!all(is.finite(value_range))) {
    stop("plot values must contain at least one finite value.", call. = FALSE)
  }
  if (diff(value_range) == 0) {
    col_id <- rep(50L, length(values))
  } else {
    col_id <- pmax(1L, pmin(100L, floor(1 + 99 * (values - value_range[1]) / diff(value_range))))
  }
  old_mar <- graphics::par("mar")
  old_xpd <- graphics::par("xpd")
  on.exit(graphics::par(mar = old_mar, xpd = old_xpd), add = TRUE)
  new_mar <- old_mar
  new_mar[4L] <- max(new_mar[4L], 5.1)
  graphics::par(mar = new_mar)
  graphics::plot(
    coords[, 1L], coords[, 2L],
    col = pal[col_id],
    pch = 19,
    xlab = "Coordinate 1",
    ylab = "Coordinate 2",
    main = main,
    ...
  )
  .add_value_colorbar(pal, value_range, colorbar_label)
  invisible(x)
}

summary.sssvcqr <- function(object, ...) {
  delta_norm <- apply(object$delta, 2L, function(v) sqrt(sum(v^2)))
  out <- list(
    call = object$call,
    n = object$n,
    q = object$q,
    p = object$p,
    tau = object$tau,
    lambda1 = object$lambda1,
    lambda2 = object$lambda2,
    iterations = object$iterations,
    converged = object$converged,
    alpha = object$alpha,
    beta_G = object$beta_G,
    delta_norm = delta_norm
  )
  class(out) <- "summary.sssvcqr"
  out
}

print.sssvcqr <- function(x, ...) {
  cat("Sparse-smooth SVC quantile regression fit\n")
  cat("  n =", x$n, " q =", x$q, " p =", x$p, " tau =", x$tau, "\n")
  cat("  lambda1 =", x$lambda1, " lambda2 =", x$lambda2, "\n")
  cat("  iterations =", x$iterations, " converged =", x$converged, "\n")
  invisible(x)
}

print.summary.sssvcqr <- function(x, ...) {
  cat("Sparse-smooth SVC quantile regression summary\n")
  cat("  n =", x$n, " q =", x$q, " p =", x$p, " tau =", x$tau, "\n")
  cat("  lambda1 =", x$lambda1, " lambda2 =", x$lambda2, "\n")
  cat("  iterations =", x$iterations, " converged =", x$converged, "\n\n")
  if (length(x$alpha)) {
    cat("alpha:\n")
    print(x$alpha)
  }
  cat("beta_G:\n")
  print(x$beta_G)
  cat("delta L2 norms:\n")
  print(x$delta_norm)
  invisible(x)
}

cv_ss_svcqr <- function(y,
                        Z,
                        X,
                        u,
                        tau = 0.5,
                        lambda1_seq,
                        lambda2_seq,
                        k_nn = 10L,
                        K_folds = 5L,
                        folds = NULL,
                        adaptive_weights = TRUE,
                        lambda1_pilot = NULL,
                        lambda2_pilot = NULL,
                        a_stabilizer = 0.01,
                        gamma_power = 1,
                        w = NULL,
                        control = list(max_iter = 500L, tol_pri = 1e-4, tol_dual = 1e-3),
                        fold_seed = 1L,
                        verbose = FALSE,
                        graph_normalized = TRUE,
                        graph_symmetrize = c("union", "mutual"),
                        graph_sigma = NULL) {
  graph_symmetrize <- match.arg(graph_symmetrize)
  y <- as.numeric(y)
  n <- length(y)
  if (n < 2L || anyNA(y) || any(!is.finite(y))) {
    stop("y must contain at least two finite numeric values.", call. = FALSE)
  }
  if (!is.numeric(tau) || length(tau) != 1L || tau <= 0 || tau >= 1) {
    stop("tau must be a scalar in (0, 1).", call. = FALSE)
  }
  Z <- if (missing(Z) || is.null(Z)) matrix(nrow = n, ncol = 0L) else .as_matrix(Z, n, "Z")
  X <- .as_matrix(X, n, "X")
  u <- .as_matrix(u, n, "u")
  p <- ncol(X)
  if (p < 1L) {
    stop("X must contain at least one potentially local covariate.", call. = FALSE)
  }
  if (missing(lambda1_seq) || missing(lambda2_seq)) {
    stop("lambda1_seq and lambda2_seq are required.", call. = FALSE)
  }
  if (!is.numeric(lambda1_seq) || !length(lambda1_seq) ||
      anyNA(lambda1_seq) || any(!is.finite(lambda1_seq)) || any(lambda1_seq < 0)) {
    stop("lambda1_seq must contain non-negative finite values.", call. = FALSE)
  }
  if (!is.numeric(lambda2_seq) || !length(lambda2_seq) ||
      anyNA(lambda2_seq) || any(!is.finite(lambda2_seq)) || any(lambda2_seq < 0)) {
    stop("lambda2_seq must contain non-negative finite values.", call. = FALSE)
  }

  if (is.null(folds)) {
    folds <- make_spatial_folds(u, K = K_folds, method = "kmeans", seed = fold_seed)
  }
  folds <- as.integer(folds)
  if (length(folds) != n) {
    stop("folds must have length equal to length(y).", call. = FALSE)
  }
  fold_ids <- sort(unique(folds))

  if (!is.null(w)) {
    w <- as.numeric(w)
    if (length(w) != p || anyNA(w) || any(!is.finite(w)) || any(w < 0)) {
      stop("w must be a non-negative numeric vector with length ncol(X).", call. = FALSE)
    }
  }

  fold_weights <- vector("list", length(fold_ids))
  if (adaptive_weights && is.null(w)) {
    if (is.null(lambda1_pilot)) {
      lambda1_pilot <- min(lambda1_seq)
    }
    if (is.null(lambda2_pilot)) {
      lambda2_pilot <- max(lambda2_seq)
    }
    .check_nonnegative_scalar(lambda1_pilot, "lambda1_pilot")
    .check_nonnegative_scalar(lambda2_pilot, "lambda2_pilot")
    if (!is.numeric(a_stabilizer) || length(a_stabilizer) != 1L ||
        !is.finite(a_stabilizer) || a_stabilizer <= 0) {
      stop("a_stabilizer must be a positive finite scalar.", call. = FALSE)
    }
    if (!is.numeric(gamma_power) || length(gamma_power) != 1L ||
        !is.finite(gamma_power) || gamma_power < 0) {
      stop("gamma_power must be a non-negative finite scalar.", call. = FALSE)
    }
    if (verbose) {
      message("Running fold-wise pilot fits for adaptive weights.")
    }
    for (f in seq_along(fold_ids)) {
      idx_tr <- which(folds != fold_ids[f])
      fit_pilot <- ss_svcqr(
        y = y[idx_tr],
        Z = Z[idx_tr, , drop = FALSE],
        X = X[idx_tr, , drop = FALSE],
        u = u[idx_tr, , drop = FALSE],
        tau = tau,
        lambda1 = lambda1_pilot,
        lambda2 = lambda2_pilot,
        k_nn = k_nn,
        w = NULL,
        control = control,
        graph_normalized = graph_normalized,
        graph_symmetrize = graph_symmetrize,
        graph_sigma = graph_sigma
      )
      delta_pilot_norms <- apply(fit_pilot$delta, 2L, function(v) sqrt(sum(v^2)))
      fold_weights[[f]] <- 1 / (delta_pilot_norms + a_stabilizer)^gamma_power
    }
  } else {
    base_w <- if (is.null(w)) rep(1, p) else w
    for (f in seq_along(fold_ids)) {
      fold_weights[[f]] <- base_w
    }
  }

  grid <- expand.grid(lambda1 = lambda1_seq, lambda2 = lambda2_seq)
  cv_mean <- rep(NA_real_, nrow(grid))
  cv_sd <- rep(NA_real_, nrow(grid))

  for (g in seq_len(nrow(grid))) {
    l1 <- grid$lambda1[g]
    l2 <- grid$lambda2[g]
    if (verbose) {
      message("CV grid ", g, "/", nrow(grid), ": lambda1=", l1, ", lambda2=", l2)
    }
    fold_losses <- rep(NA_real_, length(fold_ids))

    for (f in seq_along(fold_ids)) {
      idx_val <- which(folds == fold_ids[f])
      idx_tr <- which(folds != fold_ids[f])
      if (length(idx_tr) <= ncol(Z) + ncol(X)) {
        next
      }

      fit_cv <- ss_svcqr(
        y = y[idx_tr],
        Z = Z[idx_tr, , drop = FALSE],
        X = X[idx_tr, , drop = FALSE],
        u = u[idx_tr, , drop = FALSE],
        tau = tau,
        lambda1 = l1,
        lambda2 = l2,
        k_nn = k_nn,
        w = fold_weights[[f]],
        control = control,
        graph_normalized = graph_normalized,
        graph_symmetrize = graph_symmetrize,
        graph_sigma = graph_sigma
      )

      qhat <- predict(
        fit_cv,
        Znew = Z[idx_val, , drop = FALSE],
        Xnew = X[idx_val, , drop = FALSE],
        unew = u[idx_val, , drop = FALSE]
      )
      fold_losses[f] <- mean(check_loss_vec(y[idx_val] - qhat, tau))
    }

    cv_mean[g] <- mean(fold_losses, na.rm = TRUE)
    cv_sd[g] <- stats::sd(fold_losses, na.rm = TRUE)
  }

  best_idx <- which.min(cv_mean)
  returned_weights <- if (!is.null(w)) {
    w
  } else if (adaptive_weights) {
    fit_pilot <- ss_svcqr(
      y = y, Z = Z, X = X, u = u, tau = tau,
      lambda1 = if (is.null(lambda1_pilot)) min(lambda1_seq) else lambda1_pilot,
      lambda2 = if (is.null(lambda2_pilot)) max(lambda2_seq) else lambda2_pilot,
      k_nn = k_nn, w = NULL, control = control,
      graph_normalized = graph_normalized,
      graph_symmetrize = graph_symmetrize,
      graph_sigma = graph_sigma
    )
    delta_pilot_norms <- apply(fit_pilot$delta, 2L, function(v) sqrt(sum(v^2)))
    1 / (delta_pilot_norms + a_stabilizer)^gamma_power
  } else {
    rep(1, p)
  }
  out <- list(
    grid = grid,
    cv_mean = cv_mean,
    cv_sd = cv_sd,
    best = list(
      lambda1 = grid$lambda1[best_idx],
      lambda2 = grid$lambda2[best_idx],
      cv_mean = cv_mean[best_idx],
      cv_sd = cv_sd[best_idx]
    ),
    folds = folds,
    weights = returned_weights,
    tau = tau
  )
  class(out) <- "sssvcqr_cv"
  out
}

print.sssvcqr_cv <- function(x, ...) {
  cat("Spatially blocked CV for SS-SVCQR\n")
  cat("  tau =", x$tau, "\n")
  cat("  best lambda1 =", x$best$lambda1, "\n")
  cat("  best lambda2 =", x$best$lambda2, "\n")
  cat("  best mean check loss =", x$best$cv_mean, "\n")
  invisible(x)
}

kkt_sssvcqr <- function(y,
                        Z,
                        X,
                        fit,
                        L_sym = NULL,
                        D_vec = NULL,
                        components_list = NULL,
                        lambda1 = fit$lambda1,
                        lambda2 = fit$lambda2,
                        w = fit$weights,
                        tau = fit$tau) {
  y <- as.numeric(y)
  n <- length(y)
  Z <- if (missing(Z) || is.null(Z)) matrix(nrow = n, ncol = 0L) else .as_matrix(Z, n, "Z")
  X <- .as_matrix(X, n, "X")
  if (is.null(L_sym) || is.null(D_vec) || is.null(components_list)) {
    graph_data <- build_graph_laplacian(
      fit$u,
      k = fit$graph$k,
      normalized = fit$graph$normalized,
      symmetrize = fit$graph$symmetrize,
      sigma = fit$graph$sigma
    )
    L_sym <- graph_data$L_sym
    D_vec <- graph_data$D_vec
    components_list <- graph_data$components_list
  }

  q <- ncol(Z)
  p <- ncol(X)
  Z_alpha <- if (q > 0L) as.numeric(Z %*% fit$alpha) else rep(0, n)
  X_betaG <- as.numeric(X %*% fit$beta_G)
  Xdelta <- rowSums(X * fit$delta)
  r <- y - Z_alpha - X_betaG - Xdelta
  psi <- tau - as.numeric(r < 0)

  g_alpha <- if (q > 0L) crossprod(Z, psi) else 0
  g_betaG <- crossprod(X, psi)
  grad_alpha_norm <- if (q > 0L) sqrt(sum(g_alpha^2)) else 0
  grad_betaG_norm <- sqrt(sum(g_betaG^2))

  delta_norm <- apply(fit$delta, 2L, function(v) sqrt(sum(v^2)))
  group_stationarity <- rep(NA_real_, p)
  group_margin <- rep(NA_real_, p)
  C_center <- .make_constraint_matrix(D_vec, components_list)
  centering_residual <- as.matrix(Matrix::t(C_center) %*% fit$delta)
  centering_violation <- apply(abs(centering_residual), 2L, max)

  for (j in seq_len(p)) {
    g_j <- X[, j] * psi + 2 * lambda2 * as.vector(L_sym %*% fit$delta[, j])
    g_tilde_j <- project_D_centered(g_j, D_vec, components_list)

    dj_norm <- delta_norm[j]
    if (dj_norm > 1e-10) {
      target <- lambda1 * w[j] * fit$delta[, j] / dj_norm
      group_stationarity[j] <- sqrt(sum((g_tilde_j - target)^2))
    } else {
      gnorm <- sqrt(sum(g_tilde_j^2))
      group_margin[j] <- max(0, gnorm - lambda1 * w[j])
    }
  }

  list(
    grad_alpha_norm = grad_alpha_norm,
    grad_betaG_norm = grad_betaG_norm,
    group_stationarity = group_stationarity,
    group_margin = group_margin,
    centering_violation = centering_violation,
    max_centering_violation = max(centering_violation),
    delta_norm = delta_norm,
    max_violation = max(c(
      grad_alpha_norm,
      grad_betaG_norm,
      ifelse(is.na(group_stationarity), 0, group_stationarity),
      ifelse(is.na(group_margin), 0, group_margin),
      centering_violation
    ))
  )
}
