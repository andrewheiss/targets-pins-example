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

# The actual pipeline
list(
  # Grab and clean and process the latest data from the remote source only if 
  # it has changed since the last time
  tar_change(
    results_ada,
    parse_clean_county("Ada", "https://election-testing.andhs.co/county?county=Ada"),
    change = get_latest_timestamp("https://election-testing.andhs.co/county?county=Ada")
  ),

  # Store the latest data through pins
  tar_target(
    pinned_ada,
    pin_county(results_ada, name = "ada_cleaned")
  ),

  # Do it again for another county
  tar_change(
    results_canyon,
    parse_clean_county("Canyon", "https://election-testing.andhs.co/county?county=Canyon"),
    change = get_latest_timestamp("https://election-testing.andhs.co/county?county=Canyon")
  ),
  tar_target(
    pinned_canyon,
    pin_county(results_canyon, name = "canyon_cleaned")
  ),

  # And again
  tar_change(
    results_kootenai,
    parse_clean_county("Kootenai", "https://election-testing.andhs.co/county?county=Kootenai"),
    change = get_latest_timestamp("https://election-testing.andhs.co/county?county=Kootenai")
  ),
  tar_target(
    pinned_kootenai,
    pin_county(results_kootenai, name = "kootenai_cleaned")
  )

  # AND SO ON for all the other counties or precincts or whatever
)
