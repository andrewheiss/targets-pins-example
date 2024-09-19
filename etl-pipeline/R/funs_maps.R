
make_example_map <- function() {
  library(leaflet)

  m <- leaflet() |>
    addTiles() |>
    setView(-116.19975993403531, 43.61772594375527, zoom = 16) |>
    addPopups(-116.19975993403531, 43.61772594375527, "Idaho State Capitol")
  
  return(m)
}
