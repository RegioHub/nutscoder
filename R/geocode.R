#' Get NUTS codes for location strings
#'
#' @param locations Character vector of locations to geocode
#' @param nominatim_api URL of the Nominatim API
#' @param return_geometry If TRUE, returns the sf geometry of the geocoded NUTS
#'   regions
#'
#' @return A data.frame with 5 columns:
#'   - location: The input in the `location` argument
#'   - name: Name of the geocoded NUTS region
#'   - nuts_1, nuts_2, nuts_3: Official region code at NUTS-1, 2, and 3
#' @export
#'
#' @examples
#' nuts_geocode(c("munich", "hamburg"))
nuts_geocode <- function(locations,
                         nominatim_api = "https://nominatim.openstreetmap.org",
                         return_geometry = FALSE) {
  purrr::map_dfr(locations, osm_geometry, nominatim_api) |>
    nuts_join(nutscoder::de_nuts_osm_sf, return_geometry)
}
