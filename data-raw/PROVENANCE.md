# Provenance

Every file in this directory is reproduced unmodified from EPA's published
indicator page and its per-figure data downloads. To update the data, replace the
file and rerun `Rscript R/build_data.R`.

## Indicator page

- `source-page.html`  \
  <https://19january2025snapshot.epa.gov/climate-indicators/climate-change-indicators-heat-waves/index.html>  \
  sha256 `1c5337350851e5ea2525b5e484c3bcc39624c5b43964b1a5763566d8cf8b6d40`

Technical documentation: <https://19january2025snapshot.epa.gov/system/files/documents/2024-06/heat-waves_documentation.pdf>

## Figure data

- `heat_waves_fig-1.csv`  \
  <https://19january2025snapshot.epa.gov/system/files/other-files/2024-06/heat_waves_fig-1.csv>  \
  sha256 `17dccf1b23121a62ef98fffbb08509acc0df13aa60f08bd2ea4dfe4f6655f173`  \
  encoding windows-1252, 7 data rows, columns: `Decade`, `Frequency (average number of heat waves per year)`, `Duration (average number of individual heat waves)`, `Season (average length of annual heat wave season)`, `Intensity (average temperature above local threshold during heat waves)`  \
  title: Figure 1. Heat Wave Characteristics in the United States by Decade, 1961–2023  \
  data source: NOAA, 2024; web update: June 2024; units: number of heat waves; length of heat waves (days); length of heat wave season (days); °F

- `heat_waves_fig-2.csv`  \
  <https://19january2025snapshot.epa.gov/system/files/other-files/2024-06/heat_waves_fig-2.csv>  \
  sha256 `f9bb568ccda2a2bea2755b885af190d4e4d6432be69c06c74948aa2e8070fa43`  \
  encoding windows-1252, 50 data rows, columns: `Station`, `Latitude`, `Longitude`, `Frequency Change`, `Duration Change`, `Season Change`, `Intensity Change`  \
  title: Figure 2. Heat Wave Characteristics in 50 Large U.S. Cities, 1961–2023  \
  data source: NOAA, 2024; web update: June 2024; units: degrees; degrees; number of heat waves; length of heat waves (days); length of heat wave season (days); °F

- `heat_waves_fig-3.csv`  \
  <https://19january2025snapshot.epa.gov/system/files/other-files/2022-07/heat_waves_fig-3.csv>  \
  sha256 `f4ce28f7516d97d9ee2e118fd132db13971734e193aac981b91fa7b029f826bb`  \
  encoding windows-1252, 132 data rows, columns: `Year`, `Heat wave index`  \
  title: Figure 3. U.S. Annual Heat Wave Index, 1895–2021  \
  data source: Kunkel, 2022; web update: July 2022; units: heat wave index
