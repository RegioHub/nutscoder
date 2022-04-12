.onLoad <- function(libname, pkgname) {
  osm_geometry <<- memoise::memoise(osm_geometry)

  st_buffer_1km <<- memoise::memoise(st_buffer_1km)
}
