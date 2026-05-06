\name{build_graph_laplacian}
\alias{build_graph_laplacian}
\title{Build a weighted k-nearest-neighbor graph Laplacian}
\description{
Constructs a weighted k-nearest-neighbor graph from spatial coordinates using
\pkg{FNN} nearest-neighbor search and returns sparse adjacency and Laplacian
matrices.
}
\usage{
build_graph_laplacian(u, k = 10L, normalized = TRUE,
  symmetrize = c("union", "mutual"), sigma = NULL)
}
\arguments{
\item{u}{Coordinate matrix.}
\item{k}{Number of nearest neighbors. Values greater than or equal to the
number of locations are capped at \code{nrow(u) - 1}.}
\item{normalized}{Use the normalized Laplacian if \code{TRUE}; otherwise use
the unnormalized Laplacian.}
\item{symmetrize}{Use the union or mutual k-nearest-neighbor graph.}
\item{sigma}{Optional positive Gaussian kernel bandwidth.}
}
\value{A list containing the weight matrix, degree vector, sparse Laplacian, and
connected components.}
\details{
The graph is built from the directed k-nearest-neighbor edge list rather than
from a full pairwise distance matrix. The returned \code{W}, \code{L_sym}, and
\code{L} components are sparse \pkg{Matrix} objects. For fixed \code{k}, graph
storage is \eqn{O(nk)} instead of \eqn{O(n^2)}. When \code{sigma} is omitted,
the Gaussian bandwidth is computed from positive k-nearest-neighbor distances;
duplicated coordinates are allowed, and zero-distance neighbor edges receive
weight one.
}
