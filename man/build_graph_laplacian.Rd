\name{build_graph_laplacian}
\alias{build_graph_laplacian}
\title{Build a weighted k-nearest-neighbor graph Laplacian}
\description{
Constructs a weighted k-nearest-neighbor graph from spatial coordinates and
returns a sparse normalized or unnormalized graph Laplacian.
}
\usage{
build_graph_laplacian(u, k = 10L, normalized = TRUE,
  symmetrize = c("union", "mutual"), sigma = NULL)
}
\arguments{
\item{u}{Coordinate matrix.}
\item{k}{Number of nearest neighbors.}
\item{normalized}{Use the normalized Laplacian if \code{TRUE}; otherwise use
the unnormalized Laplacian.}
\item{symmetrize}{Use the union or mutual k-nearest-neighbor graph.}
\item{sigma}{Optional Gaussian kernel bandwidth.}
}
\value{A list containing the weight matrix, degree vector, sparse Laplacian, and
connected components.}
