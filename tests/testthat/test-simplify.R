test_that("simplify modes preserve current mixed-vector behavior", {
  expect_type(fromJSON('[1, "2.3", "abc"]', simplify = TRUE), "character")
  expect_type(fromJSON('[1, true, "2.3", "abc"]', simplify = TRUE), "character")
  expect_type(fromJSON('["1", true]', simplify = TRUE), "character")

  expect_type(fromJSON("[1, true]", simplify = TRUE), "double")
  expect_type(fromJSON('{ "a": "1", "b": true}', simplify = TRUE), "character")
})

test_that("Strict simplification keeps incompatible values as lists", {
  expect_type(fromJSON('[1, "2.3", "abc"]', simplify = Strict), "list")
  expect_type(fromJSON('[1, true, "2.3", "abc"]', simplify = Strict), "list")
  expect_type(fromJSON("[1, true]", simplify = Strict), "list")
  expect_type(fromJSON('{ "a": "1", "b": true}', simplify = Strict), "list")
})

test_that("Strict simplification still simplifies compatible object values", {
  expect_type(fromJSON('{ "a": "1", "b": "true"}', simplify = Strict), "character")
  expect_type(fromJSON('{ "a": 1, "b": 2}', simplify = Strict), "double")
  expect_type(fromJSON('{ "a": 1, "b": 2}', simplify = FALSE), "list")
})

test_that("nullValue can preserve missing positions in simplified vectors", {
  expect_true(all(is.na(fromJSON(toJSON(c("a", NA, "b", "c")), nullValue = NA, simplify = TRUE)[2])))
  expect_true(all(is.na(fromJSON(toJSON(c(1, NA, 3, 4)), nullValue = NA, simplify = TRUE)[2])))
  expect_true(all(is.na(fromJSON(toJSON(c(TRUE, NA, FALSE, TRUE)), nullValue = NA, simplify = TRUE)[2])))
})
