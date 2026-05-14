#!/usr/bin/env Rscript

required <- c("bench", "ggplot2")
missing_required <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_required)) {
  stop(
    "Install required benchmark packages first: ",
    paste(missing_required, collapse = ", "),
    call. = FALSE
  )
}

if (!requireNamespace("RJSONIO", quietly = TRUE)) {
  stop("RJSONIO must be installed before running competitor benchmarks.", call. = FALSE)
}

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
result_dir <- file.path(root, "benchmarks", "results")
figure_dir <- file.path(root, "benchmarks", "figures")
article_figure_dir <- file.path(root, "vignettes", "figures", "benchmarks")
dir.create(result_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(article_figure_dir, recursive = TRUE, showWarnings = FALSE)

iterations <- as.integer(Sys.getenv("RJSONIO_BENCH_ITERATIONS", "20"))
if (is.na(iterations) || iterations < 1L) {
  iterations <- 20L
}

set.seed(20260514)

payloads <- list(
  numeric_vector = rpois(10000, lambda = 4),
  data_frame = data.frame(
    id = seq_len(2000),
    value = round(rnorm(2000), 6),
    flag = rep(c(TRUE, FALSE), 1000),
    label = sprintf("row-%04d", seq_len(2000)),
    stringsAsFactors = FALSE
  ),
  nested_list = list(
    name = "RJSONIO benchmark payload",
    created = "2026-05-14",
    records = replicate(
      500,
      list(
        id = sample.int(100000, 1),
        values = as.list(round(runif(8), 6)),
        active = sample(c(TRUE, FALSE), 1),
        tags = as.list(sample(letters, 4))
      ),
      simplify = FALSE
    )
  )
)

canonical_json <- lapply(payloads, RJSONIO::toJSON)
payload_files <- lapply(names(canonical_json), function(name) {
  path <- tempfile(pattern = paste0("rjsonio-", name, "-"), fileext = ".json")
  writeLines(canonical_json[[name]], path, useBytes = TRUE)
  path
})
names(payload_files) <- names(canonical_json)
on.exit(unlink(unlist(payload_files), force = TRUE), add = TRUE)

has_fun <- function(package, fun) {
  requireNamespace(package, quietly = TRUE) && exists(fun, envir = asNamespace(package), inherits = FALSE)
}

adapters <- list(
  RJSONIO = list(
    package = "RJSONIO",
    parse_string = function(json) RJSONIO::fromJSON(json),
    parse_file = function(path) RJSONIO::fromJSON(path),
    write_json = function(object) RJSONIO::toJSON(object),
    validate_json = function(json) RJSONIO::isValidJSON(I(json)),
    roundtrip = function(object) RJSONIO::fromJSON(RJSONIO::toJSON(object))
  ),
  jsonlite = list(
    package = "jsonlite",
    parse_string = function(json) jsonlite::fromJSON(json, simplifyVector = FALSE),
    parse_file = function(path) jsonlite::fromJSON(path, simplifyVector = FALSE),
    write_json = function(object) jsonlite::toJSON(object, auto_unbox = TRUE, dataframe = "columns"),
    validate_json = function(json) jsonlite::validate(json),
    roundtrip = function(object) jsonlite::fromJSON(
      jsonlite::toJSON(object, auto_unbox = TRUE, dataframe = "columns"),
      simplifyVector = FALSE
    )
  ),
  rjson = list(
    package = "rjson",
    parse_string = function(json) rjson::fromJSON(json_str = json),
    parse_file = function(path) rjson::fromJSON(file = path),
    write_json = function(object) rjson::toJSON(object),
    validate_json = NULL,
    roundtrip = function(object) rjson::fromJSON(json_str = rjson::toJSON(object))
  ),
  yyjsonr = list(
    package = "yyjsonr",
    parse_string = function(json) yyjsonr::read_json_str(json),
    parse_file = function(path) yyjsonr::read_json_file(path),
    write_json = function(object) yyjsonr::write_json_str(object),
    validate_json = function(json) yyjsonr::validate_json_str(json),
    roundtrip = function(object) yyjsonr::read_json_str(yyjsonr::write_json_str(object))
  ),
  jsonify = list(
    package = "jsonify",
    parse_string = function(json) jsonify::from_json(json),
    parse_file = NULL,
    write_json = function(object) jsonify::to_json(object),
    validate_json = function(json) jsonify::validate_json(json),
    roundtrip = function(object) jsonify::from_json(jsonify::to_json(object))
  ),
  RcppSimdJson = list(
    package = "RcppSimdJson",
    parse_string = function(json) RcppSimdJson::fparse(json),
    parse_file = function(path) RcppSimdJson::fload(path),
    write_json = NULL,
    validate_json = NULL,
    roundtrip = NULL
  ),
  rjsoncons = list(
    package = "rjsoncons",
    parse_string = function(json) rjsoncons::as_r(json),
    parse_file = function(path) rjsoncons::as_r(path),
    write_json = NULL,
    validate_json = NULL,
    roundtrip = NULL
  )
)

jobs <- c("parse_string", "parse_file", "write_json", "validate_json", "roundtrip")

benchmark_one <- function(package_name, payload_name, job_name, fn) {
  elapsed <- bench::mark(
    fn(),
    iterations = iterations,
    check = FALSE,
    filter_gc = TRUE
  )

  data.frame(
    package = package_name,
    payload = payload_name,
    job = job_name,
    iterations = iterations,
    median_sec = as.numeric(elapsed$median, units = "secs"),
    itr_sec = as.numeric(elapsed$`itr/sec`),
    mem_alloc_bytes = as.numeric(elapsed$mem_alloc),
    stringsAsFactors = FALSE
  )
}

results <- list()
skips <- list()

add_skip <- function(package, payload, job, reason) {
  skips[[length(skips) + 1L]] <<- data.frame(
    package = package,
    payload = payload,
    job = job,
    reason = reason,
    stringsAsFactors = FALSE
  )
}

for (adapter_name in names(adapters)) {
  adapter <- adapters[[adapter_name]]
  if (!requireNamespace(adapter$package, quietly = TRUE)) {
    for (payload_name in names(payloads)) {
      for (job_name in jobs) {
        add_skip(adapter_name, payload_name, job_name, "package is not installed")
      }
    }
    next
  }

  for (payload_name in names(payloads)) {
    for (job_name in jobs) {
      operation <- adapter[[job_name]]
      if (is.null(operation)) {
        add_skip(adapter_name, payload_name, job_name, "operation is not supported by adapter")
        next
      }

      fn <- switch(
        job_name,
        parse_string = function() operation(canonical_json[[payload_name]]),
        parse_file = function() operation(payload_files[[payload_name]]),
        write_json = function() operation(payloads[[payload_name]]),
        validate_json = function() operation(canonical_json[[payload_name]]),
        roundtrip = function() operation(payloads[[payload_name]])
      )

      trial <- try(fn(), silent = TRUE)
      if (inherits(trial, "try-error")) {
        add_skip(adapter_name, payload_name, job_name, conditionMessage(attr(trial, "condition")))
        next
      }

      timed <- try(benchmark_one(adapter_name, payload_name, job_name, fn), silent = TRUE)
      if (inherits(timed, "try-error")) {
        add_skip(adapter_name, payload_name, job_name, conditionMessage(attr(timed, "condition")))
      } else {
        results[[length(results) + 1L]] <- timed
      }
    }
  }
}

result_data <- if (length(results)) {
  do.call(rbind, results)
} else {
  data.frame(
    package = character(),
    payload = character(),
    job = character(),
    iterations = integer(),
    median_sec = numeric(),
    itr_sec = numeric(),
    mem_alloc_bytes = numeric(),
    stringsAsFactors = FALSE
  )
}

skip_data <- if (length(skips)) {
  do.call(rbind, skips)
} else {
  data.frame(package = character(), payload = character(), job = character(), reason = character())
}

packages <- names(adapters)
package_versions <- data.frame(
  package = packages,
  installed = vapply(packages, requireNamespace, logical(1), quietly = TRUE),
  version = vapply(
    packages,
    function(package) {
      if (requireNamespace(package, quietly = TRUE)) {
        as.character(utils::packageVersion(package))
      } else {
        NA_character_
      }
    },
    character(1)
  ),
  stringsAsFactors = FALSE
)

environment_info <- data.frame(
  field = c("date", "r_version", "platform", "iterations"),
  value = c(
    as.character(Sys.time()),
    R.version.string,
    R.version$platform,
    as.character(iterations)
  ),
  stringsAsFactors = FALSE
)

utils::write.csv(result_data, file.path(result_dir, "benchmark-results.csv"), row.names = FALSE)
utils::write.csv(skip_data, file.path(result_dir, "benchmark-skips.csv"), row.names = FALSE)
utils::write.csv(package_versions, file.path(result_dir, "package-versions.csv"), row.names = FALSE)
utils::write.csv(environment_info, file.path(result_dir, "environment.csv"), row.names = FALSE)

plot_data <- result_data[result_data$median_sec > 0, , drop = FALSE]

save_plot <- function(plot, filename, width = 11, height = 7) {
  path <- file.path(figure_dir, filename)
  ggplot2::ggsave(path, plot, width = width, height = height, dpi = 160)
  invisible(file.copy(path, file.path(article_figure_dir, filename), overwrite = TRUE))
}

if (nrow(plot_data)) {
  job_labels <- c(
    parse_string = "Parse string",
    parse_file = "Parse file",
    write_json = "Write JSON",
    validate_json = "Validate JSON",
    roundtrip = "Round trip"
  )
  payload_labels <- c(
    numeric_vector = "Numeric vector",
    data_frame = "Data frame",
    nested_list = "Nested list"
  )
  package_levels <- names(adapters)
  plot_data$package <- factor(plot_data$package, levels = rev(package_levels))
  plot_data$job_label <- factor(job_labels[plot_data$job], levels = job_labels)
  plot_data$payload_label <- factor(payload_labels[plot_data$payload], levels = payload_labels)
  plot_data$mem_alloc_mb <- plot_data$mem_alloc_bytes / (1024^2)
  plot_data$median_ms <- plot_data$median_sec * 1000
  plot_data$mem_label <- ifelse(plot_data$mem_alloc_mb >= 1,
    sprintf("%.1f MB", plot_data$mem_alloc_mb),
    sprintf("%.0f KB", plot_data$mem_alloc_mb * 1024)
  )

  format_ms <- function(x) {
    ifelse(x < 0.1, sprintf("%.2f ms", x),
      ifelse(x < 10, sprintf("%.1f ms", x), sprintf("%.0f ms", x))
    )
  }

  memory_plot_data <- plot_data[plot_data$mem_alloc_mb > 0, , drop = FALSE]

  baseline <- plot_data[plot_data$package == "RJSONIO", c("payload", "job", "median_sec")]
  names(baseline)[3] <- "rjsonio_median_sec"
  relative_data <- merge(plot_data, baseline, by = c("payload", "job"))
  relative_data$relative_to_rjsonio <- relative_data$median_sec / relative_data$rjsonio_median_sec
  relative_data$log2_relative <- log2(relative_data$relative_to_rjsonio)
  relative_data$ratio_label <- ifelse(
    relative_data$relative_to_rjsonio < 0.01,
    "<0.01x",
    sprintf("%.2fx", relative_data$relative_to_rjsonio)
  )
  relative_data$label <- paste0(
    relative_data$ratio_label,
    "\n",
    format_ms(relative_data$median_sec * 1000)
  )
  relative_data$package <- factor(relative_data$package, levels = rev(package_levels))
  relative_data$job_label <- factor(job_labels[relative_data$job], levels = job_labels)
  relative_data$payload_label <- factor(payload_labels[relative_data$payload], levels = payload_labels)

  summary_plot <- ggplot2::ggplot(
    relative_data,
    ggplot2::aes(x = job_label, y = package, fill = log2_relative)
  ) +
    ggplot2::geom_tile(color = "white", linewidth = 0.7) +
    ggplot2::geom_text(ggplot2::aes(label = label), size = 3.1, lineheight = 0.9) +
    ggplot2::scale_fill_gradient2(
      low = "#2c7fb8",
      mid = "white",
      high = "#d95f0e",
      midpoint = 0,
      breaks = log2(c(0.25, 0.5, 1, 2, 4)),
      labels = c("0.25x", "0.5x", "1x", "2x", "4x"),
      name = "Time vs\nRJSONIO"
    ) +
    ggplot2::facet_wrap(~ payload_label, ncol = 1) +
    ggplot2::labs(
      title = "Relative elapsed time by package and JSON task",
      subtitle = "Each cell shows median time relative to RJSONIO, then absolute median time. Lower ratios are faster.",
      x = NULL,
      y = NULL
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      legend.position = "right",
      panel.grid = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text(angle = 25, hjust = 1)
    )

  elapsed_plot <- ggplot2::ggplot(
    plot_data,
    ggplot2::aes(x = job_label, y = package, fill = log10(median_ms))
  ) +
    ggplot2::geom_tile(color = "white", linewidth = 0.7) +
    ggplot2::geom_text(ggplot2::aes(label = format_ms(median_ms)), size = 3.1) +
    ggplot2::scale_fill_gradient(
      low = "#eef5fb",
      high = "#1f5a8a",
      name = "Median\nms, log10"
    ) +
    ggplot2::facet_wrap(~ payload_label, ncol = 1) +
    ggplot2::labs(
      title = "Median elapsed time for each benchmark task",
      subtitle = "Each cell shows the median time in milliseconds. Darker cells took longer.",
      x = NULL,
      y = NULL
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      panel.grid = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text(angle = 25, hjust = 1),
      legend.position = "right"
    )

  memory_plot <- ggplot2::ggplot(
    memory_plot_data,
    ggplot2::aes(x = job_label, y = package, fill = log10(mem_alloc_mb))
  ) +
    ggplot2::geom_tile(color = "white", linewidth = 0.7) +
    ggplot2::geom_text(ggplot2::aes(label = mem_label), size = 3.1) +
    ggplot2::scale_fill_gradient(
      low = "#eef7ee",
      high = "#2f6b3f",
      name = "Memory\nMB, log10"
    ) +
    ggplot2::facet_wrap(~ payload_label, ncol = 1) +
    ggplot2::labs(
      title = "Memory allocated for each benchmark task",
      subtitle = "Each cell shows memory allocated by the measured expression. Darker cells allocated more memory.",
      x = NULL,
      y = NULL
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      panel.grid = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text(angle = 25, hjust = 1),
      legend.position = "right"
    )

  relative_plot <- ggplot2::ggplot(
    relative_data,
    ggplot2::aes(x = job_label, y = package, fill = log2_relative)
  ) +
    ggplot2::geom_tile(color = "white", linewidth = 0.7) +
    ggplot2::geom_text(ggplot2::aes(label = ratio_label), size = 3.1) +
    ggplot2::scale_fill_gradient2(
      low = "#2c7fb8",
      mid = "white",
      high = "#d95f0e",
      midpoint = 0,
      breaks = log2(c(0.25, 0.5, 1, 2, 4)),
      labels = c("0.25x", "0.5x", "1x", "2x", "4x"),
      name = "Time vs\nRJSONIO"
    ) +
    ggplot2::facet_wrap(~ payload_label, ncol = 1) +
    ggplot2::labs(
      title = "Elapsed time ratio compared with RJSONIO",
      subtitle = "RJSONIO is 1.00x for each task and payload. Blue is faster; orange is slower.",
      x = NULL,
      y = NULL
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      panel.grid = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text(angle = 25, hjust = 1),
      legend.position = "right"
    )

  save_plot(summary_plot, "benchmark-summary.png", width = 10, height = 8.5)
  save_plot(elapsed_plot, "elapsed-time.png", width = 15, height = 9)
  save_plot(memory_plot, "memory-allocation.png", width = 15, height = 9)
  save_plot(relative_plot, "relative-time.png", width = 15, height = 9)
}

invisible(file.copy(
  file.path(result_dir, c("benchmark-results.csv", "benchmark-skips.csv", "package-versions.csv", "environment.csv")),
  article_figure_dir,
  overwrite = TRUE
))

cat("Benchmark rows: ", nrow(result_data), "\n", sep = "")
cat("Skipped rows: ", nrow(skip_data), "\n", sep = "")
cat("Results: ", result_dir, "\n", sep = "")
cat("Figures: ", figure_dir, "\n", sep = "")
