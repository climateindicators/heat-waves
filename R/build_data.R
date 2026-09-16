# Build tidy long-format data for the Heat Waves indicator.
#
#   Rscript R/build_data.R
#
# Reads EPA's published figure CSVs in data-raw/ and writes data/*.csv plus
# data/meta.yml. Rerunning with unchanged inputs produces byte-identical output.
# Nothing here touches the network.
#
# TO UPDATE THE DATA: drop replacement CSVs into data-raw/ and rerun. Headers
# are asserted, not assumed, so a renamed or reordered column stops the build.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(tibble)
})

root <- here::here()
source(file.path(root, "R/utils/epa_csv.R"))
source(file.path(root, "R/utils/write_stable.R"))

raw_dir <- file.path(root, "data-raw")
out_dir <- file.path(root, "data")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# ---- Indicator constants -----------------------------------------------------

INDICATOR <- list(
  name                    = "Heat Waves",
  slug                    = "heat-waves",
  publisher               = "U.S. Environmental Protection Agency",
  source_page             = "https://19january2025snapshot.epa.gov/climate-indicators/climate-change-indicators-heat-waves/index.html",
  technical_documentation = "https://19january2025snapshot.epa.gov/system/files/documents/2024-06/heat-waves_documentation.pdf",
  rights                  = "Public domain, work of the U.S. Government (17 U.S.C. 105)"
)

# ---- Shared reshape helper ----------------------------------------------------

# Pivot a figure's series columns into long format and attach each series' key,
# label, and unit by joining a lookup table on the source header string, never
# on column position. A blank source cell is omitted rather than kept as an
# empty value, because an empty `value` would look like a real (zero)
# observation to a reader. What survives is split into `value` and a
# suppression `flag`, even though neither figure here carries one, so a future
# EPA update that introduces one (e.g. "Suppressed") fails loudly instead of
# silently becoming a bad number.
tidy_series <- function(df, id_cols, lookup) {
  out <- df |>
    tidyr::pivot_longer(
      cols      = -dplyr::all_of(id_cols),
      names_to  = "source_header",
      values_to = "raw_value"
    ) |>
    dplyr::filter(!is.na(raw_value), trimws(raw_value) != "") |>
    dplyr::inner_join(lookup, by = "source_header")

  split <- split_value_flag(out$raw_value)
  out$value <- split$value
  out$flag  <- split$flag
  out
}

# Turns "SALT_LAKE_CITY" into "Salt Lake City". Used only on the part of a
# Station code that is left after the trailing state abbreviation is dropped.
title_case_underscored <- function(x) {
  vapply(strsplit(x, "_"), function(w) {
    paste(toupper(substring(w, 1, 1)), tolower(substring(w, 2)), sep = "", collapse = " ")
  }, character(1))
}

# ---- Figure 1: Heat Wave Characteristics in the United States by Decade, 1961-2023 ----

f1_path <- file.path(raw_dir, "heat_waves_fig-1.csv")
f1_meta <- read_epa_preamble(f1_path)
f1_raw  <- read_epa_csv(f1_path)

# EPA's Units: line gives one unit per series, in the same order as the four
# columns below: number of heat waves, length of heat waves (days), length of
# heat wave season (days), degrees Fahrenheit.
FIG1_SERIES <- tibble::tribble(
  ~source_header,                                                             ~series_key, ~series_label,   ~unit,
  "Frequency (average number of heat waves per year)",                        "frequency", "Frequency",     "heat waves",
  "Duration (average number of individual heat waves)",                       "duration",  "Duration",      "days",
  "Season (average length of annual heat wave season)",                       "season",    "Season length", "days",
  "Intensity (average temperature above local threshold during heat waves)",  "intensity", "Intensity",     "°F"
)

assert_headers(
  f1_raw,
  id_cols          = "Decade",
  expected_headers = FIG1_SERIES$source_header,
  what             = "heat_waves_fig-1.csv"
)

f1 <- tidy_series(f1_raw, "Decade", FIG1_SERIES)
stopifnot("figure 1: no suppression flags expected" = all(f1$flag == ""))

f1 <- f1 |>
  dplyr::mutate(decade_start = sub("s$", "", Decade)) |>
  dplyr::rename(decade = Decade) |>
  dplyr::arrange(match(decade, f1_raw$Decade), match(series_key, FIG1_SERIES$series_key)) |>
  dplyr::select(decade, decade_start, series_key, series_label, unit, value)

assert_conservation(f1_raw, FIG1_SERIES$source_header, nrow(f1), "figure 1")

write_csv_stable(f1, file.path(out_dir, "heat_wave_characteristics_by_decade.csv"))

# ---- Figure 2: Heat Wave Characteristics in 50 Large U.S. Cities, 1961-2023 ----

f2_path <- file.path(raw_dir, "heat_waves_fig-2.csv")
f2_meta <- read_epa_preamble(f2_path)
f2_raw  <- read_epa_csv(f2_path)

# Same four characteristics as Figure 1, expressed here as the change over
# 1961-2023 rather than a decade average, so they share the same units.
FIG2_SERIES <- tibble::tribble(
  ~source_header,      ~series_key, ~series_label,   ~unit,
  "Frequency Change",  "frequency", "Frequency",     "heat waves",
  "Duration Change",   "duration",  "Duration",      "days",
  "Season Change",     "season",    "Season length", "days",
  "Intensity Change",  "intensity", "Intensity",     "°F"
)

assert_headers(
  f2_raw,
  id_cols          = c("Station", "Latitude", "Longitude"),
  expected_headers = FIG2_SERIES$source_header,
  what             = "heat_waves_fig-2.csv"
)

