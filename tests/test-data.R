# Regression checks on the generated data for the Heat Waves indicator.
#
#   Rscript tests/test-data.R
#
# The checks below are shape-independent: they hold whatever the reshape in
# R/build_data.R turns each figure into. Value snapshots, which pin the actual
# numbers so a data update fails loudly instead of passing silently, are the
# TODO at the bottom.

setwd(here::here())
source("R/utils/write_stable.R")

# Keeps the dictionary check readable when a meta.yml field is absent altogether.
`%||%` <- function(a, b) if (is.null(a)) b else a

failures <- character()
check <- function(label, ok) {
  ok <- isTRUE(ok)
  cat(sprintf("  [%s] %s\n", if (ok) "PASS" else "FAIL", label))
  if (!ok) failures <<- c(failures, label)
  invisible(ok)
}

rd <- function(f) {
  readr::read_csv(file.path("data", f),
                  col_types = readr::cols(.default = readr::col_character()),
                  na = character(), progress = FALSE)
}

meta <- yaml::read_yaml("data/meta.yml")

cat("\nData dictionary\n")
check("meta.yml documents 3 dataset(s)", length(meta$datasets) == 3L)
check("meta.yml has no timestamp",
      !any(grepl("\\d{4}-\\d{2}-\\d{2}T|Sys\\.time|generated_at",
                 readLines("data/meta.yml", warn = FALSE))))

for (ds in meta$datasets) {
  df   <- rd(ds$file)
  cols <- vapply(ds$columns, function(x) x$name, character(1))
  check(sprintf("%s: meta.yml lists the columns the file actually has", ds$file),
        identical(cols, names(df)))
  check(sprintf("%s: meta.yml row count matches the file", ds$file),
        identical(as.integer(ds$rows), nrow(df)))
  check(sprintf("%s: every column has a type and a description", ds$file),
        all(vapply(ds$columns, function(x) nzchar(x$type %||% "") && nzchar(x$description %||% ""), logical(1))))
  check(sprintf("%s: source file is still present and unchanged", ds$file),
        identical(file_sha256(file.path("data-raw", ds$source_file)), ds$source_sha256))
  check(sprintf("%s: no blank rows", ds$file), nrow(df) > 0L)
}

cat("\nFile hygiene\n")
for (f in list.files("data", pattern = "[.](csv|yml)$", full.names = TRUE)) {
  check(sprintf("%s is UTF-8, LF, no BOM, no mojibake", basename(f)),
        tryCatch({ assert_clean_output(f); TRUE },
                 error = function(e) { cat("      ", conditionMessage(e), "\n"); FALSE }))
}

cat("\nValue snapshots\n")

decade <- rd("heat_wave_characteristics_by_decade.csv")
check("decade: 28 rows (7 decades x 4 series)", nrow(decade) == 28L)
check("decade: first row is 1960s frequency",
      identical(decade$decade[1], "1960s") &&
        identical(decade$series_key[1], "frequency") &&
        identical(decade$value[1], "2.172"))
check("decade: last row is 2020s intensity",
      identical(decade$decade[28], "2020s") &&
        identical(decade$series_key[28], "intensity") &&
        identical(decade$value[28], "2.534534896"))
check("decade: value ranges from 1.949738461 to 69.94",
      identical(min(as.numeric(decade$value)), 1.949738461) &&
        identical(max(as.numeric(decade$value)), 69.94))

city <- rd("heat_wave_characteristics_by_city.csv")
check("city: 200 rows (50 stations x 4 series)", nrow(city) == 200L)
check("city: first row is Albany, NY frequency",
      identical(city$station[1], "ALBANY_NY") &&
        identical(city$city[1], "Albany") &&
        identical(city$state[1], "NY") &&
        identical(city$series_key[1], "frequency") &&
        identical(city$value[1], "3.273809524"))
check("city: last row is Tulsa, OK intensity",
      identical(city$station[200], "TULSA_OK") &&
        identical(city$series_key[200], "intensity") &&
        identical(city$value[200], "0.853401462"))
check("city: value ranges from -0.749159192 (Memphis duration) to 139.7291667 (San Juan season)",
      identical(min(as.numeric(city$value)), -0.749159192) &&
        identical(max(as.numeric(city$value)), 139.7291667))

index <- rd("heat_wave_index_annual.csv")
check("index: 127 rows (1895-2021)", nrow(index) == 127L)
check("index: first row is 1895", identical(index$year[1], "1895") &&
        identical(index$value[1], "0.034"))
check("index: last row is 2021", identical(index$year[127], "2021") &&
        identical(index$value[127], "0.226"))
check("index: value ranges from 0.001 (1903) to 1.338 (1936, the Dust Bowl peak)",
      identical(min(as.numeric(index$value)), 0.001) &&
        identical(max(as.numeric(index$value)), 1.338))

cat("\n")
if (length(failures)) {
  cat(sprintf("%d FAILED:\n", length(failures)))
  for (f in failures) cat("  -", f, "\n")
  quit(status = 1L)
}
cat("All data checks passed.\n")
