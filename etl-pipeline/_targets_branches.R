library(targets)
library(tarchetypes)
suppressPackageStartupMessages(library(dplyr))

# Set target options
tar_option_set(
  packages = c("tibble"),  # Packages that all target functions have access to
  format = "qs",  # Store finished targets with qs instead of rds
  controller = crew::crew_controller_local(workers = 4, seconds_idle = 60)  # Use 4 workers
)

# Source all the R scripts in the R/ folder
tar_source()

# Make a little dataset of all the counties and build their corresponding URLs
#
# IN REAL LIFE this wouldn't actuall work this way---you'd access the 
# county-level data through a database or whatever, not an API
counties <- tribble(
  ~county,
  "Ada",
  "Canyon",
  "Kootenai",
  "Bonneville",
  "Twin Falls",
  "Bannock",
  "Madison"
) |> 
  mutate(url = glue::glue(
    "https://election-testing.andhs.co/county?county={URLencode(county)}"
  )) |> 
  # Create an R-friendly object name for each county
  mutate(target_name = janitor::make_clean_names(county))

# The actual pipeline
list(
  # tar_map() dynamically builds a bunch of targets based on a list or dataframe
  # Here, it uses the `counties` dataframe
  tar_map(
    values = counties,
    names = target_name,
    descriptions = NULL,

    # Grab and clean and process the latest data from the remote source only if 
    # it has changed since the last time
    tar_change(
      results,
      parse_clean_county(county, url),
      change = get_latest_timestamp(url)
    ),

    # Store the latest data through pins
    tar_target(
      pinned,
      pin_county(results, name = paste0(target_name, "_cleaned"))
    )
  )
)
