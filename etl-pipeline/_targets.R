library(targets)
library(tarchetypes)
suppressPackageStartupMessages(library(dplyr))

# Set target options
tar_option_set(
  packages = c("dplyr"),  # Packages that all target functions have access to
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
  ~county,      ~congressional_district,
  "Ada",        1,
  "Canyon",     1, 
  "Kootenai",   2,
  "Bonneville", 2,
  "Twin Falls", 1,
  "Bannock",    2,
  "Madison",    1
) |> 
  mutate(url = glue::glue(
    # "http://localhost:8000/county?county={URLencode(county)}"
    "https://election-testing.andhs.co/county?county={URLencode(county)}"
  )) |> 
  # Create an R-friendly object name for each county
  mutate(
    target_name = janitor::make_clean_names(county),
    results_target_name = paste0("results_", target_name)
  )


cleaned_counties <- list(
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
      pin_object(results, name = paste0(target_name, "_cleaned"))
    )
  )
)

# The actual pipeline
list(
  cleaned_counties,

  tar_combine(
    presidential_counties,
    tar_select_targets(cleaned_counties, any_of(counties$results_target_name)),
    command = list(!!!.x)
  ),

  tar_combine(
    cd1_counties,
    tar_select_targets(
      cleaned_counties, 
      one_of(
        counties |> 
          filter(congressional_district == 1) |> 
          pull(results_target_name)
      )
    ),
    command = list(!!!.x)
  ),

  tar_combine(
    cd2_counties,
    tar_select_targets(
      cleaned_counties, 
      one_of(
        counties |> 
          filter(congressional_district == 2) |> 
          pull(results_target_name)
      )
    ),
    command = list(!!!.x)
  ),

  # Aggregate all presidential-level results and store it as a pinned object
  tar_target(
    results_presidential, 
    build_presidential_results(presidential_counties)
  ),
  tar_target(
    results_presidential_pinned, 
    pin_object(results_presidential, "results_presidential")
  ),

  # Aggregate the two congressional district-level results and store them as pinned objects
  tar_target(results_cd1, build_cd_results(cd1_counties, "District 1")),
  tar_target(results_cd1_pinned, pin_object(results_cd1, "results_cd1")),

  tar_target(results_cd2, build_cd_results(cd2_counties, "District 2")),
  tar_target(results_cd2_pinned, pin_object(results_cd2, "results_cd2")),

  # Make a leaflet map here
  tar_target(example_map, make_example_map()),
  tar_target(example_map_pinned, pin_object(example_map, "example_map"))
)
