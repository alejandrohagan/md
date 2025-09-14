# My Project


<img src="md_logo.png" style="width:40.0%" />

# Developer notes

- create_or_replace_database doesn’t work if its local or temp database
  only mother duck – need to generalize logic
  - create subfunctions so we can use cli to showcase what is going on
    - need a function that returns a connection type eg local vs. md
    - If MD then do create or replace function
    - if not MD then simply do create schema, create table function
    - perhaps work backwards from create table?
- update and complete function documentation
- create tests with describes
- update documentation with more examples
  - how to create a database
  - how to upload existing data
  - how to move data around in a database
  - database admin options
  - how to upload data from source files w/o reading it locally
    - how to install extensions
    - csv
    - parquet
    - excel
    - another database
  - How to manage a database (MD only)
    - add a user
    - manager user instance
    - create access tokens
    - delete a user
    - xxx
  - [case study 1](motherduck.com/blog/semantic-layer-duckdb-tutorial/)
  - [case study 2](contoso%20package)
  - [case study 3](something%20machine%20learning)

# Overview

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

## future ambition

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

# Overview of functions

## functions that help you manage your connection and database metadata

- `connect_to_motherduck()` will leverage your motherduck token to
  connect you to your motherduck instance (it will install the
  motherduck extension if not already present)
- `install_extensions()` will install various duckdb extensions from the
  official repository or if you set the flag, a community repository
- `load_extensions()` will load a duckdb extensions either from an
  official repository
- `validate_md_connection_statu()` will validate your motherduck
  connection status
- `validate_extension_install_status()` will validate if an extension
  has been successfully installed
- `validate_extension_load_status()` will validate if an extension has
  been successfully loaded

## functions that help you see what is in your databases

- `pwd()` prints the current database that you are “in”
- `cd()` will change your “root” database so any execution functions are
  relative to that database
- `list_database()` list the databases and their metadata
- `list_schema()`list the schemas and their metadata
- `list_table()`list the tables and their metadata
- `list_view()`list the views and their metadata

## functions that will help you read data into duckdb or motherduck

- `read_httpfs()` will read httpfs file formats
- `read_parquet()` will read parquet file formats
- `read_excel()` will read excel files formats

## functions that will help you create or replace databases, scehems, tables or views

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

## functions to help you manage motherduck users, tokens, and instance settings

- `list_md_active_accounts()`
- `list_md_user_instance()`
- `list_md_user_tokens()`
- `show_current_user()`
- `create_md_user()`
- `delete_md_user()`
- `create_md_access_token()`
- `delete_md_access_token()`
- `configure_md_user_settings()`

## functions to help you understand your data

- `summary()` will summarize your table or view’s data

## What do I need to use this?

