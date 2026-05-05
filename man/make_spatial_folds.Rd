\name{make_spatial_folds}
\alias{make_spatial_folds}
\title{Create spatial cross-validation folds}
\description{
Assigns observations to spatially coherent folds using k-means clustering or a
simple coordinate grid.
}
\usage{
make_spatial_folds(u, K = 5L, method = c("kmeans", "grid"), seed = NULL)
}
\arguments{
\item{u}{Coordinate matrix.}
\item{K}{Number of folds.}
\item{method}{Fold construction method.}
\item{seed}{Optional random seed.}
}
\value{An integer vector of fold labels.}
