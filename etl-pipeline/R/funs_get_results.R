get_latest_timestamp <- function(url) {
  library(httr2)

  response <- request(url) |>
    req_perform() |>
    resp_body_json()

  response |>
    purrr::pluck("last-modified")
}

parse_clean_county <- function(county, url) {
  library(httr2)

  response <- request(url) |>
    req_perform() |>
    resp_body_json()

  list(
    county = county,
    timestamp = response$`last-modified`,
    next_update = response$`next-update`,
    vote_total = response$value
  )
}

pin_object <- function(x, name) {
  library(pins)

  board <- board_folder("../pins")
  board |> pin_write(x, name = name, type = "qs")
}

build_presidential_results <- function(x) {
  # Do stuff here to get presidential results from each of the counties
  all_counties <- bind_rows(x)

  total <- sum(all_counties$vote_total)

  return(total)
}

build_cd_results <- function(x, district) {
  # Do stuff here to get congressional results from each of the counties
  all_counties <- bind_rows(x)

  total <- sum(all_counties$vote_total)

  return(lst(district, total))
}

build_close_race <- function(x) {
  # Do stuff here to determine which races are close
  all_counties <- bind_rows(x)

  close_races <- all_counties |> 
    filter(vote_total <= 10000)

  return(close_races)
}

make_huge_thing <- function() {
  set.seed(1234)

  blah <- tibble(x = rnorm(100000000))

  return(blah)
}
