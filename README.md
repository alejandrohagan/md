# My Project


## Overview

This is a collection of utilities to help with the management,
administration and navigation of [duckdb](https://duckdb.org/) database
either locally on your computer or in the cloud via
[motherduck](https://motherduck.com/)

Database management is incredibly easy in R with fantastic packages such
as [DBI](https://dbplyr.tidyverse.org/) and
[dbplyr](https://dbplyr.tidyverse.org/), however some databases have
specific extensions or utilities that are aren’t readily accessible via
this packages

{md} pack simplifies these common database administration task with easy
to understand syntax. {md} is built upon
[DBI](https://dbplyr.tidyverse.org/) and returns a lazy DBI object so
that you can further fully integrate your data with
[dbplyr](https://dbplyr.tidyverse.org/)

## Future ambition

Eventually, I’ll use the learning from this package to create a meta DB
utilities package so that regardless if you’re in snowflake, DuckDB,
Redshift, etc you will have generalized functions that work across your
database types

This is very much work in progress – I’ll eventually transition to the
[R7](https://rconsortium.github.io/S7/articles/S7.html) object system
but just want to get some usage first before deciding on the
architecture and structure.

Please create an issue if you have any comments or requests or reach out
if you have any feedback.

## Overview of functions

Below is a quick overview of the functions available in the package.

### Functions that help you manage your connection and duckdb specific extensions

- `connect_to_motherduck()` will leverage your motherduck token to
  connect you to your motherduck instance (it will install the
  motherduck extension if not already present)
- `install_extensions()` will install various duckdb extensions from the
  official repository
- `load_extensions()` will load a duckdb extensions either from an
  official repository
- `validate_md_connection_statu()` will validate your motherduck
  connection status
- `validate_extension_install_status()` will validate if an extension
  has been successfully installed
- `validate_extension_load_status()` will validate if an extension has
  been successfully loaded

### Functions that help you see what is in your databases

- `pwd()` prints the current database that you are “in”
- `cd()` will change your “root” database so any execution functions are
  relative to that database (eg. CREATE SCHEMA)
- `list_database()` list the databases and their metadata
- `list_schema()`list the schemas and their metadata
- `list_table()`list the tables and their metadata
- `list_all_table()`list all tables across all databases
- `list_view()`list the views and their metadata

### Functions that will help you read data into duckdb or motherduck

- `read_httpfs()` will read httpfs file formats
- `read_parquet()` will read parquet file formats
- `read_excel()` will read excel files formats

### Functions that will help you create or replace databases, scehems, tables or views

- `create_or_replace_database()` will take R data and create a database
  with your data
- `create_or_replace_schemas()` will take R data and create a schema
  with your data
- `create_or_replace_view()` will take R data and create a views with
  your data
- `create_or_replace_table()` will take R data and create a tables with
  your data
- `drop_table()` will delete a table from your databases
- `drop_database()` will delete a database

## Functions to help you manage motherduck users, tokens, and instance settings

- `list_md_active_accounts()` list users with active duckling instances
  (note: will not list inactive users)
- `list_md_user_instance()` list a user’s instance settings
- `list_md_user_tokens()` list user’s tokens
- `show_current_user()` show your current user name
- `create_md_user()` create user or service account in your organization
- `delete_md_user()` delete a user or service account
- `create_md_access_token()` create an access token for a user
- `delete_md_access_token()` delete an access token for a user
- `configure_md_user_settings()` configure a user’s instance settings

### Functions to help you understand your data

- `summary()` will summarize your table or view’s data

## What do I need to use this?

- [duckdb](https://duckdb.org/) R package installed on your computer
- A [motherduck](https://motherduck.com/) account
- A motherduck access token which you you can be saved to your R
  environment file with `usethis::edit_r_environ()`

> [!NOTE]
>
> ### Whats the difference between Motherduck and Duckdb?
>
> - Duckdb is a database that you can deploy and run either temporary or
>   permanently in your computer. If you run it via your local computer,
>   it is only available on your computer
>
> - Motherduck is a cloud based deployment of duckdb which means you can
>   save your data in the cloud or access it locally
>
> - Most core functions in this package work for both motherduck or
>   duckdb database
>
> - It is more of a question if you want you data to be access only
>   locally on your computer or if you want to be able to access it
>   remotely via the cloud

## Lets see the package in action

### Create a duckdb instance and Connect to your motherduck account

When creating a duckdb database, you have three options

1.  A in-memory based instance that exists in your local computer
2.  A file based instance that exists in your local computer
3.  A cloud-based instance through [motherduck](https://motherduck.com/)

To create options 1 or 2 you can simply use either the
[duckdb](https://duckdb.org/) or the
[duckplyr](https://duckplyr.tidyverse.org/index.html) packages.

To use option 3, you will need to create a motherudck account and
generate an access token. Once created, save your access token to an
your R enviorment with `usethis::edit_r_environ()`. I recommend using
`MOTHERDUCK_TOKEN` as your variable name.

Once completed, you can simply use the `connect_to_motherduck()`
function and pass through your token variable name and optional
configuration options.

``` r
con_md <- connect_to_motherduck("MOTHERDUCK_TOKEN")
```

    ── Extension Load & Install Report ─────────────────────────────────────────────

    Installed and loaded 1 extension: motherduck

    Use `list_extensions()` to list extensions, status and their descriptions

    Use `install_extensions()` to install new duckdb extensions

    See <https://duckdb.org/docs/stable/extensions/overview.html> for more
    information

    ✔ You are connected to MotherDuck

This will return a connection and print statement indicating if
connection status.

At any time you can validate your connection status with
`validate_md_connection_status()`

``` r
validate_md_connection_status(con_md)
```

    ✔ You are connected to MotherDuck

> [!NOTE]
>
> ### how to create a motherduck account and access token?
>
> 1.  Go to [motherduck](https://motherduck.com/) and create an account,
>     free options are available
> 2.  Go to your user name in the top right, click settings then click
>     access tokens
> 3.  Click create token and then name your token and copy the token
>     code
> 4.  You will need this token to access your account
> 5.  If you want to access it via R then simplest way is to save your
>     access code as a variable in your r environment
> 6.  Simply leverage the [usethis](https://usethis.r-lib.org/) function
>     `edit_r_environ()` to set your access code to a variable and save
>     it – this is one time activity
> 7.  To check if your correctly saved your variable then you can use
>     the Sys.getenv(“var_name”) with “var_name” the named you assigned
>     your access token to
> 8.  Going forward, if you want to access your token you don’t need to
>     re-type the access token, simply remember your variable name
>
> - First you will need a motherduck account, which has both free and
>   paid tiers
>
> - Once you’ve created an account, simply, go to your settings and
>   click ‘Access Tokens’ under your ‘Integrations’
>
> - Keep this secure and safe as this lets you connect to your online
>   database to read or write data
>
> - Open R and use the `usethis::edit_r_environ()` function to put your
>   motherduck token as a variable in your enviornment profile
>
>   - MOTHERDUCK_TOKEN=‘tokenID’
>
> - From there you can use the
>   `connect_to_motherduck("MOTHERDUCK_TOKEN")`
>
> - This will use the [DBI](https://dbi.r-dbi.org/) library to create a
>   connection to your mother duck instance

When connecting to motherduck there are a number of configuration
options available, you can reference them via the `md::db_config` which
will pull a list of options and their default values

To change these, simply edit the configuration options you want and then
pass the list as an argument `connect_to_motherduck()` or `duckdb()` if
connecting locally

You can see the full list of duckdb configuration options
[here](https://duckdb.org/docs/stable/configuration/overview.html) or
alternatively you can use `list_settings()` to see your current
configuration options.

``` r
config <- md::db_config #<1> get list of default configuration options


config$allow_community_extensions <- "true" #<2> change a default option

con_md <- connect_to_motherduck("MOTHERDUCK_TOKEN",config = config) #<3> pass the modified list to your connection
```

At any time you can see what configuration arguments are for your
connection with `md::list_settings()`.

``` r
list_setting(con_md)
```

Congratulations, you’ve set connected to your motherduck database from
R!

If you’re new to databases, it will be helpful to have a basic
understanding of database management - don’t worry the basics are
straight forward and won’t overwhelm you, below are a list of resources
I found helpful.

- [Posit solutions guide to working with
  databases](https://solutions.posit.co/connections/db/)
- [dbplyr package
  page](https://dbplyr.tidyverse.org/articles/dbplyr.html)
- [Motherduck how to
  guide](https://motherduck.com/docs/key-tasks/authenticating-and-connecting-to-motherduck/)
- [duckdb documentation
  guide](https://duckdb.org/docs/stable/sql/introduction)

Please see the {md} package down website to see additional documentation
on how to use the functions and motherduck