stopifnot(
  "figure 2: station codes should be unique" =
    !anyDuplicated(f2_raw[["Station"]]),
  "figure 2: station codes should end in an uppercase 2-letter state code" =
    all(grepl("_[A-Z]{2}$", f2_raw[["Station"]]))
)

f2 <- tidy_series(f2_raw, c("Station", "Latitude", "Longitude"), FIG2_SERIES)
stopifnot("figure 2: no suppression flags expected" = all(f2$flag == ""))

f2 <- f2 |>
  dplyr::mutate(
    state = sub(".*_([A-Z]{2})$", "\\1", Station),
    city  = title_case_underscored(sub("_[A-Z]{2}$", "", Station))
  ) |>
  dplyr::rename(station = Station, latitude = Latitude, longitude = Longitude) |>
  dplyr::arrange(match(station, f2_raw$Station), match(series_key, FIG2_SERIES$series_key)) |>
  dplyr::select(station, city, state, latitude, longitude, series_key, series_label, unit, value)

assert_conservation(f2_raw, FIG2_SERIES$source_header, nrow(f2), "figure 2")

write_csv_stable(f2, file.path(out_dir, "heat_wave_characteristics_by_city.csv"))

# ---- Figure 3: U.S. Annual Heat Wave Index, 1895-2021 ----

f3_path <- file.path(raw_dir, "heat_waves_fig-3.csv")
f3_meta <- read_epa_preamble(f3_path)
f3_raw  <- read_epa_csv(f3_path)

assert_headers(
  f3_raw,
  id_cols          = "Year",
  expected_headers = "Heat wave index",
  what             = "heat_waves_fig-3.csv"
)

# Already tidy: one row per year, one series. The earliest rows (1890-1894)
# carry no value because the published record starts in 1895; they are
# dropped rather than kept as an empty value, same reasoning as tidy_series().
f3 <- f3_raw |>
  dplyr::filter(trimws(`Heat wave index`) != "") |>
  dplyr::rename(year = Year, value = `Heat wave index`) |>
  dplyr::select(year, value)

assert_conservation(f3_raw, "Heat wave index", nrow(f3), "figure 3")

write_csv_stable(f3, file.path(out_dir, "heat_wave_index_annual.csv"))

# ---- Data dictionary ---------------------------------------------------------

col <- function(name, type, description) {
  list(name = name, type = type, description = description)
}

meta <- list(
  indicator = INDICATOR,
  datasets = list(
    list(
      file            = "heat_wave_characteristics_by_decade.csv",
      figure          = "Figure 1",
      figure_title    = f1_meta$title,
      source_file     = "heat_waves_fig-1.csv",
      source_sha256   = file_sha256(f1_path),
      source_encoding = "windows-1252",
      data_source     = f1_meta$data_source,
      web_update      = f1_meta$web_update,
      unit            = "varies by series; see the `unit` column",
      rows            = nrow(f1),
      columns         = list(
        col("decade", "string", "Decade label as published, e.g. \"1960s\""),
        col("decade_start", "integer", "First year of the decade, for ordering and axis breaks"),
        col("series_key", "string", "Machine-readable series identifier: frequency, duration, season, or intensity"),
        col("series_label", "string", "Display label, as used in EPA's published chart legend"),
        col("unit", "string", "Unit of `value`; this file mixes a count, two day counts, and degrees Fahrenheit, so `unit` varies by row"),
        col("value", "number", "Decade average for the series named in `series_key`, verbatim from the source file")
      )
    ),
    list(
      file            = "heat_wave_characteristics_by_city.csv",
      figure          = "Figure 2",
      figure_title    = f2_meta$title,
      source_file     = "heat_waves_fig-2.csv",
      source_sha256   = file_sha256(f2_path),
      source_encoding = "windows-1252",
      data_source     = f2_meta$data_source,
      web_update      = f2_meta$web_update,
      unit            = "varies by series; see the `unit` column",
      rows            = nrow(f2),
      columns         = list(
        col("station", "string", "EPA's station code, city name and state abbreviation joined by underscores, e.g. \"ALBANY_NY\""),
        col("city", "string", "City name, derived from `station`"),
        col("state", "string", "Two-letter state abbreviation, derived from `station`"),
        col("latitude", "number", "Station latitude in decimal degrees north"),
        col("longitude", "number", "Station longitude in decimal degrees east (negative is west)"),
        col("series_key", "string", "Machine-readable series identifier: frequency, duration, season, or intensity"),
        col("series_label", "string", "Display label, as used in EPA's published chart legend"),
        col("unit", "string", "Unit of `value`; this file mixes a count, two day counts, and degrees Fahrenheit, so `unit` varies by row"),
        col("value", "number", "Change from 1961 to 2023 in the series named in `series_key`, verbatim from the source file")
      )
    ),
    list(
      file            = "heat_wave_index_annual.csv",
      figure          = "Figure 3",
      figure_title    = f3_meta$title,
      source_file     = "heat_waves_fig-3.csv",
      source_sha256   = file_sha256(f3_path),
      source_encoding = "windows-1252",
      data_source     = f3_meta$data_source,
      web_update      = f3_meta$web_update,
      unit            = f3_meta$units,
      rows            = nrow(f3),
      columns         = list(
        col("year", "integer", "Calendar year"),
        col("value", "number", "U.S. Annual Heat Wave Index, verbatim from the source file")
      )
    )
  )
)

write_yaml_stable(meta, file.path(out_dir, "meta.yml"))

# ---- Verify what was written -------------------------------------------------

written <- list.files(out_dir, pattern = "[.](csv|yml)$", full.names = TRUE)
invisible(lapply(written, assert_clean_output))

cat("\nWrote:\n")
for (p in written) {
  cat(sprintf("  %-34s %8d bytes  %s\n", basename(p), file.size(p), substr(file_sha256(p), 1, 12)))
}
