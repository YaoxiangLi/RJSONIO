test_that("stringFun can transform parsed strings with an R function", {
  json <- '[ 1, "abc", "xyz"]'

  expect_equal(
    fromJSON(json, stringFun = function(value) sprintf("xxx_%s", value)),
    list(1, "xxx_abc", "xxx_xyz")
  )
})

test_that("stringFun return type controls simplified vector type", {
  json <- '[ "1", "2.3", "3.1415"]'

  expect_type(fromJSON(json), "character")
  expect_type(fromJSON(json, stringFun = function(value) as.numeric(value)), "double")
  expect_type(fromJSON(json, stringFun = function(value) TRUE), "logical")
})

test_that("registered native string routines remain available", {
  json <- '[ 1, "abc", "xyz"]'

  expect_type(fromJSON(json, stringFun = "R_json_dateStringOp"), "list")
  expect_type(
    fromJSON(json, stringFun = structure("R_json_dateStringOp", class = "SEXPRoutine")),
    "list"
  )
})

test_that("native date string routine converts date-like strings when simplification is disabled", {
  json <- '[ 1, "/new Date(12312313)", "/Date(12312313)"]'
  parsed <- fromJSON(json, stringFun = "R_json_dateStringOp", simplify = FALSE)

  expect_true(is(parsed[[1]], "numeric"))
  expect_true(is(parsed[[2]], "POSIXct"))
  expect_true(is(parsed[[3]], "POSIXct"))
})
