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
nuts_join <- function(sf, nuts, return_geometry) {
  ret <- sf::st_join(sf, st_buffer_1km(nuts), sf::st_covered_by) |>
    sf::st_drop_geometry() |>
    dplyr::filter(!is.na(.data$nuts_1)) |>
    nuts_slice_lowest() |>
    dplyr::select(.data$location, .data$name, .data$nuts_1, .data$nuts_2, .data$nuts_3)

  if (isTRUE(return_geometry)) {
    ret <- nutscoder::de_nuts_osm_sf |>
      dplyr::right_join(ret, by = c("name", "nuts_1", "nuts_2", "nuts_3"))
  }

  ret
}

nuts_slice_lowest <- function(nuts_df) {
  nuts_df |>
    dplyr::mutate(
      nuts_level = purrr::pmap_int(
        list(.data$nuts_1, .data$nuts_2, .data$nuts_3),
        \(...) 3L - sum(is.na(c(...)))
      ),
      row_nr = dplyr::row_number()
    ) |>
    dplyr::group_by(.data$location) |>
    dplyr::slice_max(.data$nuts_level) |>
    dplyr::ungroup() |>
    dplyr::mutate(location = as.character(.data$location)) |>
    dplyr::arrange(.data$row_nr) |>
    dplyr::select(-.data$row_nr)
}

st_buffer_1km <- function(sf) sf::st_buffer(sf, units::set_units(1000, m))
