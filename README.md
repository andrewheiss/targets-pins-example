

This repository contains four folders/projects. Only two are really
important:

1.  `etl-pipeline`: This uses {targets} to grab and clean and store data
    from a remote data store (in this case, for the sake of example, a
    web API). The resulting data is stored in `pins/` using {pins}.
2.  `site-pipeline`: This uses Quarto to build a website using the data
    that currently in {pins}.

The other two are helper folders/projects:

- `election-playground`: This is a little Python flask app that spits
  out random numbers every five minutes. You can either run it locally
  using Docker, or visit
  \<`https://election-testing.andhs.co/county?county=blah`\>, changing
  “blah” to whatever you want.
- `pins`: This is an empty folder that {pins} will use as a pinboard for
  storing R objects across projects. In real life, this can be anywhere,
  though.

## General process

This process has two independent moving parts:

1.  The `etl-pipeline` runs every X minutes and is in charge of
    collecting the most recent data. With the magic of {targets}, it
    will only process remote data that has changed since the last time
    the pipeline ran. All the data goes into a pinboard.
2.  The `site-pipeline` can run every Y minutes and pulls the latest
    data from the pinboard.

For example, the ETL pipeline could run on a cronjob set to run every 2
minutes to keep everything constantly updated in the background. The
website can be built at any time (through cron, or manually, or
whatever), and it will grab the most current data in the pinboard.
