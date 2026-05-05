\name{simulate_sssvcqr_data}
\alias{simulate_sssvcqr_data}
\title{Simulate data for SS-SVCQR examples}
\description{
Generates synthetic spatial quantile-regression data with known global
coefficients and sparse spatial deviation fields.
}
\usage{
simulate_sssvcqr_data(n = 120, q = 2, p = 3, tau = 0.5,
  noise_sd = 0.4, seed = NULL, graph_k = 8L)
}
\arguments{
\item{n}{Number of observations.}
\item{q}{Number of global covariates.}
\item{p}{Number of candidate spatially varying covariates.}
\item{tau}{Target quantile level.}
\item{noise_sd}{Gaussian error scale.}
\item{seed}{Optional random seed.}
\item{graph_k}{Graph size used to center true deviations.}
}
\value{A list containing \code{y}, \code{Z}, \code{X}, \code{u}, true coefficients,
true deviations, and the linear predictor.}
\examples{
dat <- simulate_sssvcqr_data(n = 30, q = 1, p = 2, seed = 1)
str(dat)
}
