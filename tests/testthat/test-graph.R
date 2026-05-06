test_that("graph Laplacian has expected shape and sparse storage", {
  set.seed(1)
  u <- matrix(runif(40), ncol = 2)
  graph <- build_graph_laplacian(u, k = 4)

  expect_equal(dim(graph$W), c(20, 20))
  expect_equal(dim(graph$L_sym), c(20, 20))
  expect_equal(dim(graph$L), c(20, 20))
  expect_s4_class(graph$W, "sparseMatrix")
  expect_s4_class(graph$L_sym, "sparseMatrix")
  expect_s4_class(graph$L, "sparseMatrix")
  expect_equal(length(graph$D_vec), 20)
  expect_true(all(graph$D_vec >= 0))
  expect_equal(length(graph$components_list[[1]]) >= 1, TRUE)
  expect_length(unlist(graph$components_list, use.names = FALSE), 20)
  expect_setequal(unlist(graph$components_list, use.names = FALSE), seq_len(20))
  expect_equal(Matrix::nnzero(graph$W - Matrix::t(graph$W)), 0)
  expect_equal(Matrix::nnzero(graph$L_sym - Matrix::t(graph$L_sym)), 0)
  expect_equal(Matrix::nnzero(graph$L - Matrix::t(graph$L)), 0)
  expect_equal(as.numeric(Matrix::rowSums(graph$W)), graph$D_vec)
  expect_lte(Matrix::nnzero(graph$W), 2 * nrow(u) * graph$k)
})

test_that("graph construction supports symmetrization and Laplacian variants", {
  set.seed(11)
  u <- matrix(runif(60), ncol = 2)

  for (symmetrize in c("union", "mutual")) {
    for (normalized in c(TRUE, FALSE)) {
      graph <- build_graph_laplacian(
        u,
        k = 3,
        normalized = normalized,
        symmetrize = symmetrize
      )

      expect_equal(dim(graph$W), c(30, 30))
      expect_equal(dim(graph$L), c(30, 30))
      expect_s4_class(graph$W, "sparseMatrix")
      expect_s4_class(graph$L, "sparseMatrix")
      expect_identical(graph$normalized, normalized)
      expect_identical(graph$symmetrize, symmetrize)
    }
  }
})

test_that("graph construction safely caps k at n - 1", {
  set.seed(12)
  u <- matrix(runif(16), ncol = 2)
  graph <- build_graph_laplacian(u, k = 100)

  expect_equal(graph$k, nrow(u) - 1L)
  expect_equal(dim(graph$W), c(8, 8))
  expect_s4_class(graph$W, "sparseMatrix")
})

test_that("graph construction handles duplicated coordinates", {
  u <- rbind(
    c(0, 0),
    c(0, 0),
    c(1, 0),
    c(1, 1),
    c(0, 1)
  )
  graph <- build_graph_laplacian(u, k = 2)

  expect_true(is.finite(graph$sigma))
  expect_false(anyNA(graph$D_vec))
  expect_false(anyNA(graph$W@x))
  expect_s4_class(graph$W, "sparseMatrix")
})

test_that("graph construction validates invalid inputs", {
  u <- matrix(runif(10), ncol = 2)

  expect_error(build_graph_laplacian(u[1, , drop = FALSE]), "at least two")
  u_bad <- u
  u_bad[1, 1] <- NA_real_
  expect_error(build_graph_laplacian(u_bad), "finite")
  expect_error(build_graph_laplacian(u, k = 0), "k")
  expect_error(build_graph_laplacian(u, k = NA_real_), "k")
  expect_error(build_graph_laplacian(u, sigma = 0), "sigma")
  expect_error(build_graph_laplacian(u, sigma = Inf), "sigma")
})

test_that("graph construction does not use a full dense distance matrix", {
  body_text <- paste(deparse(body(build_graph_laplacian)), collapse = "\n")

  expect_false(grepl("stats::dist", body_text, fixed = TRUE))
  expect_false(grepl("as.matrix(stats::dist", body_text, fixed = TRUE))
})

test_that("spatial folds assign every location", {
  set.seed(2)
  u <- matrix(runif(60), ncol = 2)
  folds <- make_spatial_folds(u, K = 3, seed = 9)

  expect_length(folds, 30)
  expect_setequal(sort(unique(folds)), 1:3)
})
