\name{predict.sssvcqr}
\alias{predict.sssvcqr}
\title{Predict from an SS-SVCQR fit}
\description{
Returns fitted quantiles or local coefficient surfaces from an SS-SVCQR model.
For new locations, spatial deviations are extrapolated from nearest training
locations.
}
\usage{
\method{predict}{sssvcqr}(object, Znew = NULL, Xnew = NULL, unew = NULL,
  k = 1L, type = c("response", "coefficients"), ...)
}
\arguments{
\item{object}{A fitted \code{sssvcqr} object.}
\item{Znew}{New global covariate matrix. Required when the model has global
\code{Z} covariates and \code{Xnew} is supplied.}
\item{Xnew}{New local-candidate covariate matrix. If omitted, training fitted
values or coefficient surfaces are returned.}
\item{unew}{New coordinate matrix. Required for prediction at locations other
than the training observations.}
\item{k}{Number of nearest neighbors used to extrapolate spatial deviations.}
\item{type}{Return fitted responses or local coefficient surfaces.}
\item{...}{Unused.}
}
\value{A numeric vector of predicted quantiles or a matrix of local coefficients.}
