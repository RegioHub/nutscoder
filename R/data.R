#' German NUTS regions
#'
#' A dataset containing the names, NUTS codes, and geographic geometries of
#'   German administrative regions
#'
#' @format An [sf][sf::sf] object with 444 features and 4 fields:
#' \describe{
#'  - name: Name of the region
#'  - nuts_1, nuts_2, nuts_3: Official region code at NUTS-1, 2, and 3
#' }
#'
#' @source <https://www.openstreetmap.org>, <https://overpass-api.de/api/interpreter>, <https://nominatim.openstreetmap.org/details>
"de_nuts_osm_sf"
