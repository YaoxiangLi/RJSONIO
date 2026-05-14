test_that("empty JSON arrays and objects keep current structures", {
  expect_identical(fromJSON("[]"), structure(list(), class = "AsIs"))
  expect_identical(fromJSON("{}"), structure(list(), names = character()))
  expect_identical(emptyNamedList, structure(list(), names = character()))
})

test_that("scientific notation parses consistently across exponent cases", {
  parsed <- fromJSON("[3.14e4, 3.14E4]")

  expect_equal(parsed[[1]], parsed[[2]])
  expect_equal(parsed[[1]], 31400)
})

test_that("character and numeric NA values can be serialized and restored with nullValue", {
  expect_true(is.na(fromJSON(toJSON(c("a", NA, "b")), nullValue = NA, simplify = TRUE)[2]))
  expect_true(is.na(fromJSON(toJSON(c(1, NA, 3)), nullValue = NA, simplify = TRUE)[2]))
})

test_that("scalarCollapse preserves current nested-list behavior", {
  nested <- list(1, 2, list(NA))
  encoded <- toJSON(nested)

  expect_true(isValidJSON(I(encoded)))
  expect_type(fromJSON(encoded, simplify = FALSE), "list")
})
