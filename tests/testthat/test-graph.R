test_that("graph Laplacian has expected shape", {
  set.seed(1)
  u <- matrix(runif(40), ncol = 2)
  graph <- build_graph_laplacian(u, k = 4)

  expect_equal(dim(graph$L_sym), c(20, 20))
  expect_equal(length(graph$D_vec), 20)
  expect_true(all(graph$D_vec >= 0))
  expect_equal(length(graph$components_list[[1]]) >= 1, TRUE)
})

test_that("spatial folds assign every location", {
  set.seed(2)
  u <- matrix(runif(60), ncol = 2)
  folds <- make_spatial_folds(u, K = 3, seed = 9)

  expect_length(folds, 30)
  expect_setequal(sort(unique(folds)), 1:3)
})
