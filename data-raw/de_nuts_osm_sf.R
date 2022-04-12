library(httr2)
library(tidyverse)
library(sf)

# Utils -------------------------------------------------------------------

osm_geometry <- function(osmid, osmtype) {
  request("https://nominatim.openstreetmap.org/details") |>
    req_url_query(
      osmtype = osmtype,
      osmid = osmid,
      format = "json",
      polygon_geojson = 1
    ) |>
    req_retry(max_tries = 5) |>
    req_perform() |>
    resp_body_string() |>
    str_extract(r"[(?<=\"geometry\":).+(?=\}$)]") |>
    read_sf()
}

# Get NUTS regions from OSM -----------------------------------------------

overpass_query <- r"{
  [out:csv(::id,::type,name,"ref:nuts:1","ref:nuts:2","ref:nuts:3")][timeout:25];
  (
    relation["ref:nuts:1"~"^DE.$"];
    relation["ref:nuts:2"~"^DE..$"];
    relation["ref:nuts:3"~"^DE...$"];
  );
  out;
}"

de_nuts_osm <- request("https://overpass-api.de/api/interpreter") |>
  req_url_query(data = overpass_query) |>
  req_perform() |>
  resp_body_string() |>
  read_delim() |>
  janitor::clean_names() |>
  mutate(type = str_to_upper(str_sub(type, 1, 1))) |>
  arrange(ref_nuts_1, ref_nuts_2, ref_nuts_3)

# Check against official NUTS excel from EC -------------------------------

ec_nuts_excel <- here::here("data-raw/NUTS2021.xlsx")

download.file(
  "https://ec.europa.eu/eurostat/documents/345175/629341/NUTS2021.xlsx",
  ec_nuts_excel
)

de_nuts_ec <- readxl::read_xlsx(ec_nuts_excel, sheet = 2) |>
  janitor::clean_names() |>
  filter(startsWith(code_2021, "DE")) |>
  select(code_2021, starts_with("nuts"))

file.remove(ec_nuts_excel)

## In OSM but not in EC ----

map(1:3, \(x) {
  nuts_col <- paste0("ref_nuts_", x)

  de_nuts_osm |>
    drop_na(.data[[nuts_col]]) |>
    anti_join(
      de_nuts_ec |>
        filter(nuts_level == x),
      by = set_names("code_2021", nuts_col)
    )
})

de_nuts_osm <- de_nuts_osm |>
  filter(id != 1416133) # Osterode am Harz

## In EC but not in OSM ----

map(1:3, \(x) {
  de_nuts_ec |>
    filter(nuts_level == x) |>
    anti_join(de_nuts_osm, by = c("code_2021" = paste0("ref_nuts_", x)))
})

de_nuts_ec |>
  filter(nuts_level == 3) |>
  anti_join(de_nuts_osm, by = c("code_2021" = "ref_nuts_3"))
#> [[1]]
#> # A tibble: 1 × 5
#>   code_2021 nuts_level_1       nuts_level_2 nuts_level_3 nuts_level
#>   <chr>     <chr>              <chr>        <chr>             <dbl>
#> 1 DEZ       Extra-Regio NUTS 1 <NA>         <NA>                  1
#>
#> [[2]]
#> # A tibble: 11 × 5
#>    code_2021 nuts_level_1 nuts_level_2       nuts_level_3 nuts_level
#>    <chr>     <chr>        <chr>              <chr>             <dbl>
#>  1 DE91      <NA>         Braunschweig       <NA>                  2
#>  2 DE92      <NA>         Hannover           <NA>                  2
#>  3 DE93      <NA>         Lüneburg           <NA>                  2
#>  4 DE94      <NA>         Weser-Ems          <NA>                  2
#>  5 DEB1      <NA>         Koblenz            <NA>                  2
#>  6 DEB2      <NA>         Trier              <NA>                  2
#>  7 DEB3      <NA>         Rheinhessen-Pfalz  <NA>                  2
#>  8 DED2      <NA>         Dresden            <NA>                  2
#>  9 DED4      <NA>         Chemnitz           <NA>                  2
#> 10 DED5      <NA>         Leipzig            <NA>                  2
#> 11 DEZZ      <NA>         Extra-Regio NUTS 2 <NA>                  2
#>
#> [[3]]
#> # A tibble: 1 × 5
#>   code_2021 nuts_level_1 nuts_level_2 nuts_level_3       nuts_level
#>   <chr>     <chr>        <chr>        <chr>                   <dbl>
#> 1 DEZZZ     <NA>         <NA>         Extra-Regio NUTS 3          3

# TODO in later step: Create missing NUTS-2 as unions of suitable NUTS-3

# Get geometries for NUTS regions -----------------------------------------

de_nuts_osm_sf <- de_nuts_osm |>
  mutate(map2_dfr(id, type, osm_geometry)) |>
  st_as_sf()

# draft
de_nuts_osm |>
  drop_na(ref_nuts_3) |>
  add_count(ref_nuts_3) |>
  filter(n > 1)

de_nuts_osm_sf |>
  filter(ref_nuts_3 == "DEF0B") |>
  st_geometry() |>
  plot()

usethis::use_data(de_nuts_osm_sf, overwrite = TRUE)
library(httr2)
library(tidyverse)
library(sf)

# Utils -------------------------------------------------------------------

osm_geometry <- function(osmid, osmtype) {
  request("https://nominatim.openstreetmap.org/details") |>
    req_url_query(
      osmtype = osmtype,
      osmid = osmid,
      format = "json",
      polygon_geojson = 1
    ) |>
    req_retry(max_tries = 5) |>
    req_perform() |>
    resp_body_string() |>
    str_extract(r"[(?<=\"geometry\":).+(?=\}$)]") |>
    read_sf()
}

