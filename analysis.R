library(tidyverse)
library(S7)

devtools::document()
devtools::load_all()

md::install_extensions(con,"arrow",silent_msg = FALSE)

con <- connect_to_motherduck("MOTHERDUCK_TOKEN")

cd(con,"tsa")
pwd(con)

validate_extension_install_status(con,"motherduck",return_type = "msg")
## need to add md validation to show duckdb_database or need error messages if no databases or loaded

tsa_dbi <- tbl(con,"tsa_passenger_volumes")


validate_extension_load_status(con,extension_names = "motherduck")

validate_extension_install_status(con,c("excel","arrow"))

validate_connection_status(con)

ls(con)


cd(con,"dfd")


install_md_extensions(con,c("vss"),silent_msg = FALSE)

list_md_extensions(con) |> print(n=100)

show_databases(con_md)

duckdb::duckdb_register(con_md,name="mtcars",mtcars)

dplyr::tbl(con,"mtcars")

duckdb::dbWriteTable(con,"mtcars_write",mtcars)

validate_md_connection_status(con)

DBI::dbListTables(con)

DBI::dbGetQuery(con, "SELECT schema_name FROM information_schema.schemata;")


DBI::dbSendQuery(con,"SHOW ALL DATABASES;")
DBI::dbExecute(con,"create or replace schema hello;")
DBI::dbExecute(
    con
    ,"CREATE DATABASE IF NOT EXISTS test
    USE test
    CREATE SCHEMA IF NOT EXISTS main
    USE main
    create or replace view mtcars as values(1);"

    )
DBI::dbExecute(con, "CREATE SCHEMA IF NOT EXISTS main;")
DBI::dbExecute(con, "SET schema 'main';")
DBI::dbExecute(con, "CREATE OR REPLACE VIEW mtcars AS SELECT 1 AS dummy;")


# check datbase
DBI::dbGetQuery(.con, "SELECT * FROM md_list_database_shares();") |>
    as_tibble()
.con <- con_md
# check connection

DBI::dbGetQuery(.con, "PRAGMA show_databases;") |>
    as_tibble()

DBI::dbGetQuery(.con, "SELECT * FROM md_active_server_connections();") |>
    as_tibble()


DBI::dbGetQuery(.con, "SELECT md_current_client_connection_id();") |>
        as_tibble()

DBI::dbGetQuery(.con, "SELECT md_current_client_duckdb_id();") |>
        as_tibble()

DBI::dbGetQuery(.con, "PRAGMA user_agent;")

DBI::dbGetQuery(.con, "SELECT current_user();")

DBI::dbGetQuery(con, "SELECT version();")

DBI::dbGetQuery(.con, "SELECT current_role();")
pwd(.con)


DBI::dbGetQuery(.con, "Select * from MD_WELCOME_MESSAGES();")
DBI::dbGetQuery(.con, "select * from duckdb_settings();")

 con <- DBI::dbConnect(duckdb::duckdb())

 DBI::dbGetQuery(.con, "SELECT ('hello world').replace(' ', '_') as test;")

DBI::dbExecute(con,"USE TSA")
DBI::dbGetQuery(con,"SELECT current_schema();")
DBI::dbGetQuery(con,"SELECT current_database();")
DBI::dbGetQuery(con,"SELECT current_table();")


DBI::dbGetQuery(.con,"SELECT * from duckdb_settings();") |> as_tibble() |> view()


read_parquet(.con,"/home/hagan/Downloads/titanic.parquet")

lsd(.con)
tbl(.con,sql("select * from my_parquet_view"))


map_db <- function(con, input_vector, lambda_expr) {
    # Convert R vector to DuckDB list string: [1, 2, 3]
    duck_list <- paste0("[", paste(input_vector, collapse = ", "), "]")

    # Build the SQL query
    query <- paste0(
        "SELECT list_transform(", duck_list, ", ", lambda_expr, ") AS result;"
    )

    # Run the query and return the result
    DBI::dbGetQuery(con, query)$result[[1]]
}

map_db(con_md, c(2,4,50,10),"x -> x + x")

#
# map(1:100,\(x) min(x))
#
# out <- rlang::fn_body(\(x,y) x+1*y)
#
# out[[2]]
