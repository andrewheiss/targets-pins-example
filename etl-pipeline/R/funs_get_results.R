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
