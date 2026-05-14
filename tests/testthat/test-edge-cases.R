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

test_that("lists with empty vectors keep current parsed structure", {
  expect_equal(
    fromJSON(toJSON(list(x = 1, y = character(0)))),
    list(x = 1, y = structure(list(), class = "AsIs"))
  )
  expect_equal(
    fromJSON(toJSON(list(x = 1, y = character(0), b = 1))),
    list(x = 1, y = structure(list(), class = "AsIs"), b = 1)
  )
  expect_equal(
    fromJSON(toJSON(list(x = vector(), y = 123, z = "allo"))),
    list(x = structure(list(), class = "AsIs"), y = 123, z = "allo")
  )
})

test_that("bundled UTF-8 news fixture remains parseable", {
  load(test_path("../newsUTF8.rda"))

  parsed <- fromJSON(news)
  expect_type(parsed, "list")
  expect_named(parsed, c("offset", "results", "tokens", "total"))
})
