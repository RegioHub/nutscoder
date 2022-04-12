
<!-- README.md is generated from README.Rmd. Please edit that file -->

# nutscoder

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/nutscoder)](https://CRAN.R-project.org/package=nutscoder)
[![R-CMD-check](https://github.com/long39ng/nutscoder/workflows/R-CMD-check/badge.svg)](https://github.com/long39ng/nutscoder/actions)
<!-- badges: end -->

## Installation

You can install the development version of nutscoder like so:

``` r
remotes::install_github("long39ng/nutscoder")
```

## Example

``` r
library(nutscoder)
nuts_geocode(c("munich", "hamburg"))
#> # A tibble: 2 × 5
#>   location name    nuts_1 nuts_2 nuts_3
#>   <chr>    <chr>   <chr>  <chr>  <chr> 
#> 1 hamburg  Hamburg DE6    DE60   DE600 
#> 2 munich   München DE2    DE21   DE212
```
