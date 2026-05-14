test_that("fromJSON reads JSON from text connections", {
  con <- textConnection(c("[[1,2,3,4],", "[5, 6, 7, 8]]"))
  on.exit(close(con), add = TRUE)

  expect_equal(fromJSON(con), list(1:4, 5:8))
})

test_that("fromJSON reads JSON from single text connections", {
  con <- textConnection("[1, 2, 3,\n4]")
  on.exit(close(con), add = TRUE)

  expect_equal(fromJSON(con), c(1, 2, 3, 4))
})

test_that("fromJSON reads package sample data from files", {
  path <- system.file("sampleData", "keys.json", package = "RJSONIO")
  expect_true(file.exists(path))

  parsed <- fromJSON(path)
  expect_type(parsed, "list")
})

test_that("readJSONStream parses from a connection", {
  path <- tempfile()
  writeLines("[1, 2, 3]", path, useBytes = TRUE)
  con <- file(path, open = "rb")
  on.exit({
    close(con)
    unlink(path)
  }, add = TRUE)

  expect_equal(readJSONStream(con), c(1, 2, 3))
})