# Get NUTS regions from OSM -----------------------------------------------

overpass_query <- r"{
  [out:csv(::id,::type,name,"ref:nuts:1","ref:nuts:2","ref:nuts:3")][timeout:25];
  (
    relation["ref:nuts:1"~"^DE.$"];
    relation["ref:nuts:2"~"^DE..$"];
    relation["ref:nuts:3"~"^DE...$"];
  );
  out;
}"

de_nuts_osm <- request("https://overpass-api.de/api/interpreter") |>
  req_url_query(data = overpass_query) |>
  req_perform() |>
  resp_body_string() |>
  read_delim() |>
  janitor::clean_names() |>
  mutate(type = str_to_upper(str_sub(type, 1, 1))) |>
  # Duplicated: Birkenfeld, Stendal, Rendsburg
  filter(!id %in% c(1244279, 1284750, 548570)) |>
  arrange(ref_nuts_1, ref_nuts_2, ref_nuts_3)

# Check against official NUTS excel from EC -------------------------------

ec_nuts_excel <- here::here("data-raw/NUTS2021.xlsx")

download.file(
  "https://ec.europa.eu/eurostat/documents/345175/629341/NUTS2021.xlsx",
  ec_nuts_excel
)

de_nuts_ec <- readxl::read_xlsx(ec_nuts_excel, sheet = 2) |>
  janitor::clean_names() |>
  filter(startsWith(code_2021, "DE")) |>
  select(code_2021, starts_with("nuts"))

file.remove(ec_nuts_excel)

## In OSM but not in EC ----

map(1:3, \(x) {
  nuts_col <- paste0("ref_nuts_", x)

  de_nuts_osm |>
    drop_na(.data[[nuts_col]]) |>
    anti_join(
      de_nuts_ec |>
        filter(nuts_level == x),
      by = set_names("code_2021", nuts_col)
    )
})

de_nuts_osm <- de_nuts_osm |>
  filter(id != 1416133) # Osterode am Harz; merged with Göttingen

## In EC but not in OSM ----

map(1:3, \(x) {
  de_nuts_ec |>
    filter(nuts_level == x) |>
    anti_join(de_nuts_osm, by = c("code_2021" = paste0("ref_nuts_", x)))
})
#> [[1]]
#> # A tibble: 1 × 5
#>   code_2021 nuts_level_1       nuts_level_2 nuts_level_3 nuts_level
#>   <chr>     <chr>              <chr>        <chr>             <dbl>
#> 1 DEZ       Extra-Regio NUTS 1 <NA>         <NA>                  1
#>
#> [[2]]
#> # A tibble: 11 × 5
#>    code_2021 nuts_level_1 nuts_level_2       nuts_level_3 nuts_level
#>    <chr>     <chr>        <chr>              <chr>             <dbl>
#>  1 DE91      <NA>         Braunschweig       <NA>                  2
#>  2 DE92      <NA>         Hannover           <NA>                  2
#>  3 DE93      <NA>         Lüneburg           <NA>                  2
#>  4 DE94      <NA>         Weser-Ems          <NA>                  2
#>  5 DEB1      <NA>         Koblenz            <NA>                  2
#>  6 DEB2      <NA>         Trier              <NA>                  2
#>  7 DEB3      <NA>         Rheinhessen-Pfalz  <NA>                  2
#>  8 DED2      <NA>         Dresden            <NA>                  2
#>  9 DED4      <NA>         Chemnitz           <NA>                  2
#> 10 DED5      <NA>         Leipzig            <NA>                  2
#> 11 DEZZ      <NA>         Extra-Regio NUTS 2 <NA>                  2
#>
#> [[3]]
#> # A tibble: 1 × 5
#>   code_2021 nuts_level_1 nuts_level_2 nuts_level_3       nuts_level
#>   <chr>     <chr>        <chr>        <chr>                   <dbl>
#> 1 DEZZZ     <NA>         <NA>         Extra-Regio NUTS 3          3

# TODO in later step: Create missing NUTS-2 as unions of suitable NUTS-3

# Get geometries for NUTS regions -----------------------------------------

de_nuts_osm_sf <- de_nuts_osm |>
  mutate(map2_dfr(id, type, osm_geometry)) |>
  st_as_sf()

# Solve missing NUTS-2 regions --------------------------------------------

nuts2_missing <- de_nuts_ec |>
  filter(nuts_level == 2) |>
  anti_join(de_nuts_osm, by = c("code_2021" = "ref_nuts_2")) |>
  filter(code_2021 != "DEZZ") |>
  pull(code_2021)

nuts2_missing_sf <- map_dfr(nuts2_missing, \(x) {
  de_nuts_osm_sf |>
    filter(startsWith(ref_nuts_3, x)) |>
    st_union() |>
    st_sf(ref_nuts_2 = x) |>
    st_set_geometry("geometry") |>
    left_join(de_nuts_ec, by = c("ref_nuts_2" = "code_2021")) |>
    select(name = nuts_level_2, ref_nuts_2)
})

de_nuts_osm_sf <- bind_rows(de_nuts_osm_sf, nuts2_missing_sf) |>
  rename_with(str_remove, starts_with("ref_"), "^ref_") |>
  select(name, starts_with("nuts_")) |>
  mutate(
    nuts_2 = coalesce(nuts_2, str_sub(nuts_3, 1, 4)),
    nuts_1 = coalesce(nuts_1, str_sub(nuts_2, 1, 3))
  )

usethis::use_data(de_nuts_osm_sf, overwrite = TRUE)
