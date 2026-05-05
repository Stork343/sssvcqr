\name{ss_svcqr}
\alias{ss_svcqr}
\title{Fit sparse-smooth spatially varying coefficient quantile regression}
\description{
Fits an SS-SVCQR model by ADMM for a fixed quantile level. Candidate local
coefficients are represented as global baselines plus graph-smoothed spatial
deviations, with a group penalty selecting deviations that should be zero.
}
\usage{
ss_svcqr(y, Z, X, u, tau = 0.5, lambda1, lambda2, k_nn = 10L,
  w = NULL, control = list(), graph_normalized = TRUE,
  graph_symmetrize = c("union", "mutual"), graph_sigma = NULL)
}
\arguments{
\item{y}{Numeric response vector.}
\item{Z}{Matrix of covariates with global effects. Use \code{NULL} for none.}
\item{X}{Matrix of covariates that may have spatially varying effects.}
\item{u}{Coordinate matrix with one row per observation.}
\item{tau}{Quantile level in \code{(0, 1)}.}
\item{lambda1}{Group sparsity penalty for spatial deviations.}
\item{lambda2}{Graph Laplacian smoothness penalty.}
\item{k_nn}{Number of nearest neighbors used to build the graph.}
\item{w}{Optional non-negative adaptive group weights.}
\item{control}{List of ADMM controls: \code{max_iter}, \code{tol_pri},
\code{tol_dual}, \code{rho_s}, \code{rho_z}, \code{ridge}, and
\code{warn_nonconvergence}.}
\item{graph_normalized}{Use the normalized graph Laplacian if \code{TRUE}.}
\item{graph_symmetrize}{How to symmetrize the directed k-nearest-neighbor graph.}
\item{graph_sigma}{Optional Gaussian kernel bandwidth.}
}
\value{
An object of class \code{sssvcqr} containing global coefficients, spatial
deviations, fitted values, residuals, convergence history, and graph metadata.
}
\examples{
dat <- simulate_sssvcqr_data(n = 40, q = 1, p = 2, seed = 1)
fit <- ss_svcqr(dat$y, dat$Z, dat$X, dat$u,
  lambda1 = 2, lambda2 = 1, k_nn = 5,
  control = list(max_iter = 20, warn_nonconvergence = FALSE))
fit
head(predict(fit))
}
