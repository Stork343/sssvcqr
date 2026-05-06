selection_recovery_table <- function(fit, truth, tol = 1e-6) {
  if (!inherits(fit, "sssvcqr")) {
    stop("fit must be an object returned by ss_svcqr().", call. = FALSE)
  }
  if (!is.list(truth)) {
    stop("truth must be a list, typically returned by simulate_sssvcqr_data().", call. = FALSE)
  }
  if (!is.numeric(tol) || length(tol) != 1L || !is.finite(tol) || tol < 0) {
    stop("tol must be a non-negative finite scalar.", call. = FALSE)
  }

  delta_true <- if (!is.null(truth$delta_true)) truth$delta_true else truth$delta
  if (is.null(delta_true)) {
    stop("truth must contain delta_true or delta.", call. = FALSE)
  }
  delta_true <- as.matrix(delta_true)
  storage.mode(delta_true) <- "double"
  if (ncol(delta_true) != fit$p) {
    stop("truth delta must have one column per fitted candidate covariate.", call. = FALSE)
  }

  true_norm <- apply(delta_true, 2L, function(v) sqrt(sum(v^2)))
  active <- if (!is.null(truth$active)) {
    as.logical(truth$active)
  } else {
    true_norm > tol
  }
  if (length(active) != fit$p || anyNA(active)) {
    stop("truth$active must be a logical vector with length ncol(X).", call. = FALSE)
  }

  estimated_norm <- apply(fit$delta, 2L, function(v) sqrt(sum(v^2)))
  covariate <- colnames(delta_true)
  if (is.null(covariate)) {
    covariate <- paste0("x", seq_len(fit$p))
  }

  data.frame(
    covariate_index = seq_len(fit$p),
    covariate = covariate,
    true_active = active,
    true_deviation_norm = true_norm,
    estimated_deviation_norm = estimated_norm,
    selected_active = estimated_norm > tol,
    row.names = NULL
  )
}
