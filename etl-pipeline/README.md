

> [!NOTE]
>
> In this example, total vote counts are randomly generated every 5
> minutes at `https://election-testing.andhs.co/county?county=blah`. In
> real life, the vote totals would be grabbed from actual sources in a
> database or wherever.

There are two pipelines that illustrate how {targets} can be used to
orchestrate ETL processing:

1.  *Note! This is just for illustrating the manual process of builting
    county-specific targets. IRL, the other targets pipeline (see below)
    is much better and more automatic.* `_targets_manual.R`: This
    defines a set of three targets for each county:

    - `results_COUNTY_change`: This checks the API to see if results
      have changed since the last time they were collected. The object
      itself contains the timestamp of the last update.
    - `results_COUNTY`: This object contains the cleaned up data for the
      county.
    - `pinned_COUNTY`: This object contains the name of the object that
      is pinned at the pinboard data store.

2.  `_targets.R`: This [dynamically defines a set of targets using
    static branching](https://books.ropensci.org/targets/static.html)
    for each county instead of needing to define each one manually:

    - `results_change_COUNTY`: This checks the API to see if results
      have changed since the last time they were collected. The object
      itself contains the timestamp of the last update.
    - `results_COUNTY`: This object contains the cleaned up data for the
      county.
    - `pinned_COUNTY`: This object contains the name of the object that
      is pinned at the pinboard data store.

**Only one pipeline can be active, though, and the corresponding file
needs to be named `_targets.R`, so rename one of the files accordingly
before running `tar_make()`.**

------------------------------------------------------------------------

# General process

1.  Run `targets::tar_make()`.
2.  R will grab the latest data for all the counties specificed in the
    pipeline. If there’s new data, it will reprocess it; if there’s no
    new data, it will skip it and use the current version.
3.  R will then push the latest data (if any) to a pinboard stored at
    `../pins` (in real life, this could be stored anywhere, though).
4.  You can use this pinned data from any other project.
