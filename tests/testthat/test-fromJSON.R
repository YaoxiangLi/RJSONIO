test_that("fromJSON parses arrays and objects from text", {
  expect_equal(fromJSON("[1, 3, 10, 19]"), c(1, 3, 10, 19))
  expect_equal(fromJSON(I("[3.1415]")), 3.1415)

  object <- fromJSON('{"a": 1, "b": true, "c": "value"}')
  expect_equal(object$a, 1)
  expect_true(object$b)
  expect_equal(object$c, "value")
})

test_that("fromJSON preserves current numeric behavior for integer-looking values", {
  expect_equal(fromJSON("[123]")[[1]], 123)
  expect_type(fromJSON("[123]")[[1]], "double")

  expect_equal(fromJSON("[12345678901]")[[1]], 12345678901)
  expect_type(fromJSON("[12345678901]")[[1]], "double")
  expect_equal(fromJSON("[-12345678901]")[[1]], -12345678901)
})

test_that("fromJSON supports explicit null replacement values", {
  expect_equal(
    fromJSON("[1, null, 4]", asText = TRUE, simplify = TRUE, nullValue = -999L),
    c(1, -999, 4)
  )
  expect_equal(
    fromJSON('["a", null, "d"]', asText = TRUE, simplify = TRUE, nullValue = "999"),
    c("a", "999", "d")
  )
})

test_that("fromJSON keeps current permissive trailing-comma behavior", {
  expect_equal(unlist(fromJSON("[1, 2, 3,]"), use.names = FALSE), c(1, 2, 3))
  expect_true(isValidJSON(I("[1, 2, 3,]")))
  expect_true(isValidJSON(I("[1, 2, 3]")))
})

test_that("basicJSONHandler can collect parser events", {
  handler <- basicJSONHandler()
  fromJSON("[1, 3, 10, 19]", handler$update)

  expect_equal(unlist(handler$value(), use.names = FALSE), c(1, 3, 10, 19))
})
