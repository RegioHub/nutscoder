osm_geometry <- function(location, nominatim_api) {
  stopifnot(length(location) == 1L)

  httr2::request(nominatim_api) |>
    httr2::req_url_path_append("search") |>
    httr2::req_url_query(
      q = location,
      limit = 1,
      format = "geojson",
      polygon_geojson = 1
    ) |>
    httr2::req_retry(max_tries = 5) |>
    httr2::req_perform() |>
    httr2::resp_body_string() |>
    sf::read_sf() |>
    dplyr::mutate(location = location, .before = dplyr::everything())
}

#' @importFrom dplyr .data
nuts_join <- function(geocoded_sf, nuts, return_geometry) {
  distinct_sf <- geocoded_sf |>
    dplyr::group_by(.data$place_id) |>
    dplyr::slice(1) |>
    dplyr::ungroup() |>
    dplyr::select(.data$place_id)

  distinct_joined <- sf::st_join(distinct_sf, st_buffer_1km(nuts), sf::st_covered_by) |>
    sf::st_drop_geometry() |>
    nuts_slice_lowest()

  ret <- geocoded_sf |>
    sf::st_drop_geometry() |>
    dplyr::left_join(distinct_joined, by = "place_id") |>
    dplyr::select(.data$location, .data$name, .data$nuts_1, .data$nuts_2, .data$nuts_3)

  if (isTRUE(return_geometry)) {
    ret <- nutscoder::de_nuts_osm_sf |>
      dplyr::right_join(ret, by = c("name", "nuts_1", "nuts_2", "nuts_3"))
  }

  ret
}

nuts_slice_lowest <- function(locations_nuts) {
  locations_nuts |>
    dplyr::mutate(
      nuts_level = purrr::pmap_int(
        list(.data$nuts_1, .data$nuts_2, .data$nuts_3),
        \(...) 3L - sum(is.na(c(...)))
      )
    ) |>
    dplyr::group_by(.data$place_id) |>
    dplyr::slice_max(.data$nuts_level) |>
    dplyr::ungroup()
}

st_buffer_1km <- function(sf) sf::st_buffer(sf, units::set_units(1000, m))
