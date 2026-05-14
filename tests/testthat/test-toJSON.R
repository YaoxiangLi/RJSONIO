test_that("toJSON serializes scalar vectors", {
  expect_true(isValidJSON(I(toJSON(c(TRUE, FALSE)))))
  expect_equal(fromJSON(toJSON(c(TRUE, FALSE))), c(TRUE, FALSE))

  expect_true(isValidJSON(I(toJSON(c(1, 2, 3)))))
  expect_equal(fromJSON(toJSON(c(1, 2, 3))), c(1, 2, 3))

  expect_true(isValidJSON(I(toJSON(c("abc", "xyz")))))
  expect_equal(fromJSON(toJSON(c("abc", "xyz"))), c("abc", "xyz"))
})

test_that("toJSON preserves names as object keys", {
  expect_equal(fromJSON(toJSON(c(a = TRUE)))[["a"]], TRUE)
  expect_equal(fromJSON(toJSON(c(a = 1)))[["a"]], 1)
  expect_equal(fromJSON(toJSON(c(a = "xyz")))[["a"]], "xyz")
})

test_that("toJSON serializes arrays, tables, matrices, and data frames as valid JSON", {
  values <- array(1:(5 * 7 * 9), c(5, 7, 9))
  expect_true(isValidJSON(I(toJSON(values))))
  expect_type(fromJSON(I(toJSON(values))), "list")

  expect_true(isValidJSON(I(toJSON(table(1:3)))))
  expect_true(isValidJSON(I(toJSON(table(1:3, 1:3)))))

  mat <- matrix(1:4, nrow = 2)
  expect_true(isValidJSON(I(toJSON(mat))))

  data <- data.frame(a = 1:2, b = c("x", "y"))
  expect_true(isValidJSON(I(toJSON(data))))
})

test_that("toJSON serializes environments and S4 objects without changing public methods", {
  env <- new.env(parent = emptyenv())
  env$a <- 1:3
  env$bc <- letters[1:3]
  expect_true(isValidJSON(I(toJSON(env))))

  setClass("RJSONIOTestClass", representation(x = "integer", label = "character"))
  object <- new("RJSONIOTestClass", x = 1:3, label = "abc")
  expect_true(isValidJSON(I(toJSON(object))))

  setClass("RJSONIOFoo", representation(a = "integer", b = "character"))
  setClass("RJSONIOBar", representation(a = "integer", b = "character"))
  expect_true(isClass("RJSONIOFoo"))
  expect_true(isClass("RJSONIOBar"))
})

test_that("asJSVars returns JavaScript variable assignments invisibly", {
  result <- asJSVars(a = 1:3, b = "x")

  expect_type(result, "character")
  expect_match(result, "a =")
  expect_match(result, "b =")
  expect_match(result, "\\[")
})
