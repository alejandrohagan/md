# My Project


![](md_logo.png)

# My Project

This is WIP collection of utilities to help with the management,
administration and navigation of duckdb and motherduck databases

This will help you connect to motherduck database, create new databases,
install extensions or navigate between your various databases.

Eventually, I’ll use the learning here to create a meta DB utilities
package so that regardless if you’re in snowflake, DuckDB, redshift, etc
you will have generalized functions that work across your database
types.

I try to leverage linux style commands to minimize mental overhead
between switching in and out of other languages.

This is very much work in progress – I’ll eventually transition to the
R7 object system but just want to get some usage first before deciding
on the architecture and structure

## Features

- `pwd()` prints your current database that you are “in”
- `ls()` lists the databases that you have access to
- `cd()` will change your database
- `summarize()` will summarize your database table’s data
- `connect_to_md()` will leverage your motherduck token to connect you
  to your motherduck instance (it will install motherduck extension if
  not created)
- `install_extensions()` will install various duckdb extensions
- `validate_*()` collection of functions will just validate your
  connection and extension status
- `read_httpfs()` helps with reading httpfs formats
- `read_parquet()` helps with reading parquet files
- `create_or_replace_database()` will take R data and create a database
  with your data

## What do I need to use this?

- You need your own motherduck account and an access token which can be
  saved to your R environ file with `usethis::edit_r_environ()`

- Most functions are generalized and can work without local duckDB
  database
