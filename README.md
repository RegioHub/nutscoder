
<!-- README.md is generated from README.Rmd. Please edit that file -->

# nutscoder

{nutscoder} provides the function `nuts_geocode`, which attempts to find
[NUTS region codes](https://ec.europa.eu/eurostat/web/nuts/background)
for location names.

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/nutscoder)](https://CRAN.R-project.org/package=nutscoder)
[![R-CMD-check](https://github.com/long39ng/nutscoder/workflows/R-CMD-check/badge.svg)](https://github.com/long39ng/nutscoder/actions)
<!-- badges: end -->

## Installation

You can install the development version of {nutscoder} like so:

``` r
remotes::install_github("long39ng/nutscoder")
```

## Examples

``` r
library(nutscoder)
nuts_geocode(c("Hamburgo", "هامبورغ", "HH", "Berlin", "🐻Bärlin", "ベルリン",
               "North Rhine-Westphalia", "nrw"))
#> # A tibble: 8 × 5
#>   location               name                nuts_1 nuts_2 nuts_3
#>   <chr>                  <chr>               <chr>  <chr>  <chr> 
#> 1 Hamburgo               Hamburg             DE6    DE60   DE600 
#> 2 هامبورغ                Hamburg             DE6    DE60   DE600 
#> 3 HH                     Hamburg             DE6    DE60   DE600 
#> 4 Berlin                 Berlin              DE3    DE30   DE300 
#> 5 🐻Bärlin               Berlin              DE3    DE30   DE300 
#> 6 ベルリン               Berlin              DE3    DE30   DE300 
#> 7 North Rhine-Westphalia Nordrhein-Westfalen DEA    <NA>   <NA>  
#> 8 nrw                    Nordrhein-Westfalen DEA    <NA>   <NA>
```

The [sf](https://r-spatial.github.io/sf/) geometry of the geocoded NUTS
regions can be returned:

``` r
nuts_geocode(c("berlin", "brandenburg"), return_geometry = TRUE) |> 
  sf::st_geometry() |> 
  plot()
```

<img src="man/figures/README-unnamed-chunk-3-1.png" width="100%" />
