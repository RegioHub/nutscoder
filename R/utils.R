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
nuts_join <- function(sf, nuts) {
  sf::st_join(sf, st_buffer_1km(nuts), sf::st_covered_by) |>
    sf::st_drop_geometry() |>
    dplyr::filter(!is.na(.data$nuts_1)) |>
    # Keep row(s) with the lowest NUTS level for each place
    dplyr::mutate(nuts_level = purrr::pmap_int(
      list(.data$nuts_1, .data$nuts_2, .data$nuts_3),
      \(...) 3L - sum(is.na(c(...)))
    )) |>
    dplyr::group_by(.data$place_id) |>
    dplyr::slice_max(.data$nuts_level) |>
    dplyr::ungroup() |>
    dplyr::select(.data$location, .data$name, .data$nuts_1, .data$nuts_2, .data$nuts_3)
}

st_buffer_1km <- function(sf) sf::st_buffer(sf, units::set_units(1000, m))