- [duckdb](https://duckdb.org/) package installed on your computer
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

# Lets see the package in action

## Create a duckdb instance and Connect to your motherduck account

When creating a duckdb database, you have three options

1.  A in-memory based instance that exists in your local computer
2.  A file based instance that exists in your local computer
3.  A cloud-based instance through [motherduck](https://motherduck.com/)

To create options 1 or 2 you can simply use either the
[duckdb](https://duckdb.org/) or the
[duckplyr](https://duckplyr.tidyverse.org/index.html)

To connect to your motherduck account you can still reference the above
packages but need to do few additional steps or alternatively you use
the `connect_to_motherduck()` function and pass through your token
variable name[^1] and optional configuration options

``` r
con_md <- connect_to_motherduck("MOTHERDUCK_TOKEN")
```

This will return a connection and print statement indicating if
connection status.

At any time you can validate your connection status with
`validate_md_connection_status()`

``` r
validate_md_connection_status(con_md)
```

When connecting to motherduck there are a number of configuration
options available, you can reference them via the `md::db_config` which
will pull a list of options and their default values

To change these, simply edit the configuration options you want and then
pass this as an argument

You can see the full list of duckdb configuration options
[here](https://duckdb.org/docs/stable/configuration/overview.html) or
alternatively you can use `list_settings()` to see your current
configuration options.

``` r
config <- md::db_config #<1> get list of default configuration options

config$allow_community_extensions <- "true" #<2> change a default option

con_md <- connect_to_motherduck("MOTHERDUCK_TOKEN",config = config) #<3> pass the modified list to your connection
```

``` r
list_setting(con_md)
```

<div>

<div id="xnklnhmigy" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#xnklnhmigy table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#xnklnhmigy thead, #xnklnhmigy tbody, #xnklnhmigy tfoot, #xnklnhmigy tr, #xnklnhmigy td, #xnklnhmigy th {
  border-style: none;
}
&#10;#xnklnhmigy p {
  margin: 0;
  padding: 0;
}
&#10;#xnklnhmigy .gt_table {
  display: table;
  border-collapse: collapse;
  line-height: normal;
  margin-left: auto;
  margin-right: auto;
  color: #333333;
  font-size: 16px;
  font-weight: normal;
  font-style: normal;
  background-color: #FFFFFF;
  width: auto;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #A8A8A8;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #A8A8A8;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
}
&#10;#xnklnhmigy .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#xnklnhmigy .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}
&#10;#xnklnhmigy .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 3px;
  padding-bottom: 5px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}
&#10;#xnklnhmigy .gt_heading {
  background-color: #FFFFFF;
  text-align: center;
  border-bottom-color: #FFFFFF;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}
&#10;#xnklnhmigy .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#xnklnhmigy .gt_col_headings {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}
&#10;#xnklnhmigy .gt_col_heading {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  overflow-x: hidden;
}
&#10;#xnklnhmigy .gt_column_spanner_outer {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  padding-top: 0;
  padding-bottom: 0;
  padding-left: 4px;
  padding-right: 4px;
}
&#10;#xnklnhmigy .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#xnklnhmigy .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#xnklnhmigy .gt_column_spanner {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 5px;
  overflow-x: hidden;
  display: inline-block;
  width: 100%;
}
&#10;#xnklnhmigy .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#xnklnhmigy .gt_group_heading {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  text-align: left;
}
&#10;#xnklnhmigy .gt_empty_group_heading {
  padding: 0.5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: middle;
}
&#10;#xnklnhmigy .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#xnklnhmigy .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#xnklnhmigy .gt_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  margin: 10px;
  border-top-style: solid;
  border-top-width: 1px;
  border-top-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  overflow-x: hidden;
}
&#10;#xnklnhmigy .gt_stub {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#xnklnhmigy .gt_stub_row_group {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
  vertical-align: top;
}
&#10;#xnklnhmigy .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#xnklnhmigy .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#xnklnhmigy .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#xnklnhmigy .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#xnklnhmigy .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#xnklnhmigy .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#xnklnhmigy .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#xnklnhmigy .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#xnklnhmigy .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#xnklnhmigy .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#xnklnhmigy .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#xnklnhmigy .gt_footnotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}
&#10;#xnklnhmigy .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#xnklnhmigy .gt_sourcenotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}
&#10;#xnklnhmigy .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#xnklnhmigy .gt_left {
  text-align: left;
}
&#10;#xnklnhmigy .gt_center {
  text-align: center;
}
&#10;#xnklnhmigy .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#xnklnhmigy .gt_font_normal {
  font-weight: normal;
}
&#10;#xnklnhmigy .gt_font_bold {
  font-weight: bold;
}
&#10;#xnklnhmigy .gt_font_italic {
  font-style: italic;
}
&#10;#xnklnhmigy .gt_super {
  font-size: 65%;
}
&#10;#xnklnhmigy .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#xnklnhmigy .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#xnklnhmigy .gt_indent_1 {
  text-indent: 5px;
}
&#10;#xnklnhmigy .gt_indent_2 {
  text-indent: 10px;
}
&#10;#xnklnhmigy .gt_indent_3 {
  text-indent: 15px;
}
&#10;#xnklnhmigy .gt_indent_4 {
  text-indent: 20px;
}
&#10;#xnklnhmigy .gt_indent_5 {
  text-indent: 25px;
}
</style>

| name                                        | value     | description                                                                                                    | input_type  | scope  |
|---------------------------------------------|-----------|----------------------------------------------------------------------------------------------------------------|-------------|--------|
| access_mode                                 | automatic | Access mode of the database (AUTOMATIC, READ_ONLY or READ_WRITE)                                               | VARCHAR     | GLOBAL |
| allocator_background_threads                | false     | Whether to enable the allocator background thread.                                                             | BOOLEAN     | GLOBAL |
| allocator_bulk_deallocation_flush_threshold | 512.0 MiB | If a bulk deallocation larger than this occurs, flush outstanding allocations.                                 | VARCHAR     | GLOBAL |
| allocator_flush_threshold                   | 128.0 MiB | Peak allocation threshold at which to flush the allocator after completing a task.                             | VARCHAR     | GLOBAL |
| allow_community_extensions                  | true      | Allow to load community built extensions                                                                       | BOOLEAN     | GLOBAL |
| allow_extensions_metadata_mismatch          | false     | Allow to load extensions with not compatible metadata                                                          | BOOLEAN     | GLOBAL |
| allow_persistent_secrets                    | true      | Allow the creation of persistent secrets, that are stored and loaded on restarts                               | BOOLEAN     | GLOBAL |
| allow_unredacted_secrets                    | false     | Allow printing unredacted secrets                                                                              | BOOLEAN     | GLOBAL |
| allow_unsigned_extensions                   | false     | Allow to load extensions with invalid or missing signatures                                                    | BOOLEAN     | GLOBAL |
| allowed_directories                         | \[\]      | List of directories/prefixes that are ALWAYS allowed to be queried - even when enable_external_access is false | VARCHAR\[\] | GLOBAL |

