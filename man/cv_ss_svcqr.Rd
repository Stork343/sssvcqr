\name{cv_ss_svcqr}
\alias{cv_ss_svcqr}
\title{Spatially blocked cross-validation for SS-SVCQR}
\description{
Evaluates a grid of sparsity and smoothness penalties using spatially blocked
cross-validation and held-out check loss.
}
\usage{
cv_ss_svcqr(y, Z, X, u, tau = 0.5, lambda1_seq, lambda2_seq,
  k_nn = 10L, K_folds = 5L, folds = NULL, adaptive_weights = TRUE,
  lambda1_pilot = NULL, lambda2_pilot = NULL, a_stabilizer = 0.01,
  gamma_power = 1, w = NULL, control = list(max_iter = 500L,
  tol_pri = 1e-04, tol_dual = 0.001), fold_seed = 1L,
  verbose = FALSE, graph_normalized = TRUE,
  graph_symmetrize = c("union", "mutual"), graph_sigma = NULL)
}
\arguments{
\item{y, Z, X, u, tau}{Model inputs passed to \code{\link{ss_svcqr}}.}
\item{lambda1_seq, lambda2_seq}{Penalty grids.}
\item{k_nn}{Number of nearest neighbors for graph construction.}
\item{K_folds}{Number of spatial folds when \code{folds} is not supplied.}
\item{folds}{Optional integer fold labels.}
\item{adaptive_weights}{Whether to estimate adaptive group weights by a pilot fit.}
\item{lambda1_pilot, lambda2_pilot}{Optional pilot penalties.}
\item{a_stabilizer, gamma_power}{Adaptive weight parameters.}
\item{w}{Optional precomputed group weights.}
\item{control}{ADMM control list.}
\item{fold_seed}{Random seed for fold construction.}
\item{verbose}{Print progress messages.}
\item{graph_normalized, graph_symmetrize, graph_sigma}{Graph construction options.}
}
\value{An object of class \code{sssvcqr_cv} with CV losses and the best pair.}