</div>

</div>

Congratulations, you’ve set up your motherduck database!

Now let’s load some data into it so we can play around with the options.

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

I’m not going to cover data engineering or database management in any
real depth mostly because I don’t know anything about it.

For most of your workflow, you would follow a typical pattern:

1.  Create a database, schema or table
2.  Upload, update or amend data to your table
3.  Query the data to do calculations, analytics or reference in
    dashboards

If you’re running a database that multiple users have access to (either
through cloud or on a local server) then a typical workflow may be

1.  Create a users with certain set of permissions and roles to a
    database
2.  Assign tokens / secrets to users so that they can access databaes
    remotely
3.  Manage database utilities such as scaling
4.  Run analytics on your database metadata

Let’s see these in action

> [!NOTE]
>
> ### DBI vs. md
>
> These functions are mainly sugar syntax wrappers around the fabulous
> DBI packages to stream and simplify common database queries.

## Create a database

Later on we will show examples of how to read data from a source file,
eg. csv, parquet, excel, or even a different database, directly into
duckdb but for now let’s assume its some data that you already have
loaded.

Before we get into that lets review quickly the three things you need to
load data into a database: - database name - This is object that will
hold your schemas, tables, functions, roles, permissions, etc - somtimes
this may be called a catalog - schema name - This of this as fancy name
to classify and organize your tables, functions, procedures, etc - By
default, duckdb will use “main” as a schema name - table or view name -
This is the name of the actual table or view that holds your data

To save or reference data, you need to fully qualify with
`database_name.schema_name.table_name`

If you uploaded data without creating a table or schema first then
duckdb will assign “temp” and “main” as the default names for your
database and schema respectively.

The quickest and easiest way to get data into duckdb is either use:

- duckdb::register_duckdb()
- md::create_or_replace_database()

The different is create_or_replace_database() gives you more control on
the database name and schema name

``` r
diamonds_tbl <- data(diamonds)

con_tmp <- create_local_temp_db()

diamonds_tbl |>
    md::create_or_replace_database(
        .con = con_tmp
        ,database_name = "temp"
        ,schema_name = "main"
        ,table_name = "diamonds"
        ,overwrite=FALSE
        )
```

Notice that we don’t assing this object to anything, this just silently
writes our data to our database, to validate the data is in our dtabase,
we can do the following:

DBI::xxxx

MD::list_tables()

After running these functions, we can see our table - ready for us to
query it.

to query, you can simply leverage dplyr::tbl() function to pull it and
from there leverage the fantastic dbplyr package to use tidy verbs to
perform additional functions

Let’s say we want to filter and summarize this table and save it to a
new schema with a new name – no problem, we can repeat the steps above
this time with a new schema and reference name.

``` r
duckdb::duckdb_register(con_tmp,name = "diamonds",diamonds_tbl)

tbl(con_tmp,"diamonds")

tbl(con_tmp,sql("select * from file1dbc839ef04b6.raw.diamonds"))

DBI::dbGetQuery(con_tmp,"select * from file1dbc839ef04b6.raw.diamonds")


create_or_replace_schema()


create_or_replace_table()
```

What if we want to delete or move a database, schema or table?

Now that the basics are covered, let us explore

# Database adminstrative functions

- list_extensions()

- install_extensions()

- load_extensions

- validate_install_status

- validate_load_status

- show_duckdb_settings()

- These are a collection of motherduck specific database utilities to
  help you list, install and load duckdb extensions

- the full list of extensions is available via duckdb community store
  are listed
  [here](https://duckdb.org/docs/stable/core_extensions/overview.html)

- the `list_extensions()` will list duckdb extension from the community
  store and list their status, install or loaded

- you can use `install_extensions()` to install a new exnsion – this
  will also automatically load the extension

- If the extension is already install you can use xx

``` r
list_extensions(con)
```

> [!NOTE]
>
> ### how to create a motherduck account and access token?
>
> 1.  go to [motherduck](https://motherduck.com/) and create an account,
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
>
> ![](access_token_md.png)

[^1]: recommend you use `MOTHERDUCK_TOKEN` as your variable name
