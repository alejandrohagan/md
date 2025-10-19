
#' @title Drop and Recreate a Schema in a MotherDuck / DuckDB Database
#' @name delete_and_create_schema
#'
#' @description
#' Drops an existing schema (if it exists) in the specified database and then
#' creates a new empty schema.
#' If the connection is to a MotherDuck instance, the function switches to the
#' given database first, then drops and recreates the schema.
#' Displays helpful CLI output about the current connection, user, and database.
#'
#' @details
#' - Executes `DROP SCHEMA IF EXISTS ... CASCADE` to remove an existing schema
#'   and all contained objects.
#' - Executes `CREATE SCHEMA IF NOT EXISTS` to recreate it.
#' - If connected to MotherDuck (detected by
#'   `validate_md_connection_status()`), performs a `USE <database>` first.
#' - Prints a summary of the current connection and schema creation status
#'   using internal CLI helpers.
#'
#' @param .con A DuckDB connection object used to execute SQL queries.
#' @param database_name The name of the database where the schema should be
#'   dropped and recreated.
#' @param schema_name The name of the schema to drop and recreate.
#' @export
#' @return
#' Invisibly returns `NULL`.
#' Side effect: drops and recreates the schema and prints CLI status messages.
#'
#' @seealso [DBI::dbExecute()]
#'
delete_and_create_schema <- function(.con,database_name,schema_name){

    # Validate write_type

    # validate_con(.con)

    md_con_indicator <- validate_md_connection_status(.con,return_type="arg")

    if(md_con_indicator){
        # Create and connect to the database
        DBI::dbExecute(.con, glue::glue_sql("USE {`database_name`};", .con = .con))
    }

    # Create schema
    DBI::dbExecute(.con, glue::glue_sql("DROP SCHEMA IF EXISTS {`schema_name`} CASCADE;", .con = .con))
    DBI::dbExecute(.con, glue::glue_sql("CREATE SCHEMA IF NOT EXISTS {`schema_name`};", .con = .con))
    DBI::dbExecute(.con, glue::glue_sql("USE {`schema_name`};", .con = .con))

    # print report
    cli::cli_h1("Status:")
    md:::validate_md_connection_status(.con)
    md:::cli_show_user(.con)
    md:::cli_show_db(.con)
    md:::cli_create_obj(.con,database_name = database_name,schema_name = schema_name)

}



#' @title Create a Schema in a Database if It Does Not Exist
#' @name create_schema
#'
#' @description
#' Ensures that a specified schema exists in the given database.
#' If the connection is to a MotherDuck instance, the function switches
#' to the specified database before creating the schema.
#' It also prints helpful connection and environment information via
#' CLI messages for transparency.
#'
#' @details
#' - Uses `DBI::dbExecute()` with `CREATE SCHEMA IF NOT EXISTS` to create
#'   the schema only when needed.
#' - If connected to MotherDuck (determined by
#'   `validate_md_connection_status()`), executes `USE <database>` before
#'   creating the schema.
#' - Displays connection/user/database information via internal CLI helpers.
#'
#' @param .con A valid `DBI` connection (e.g., DuckDB or MotherDuck).
#' @param database_name Name of the database to create/use.
#' @param schema_name Name of the schema to create if it does not exist.
#' @export
#' @return
#' Invisibly returns `NULL`.
#' Side effect: creates the schema if necessary and prints CLI messages.
#'
#' @seealso [DBI::dbExecute()]
create_schema <- function(.con,database_name,schema_name){

    # Validate write_type

    # validate_con(.con)

    md_con_indicator <- validate_md_connection_status(.con,return_type="arg")

    if(md_con_indicator){
        # Create and connect to the database

      suppressMessages(
        DBI::dbExecute(.con, glue::glue_sql("USE {`database_name`};", .con = .con))
      )
    }


    cli::cli_h1("Status:")
    md:::validate_md_connection_status(.con)
    md:::cli_show_user(.con)
    md:::cli_show_db(.con)
    md:::cli_create_obj(.con,database_name = database_name,schema_name = schema_name)

    suppressMessages(
    # Create schema
    DBI::dbExecute(.con, glue::glue_sql("CREATE SCHEMA IF NOT EXISTS {`schema_name`};", .con = .con))
    )
}

#' @title Overwrite or Append a Local Tibble to a Database Table
#' @name create_table_tbl
#'
#' @description
#' Takes an in-memory tibble (or data frame) and writes it to a database table
#' using a `DBI` connection. The function supports both **overwrite** and
#' **append** modes, automatically creates the target database and schema if
#' they do not exist, and adds audit fields (`upload_date`, `upload_time`) to
#' the written table.
#'
#' @details
#' - If the connection is a MotherDuck connection (detected by
#'   `validate_md_connection_status()`), the function ensures the
#'   database is created and switches to it before creating the schema.
#' - Two audit columns are added to the data before writing:
#'   `upload_date` (date of run) and `upload_time` (time and timezone of run).
#' - Uses `DBI::Id()` to explicitly target the database/schema/table.
#' - `write_type = "overwrite"` will drop and recreate the table.
#' - `write_type = "append"` will insert rows into an existing table.
#'
#' @param .data A tibble or data frame to be written to the database.
#' @param .con A valid `DBI` connection (e.g., DuckDB or MotherDuck).
#' @param database_name Name of the database to create/use. If missing,
#'   the current database of the connection will be used.
#' @param schema_name Name of the schema to create/use. If missing,
#'   the current schema of the connection will be used.
#' @param table_name Name of the table to create or append to.
#' @param write_type Write strategy: either `"overwrite"` (drop/create)
#'   or `"append"` (insert rows). Defaults to `"overwrite"`.
#'
#' @return
#' Invisibly returns `NULL`.
#' Side effect: writes the tibble to the specified database table.
#'
#' @seealso [DBI::dbWriteTable()], [DBI::Id()]
create_table_tbl <- function(.data,.con,database_name,schema_name,table_name,write_type="overwrite"){

    # Validate write_type
    write_type <- rlang::arg_match(write_type,values = c("overwrite","append"))

    # Validate the connection (assume this is a custom function)

    md_con_indicator <- validate_md_connection_status(.con,return_type="arg")

    if(rlang::is_missing(database_name)){
      database_name <- pwd(.con) |> dplyr::pull(current_database)
    }


    if(rlang::is_missing(schema_name)){
      schema_name <- pwd(.con) |> dplyr::pull(current_schema)
    }

    database_name <- DBI::dbQuoteIdentifier(conn = .con,x = database_name)
#
    if(md_con_indicator){

#         # Create and connect to the database
        DBI::dbExecute(.con, glue::glue_sql("CREATE DATABASE IF NOT EXISTS {database_name};", .con = .con))
        Sys.sleep(1)
        DBI::dbExecute(.con, glue::glue_sql("USE {database_name};", .con = .con))

    }

    # # Create schema
    Sys.sleep(1)

    schema_name <- DBI::dbQuoteIdentifier(conn = .con,x=schema_name)

    #
    DBI::dbExecute(.con, glue::glue_sql("CREATE SCHEMA IF NOT EXISTS {schema_name}; USE {schema_name};", .con = .con))
    #
    Sys.sleep(1)
    #
    # DBI::dbExecute(.con, glue::glue_sql("USE {schema_name};", .con = .con))


    # Add audit fields
    out <- .data |>
        dplyr::mutate(
            upload_date = Sys.Date(),
            upload_time = format(Sys.time(), "%H:%M:%S  %Z",tz = Sys.timezone())
        )



    # Use DBI::Id to ensure schema is used explicitly

    table_id <- DBI::Id(table = table_name)

    # Write table
    if (write_type == "overwrite") {

        DBI::dbWriteTable(.con, name = table_id, value = out, overwrite = TRUE)

    } else if (write_type == "append") {

        DBI::dbWriteTable(.con, name = table_id, value = out, append = TRUE)

    }



}

#' @title Create a Database Table from a DBI Object
#' @name create_table_dbi
#'
#' @description
#' Creates a physical table in a database from a `dbplyr`/`DBI`-backed
#' lazy table or query. The function supports both **overwrite** and
#' **append** write strategies, automatically creates the target
#' database and schema if they do not exist, and adds audit fields
#' (`upload_date`, `upload_time`) to the written table.
#'
#' @details
#' - If the connection is a MotherDuck connection (detected by
#'   `validate_md_connection_status()`), the function ensures the
#'   database is created and switches to it before creating the schema.
#' - Adds two audit columns: `upload_date` (date of run) and
#'   `upload_time` (time and timezone of run).
#' - Uses `DBI::Id()` to explicitly target the database/schema/table.
#' - `write_type = "overwrite"` will drop and recreate the table.
#' - `write_type = "append"` will insert rows into an existing table.
#'
#' @param .data A `dbplyr` lazy table or other DBI-compatible object to be
#'   materialized as a physical table.
#' @param .con A valid `DBI` connection.
#' @param database_name Name of the database to create/use. If missing,
#'   the current database of the connection will be used.
#' @param schema_name Name of the schema to create/use. If missing,
#'   the current schema of the connection will be used.
#' @param table_name Name of the table to create or append to.
#' @param write_type Write strategy: either `"overwrite"` (drop/create)
#'   or `"append"` (insert rows). Defaults to `"overwrite"`.
#'
#' @return
#' A user-friendly message is returned invisibly (invisible `NULL`),
#' indicating whether the table was created or appended to.
#' Side effect: writes data to the database.
#'
#' @seealso [DBI::dbExecute()], [dbplyr::remote_query()]
create_table_dbi <- function(.data,.con,database_name,schema_name,table_name,write_type="overwrite"){


  # Validate write_type
  write_type <- rlang::arg_match(write_type,values = c("overwrite","append"))

  md_con_indicator <- validate_md_connection_status(.con,return_type="arg")

  if(!rlang::is_missing(database_name)){
    database_name <- pwd(.con) |> pull(current_database)
  }

  if(!rlang::is_missing(schema_name)){
    schema_name <- pwd(.con) |> pull(current_schema)
  }

  if(md_con_indicator){
    # Create and connect to the database
    DBI::dbExecute(.con, glue::glue_sql("CREATE DATABASE IF NOT EXISTS {`database_name`};", .con = .con))
    DBI::dbExecute(.con, glue::glue_sql("USE {`database_name`};", .con = .con))
  }

  Sys.sleep(1)
  # Create schema
  DBI::dbExecute(.con, glue::glue_sql("CREATE SCHEMA IF NOT EXISTS {`schema_name`};", .con = .con))


  DBI::dbExecute(.con, glue::glue_sql("USE {`schema_name`};", .con = .con))


  date_vec <- Sys.Date()
  time_vec <- format(Sys.time(), "%H:%M:%S  %Z",tz = Sys.timezone())

  # Add audit fields
  query_plan <- .data |>
    dplyr::mutate(
      upload_date = date_vec,
      upload_time = time_vec
    ) |>
    dbplyr::remote_query()

  # Use DBI::Id to ensure schema is used explicitly

  if(!md_con_indicator){

    database_name <- pwd(.con)$current_database
  }

  # table_id <- DBI::Id(database=database_name,schema = schema_name, table = table_name)
  # table_id <- DBI::Id(table = table_name)

  table_name_id <- DBI::dbQuoteIdentifier(.con,table_name)
  # Write table
  if (write_type == "overwrite") {

    dbExecute(.con, glue::glue_sql("DROP TABLE IF EXISTS {table_name_id};",.con = .con))

    Sys.sleep(1)

    dbExecute(.con,glue::glue_sql("CREATE TABLE IF NOT EXISTS {table_name_id} AS ",query_plan,.con = .con))

  } else if (write_type == "append") {

    dbExecute(.con,glue::glue_sql("INSERT INTO {table_name_id} ",query_plan,.con = .con))

  }

}



#' @title Create or Append a Table from a Tibble or DBI-Backed Table
#' @name create_table
#'
#' @description
#' A thin wrapper that routes to either [`create_table_dbi()`] (for
#' `dbplyr`-backed lazy tables, class `"tbl_dbi"`) or
#' [`create_table_tbl()`] (for in-memory tibbles / data frames), creating
#' a physical table in the target database/schema. Supports **overwrite**
#' and **append** write strategies and defers all heavy lifting to the
#' specific implementation.
#'
#' @details
#' - If `.data` is a `dbplyr` lazy table (class `"tbl_dbi"`), the call is
#'   delegated to [`create_table_dbi()`].
#' - If `.data` is an in-memory tibble/data frame (class including
#'   `"data.frame"`), the call is delegated to [`create_table_tbl()`].
#' - Any other input classes trigger an error.
#'
#' @param .data Tibble/data frame (in-memory) or a `dbplyr`/DBI-backed lazy
#'   table (class `"tbl_dbi"`).
#' @param .con A DuckDB or MotherDuck `DBI` connection.
#' @param database_name Database name to create/use.
#' @param schema_name Schema name to create/use.
#' @param table_name Target table name to create or append to.
#' @param write_type Write strategy: `"overwrite"` (drop/create) or
#'   `"append"` (insert rows). Defaults to `"overwrite"`.
#' @export
#' @return
#' Invisibly returns `NULL`. Side effect: writes a table to the database by
#' delegating to the appropriate helper.
#'
#' @seealso [create_table_dbi()], [create_table_tbl()], [DBI::dbWriteTable()],
#'   [dbplyr::remote_query()]
create_table <- function(.data,.con,database_name,schema_name,table_name,write_type="overwrite"){


  data_class <- class(.data)

  if(!any(data_class %in% c("tbl_dbi","data.frame"))){

    cli::cli_abort("data must be either {.var tbl_dbi} or {.var data.frame} not {data_class}")

  }

  if(any(data_class %in% c("tbl_dbi"))){

    suppressMessages(
    create_table_dbi(.data=.data,.con=.con,database_name=database_name,schema_name=schema_name,table_name=table_name,write_type=write_type)
    )
  }

  if(any(data_class %in% c("data.frame"))){
    suppressMessages(
    create_table_tbl(.data=.data,.con=.con,database_name=database_name,schema_name=schema_name,table_name=table_name,write_type=write_type)
    )
  }


  cli::cli_h1("Status:")
  md:::validate_md_connection_status(.con)
  md:::cli_show_user(.con)
  md:::cli_show_db(.con)
  md:::cli_create_obj(.con,database_name = database_name,schema_name = schema_name,write_type = write_type)




}


#' @title Create (If Not Exists) and Switch to a Database
#' @name create_if_not_exists_database
#'
#' @description
#' Ensures a database exists and sets it as the active database.
#' If connected to MotherDuck, the function will run
#' `CREATE DATABASE IF NOT EXISTS` followed by `USE <database>`.
#' Prints CLI status information about the current user and database.
#'
#' @details
#' - Connection type is checked via `validate_md_connection_status()`
#'   (with `return_type = "arg"`).
#' - On MotherDuck, executes:
#'   - `CREATE DATABASE IF NOT EXISTS <database>`
#'   - `USE <database>`
#' - Displays status and environment info with CLI messages.
#'
#' @param .con A valid `DBI` connection (DuckDB / MotherDuck).
#' @param database_name Name of the database to create/ensure and switch to.
#' @export
#' @return
#' Invisibly returns `NULL`.
#' Side effect: may create a database and switches to it; prints CLI status.
#'
#' @seealso [DBI::dbExecute()]
#'
#' @examples
#' \dontrun{
#' con <- DBI::dbConnect(duckdb::duckdb())
#' create_if_not_exists_database(con, "analytics")
#' }
#'
#' @export
create_if_not_exists_database <- function(.con,database_name){

  # Validate write_type

  # Validate the connection (assume this is a custom function)

  md_con_indicator <- validate_md_connection_status(.con,return_type="arg")

  if(md_con_indicator){
    # Create and connect to the database
    DBI::dbExecute(.con, glue::glue_sql("CREATE DATABASE IF NOT EXISTS {`database_name`};", .con = .con))

    DBI::dbExecute(.con, glue::glue_sql("USE {`database_name`};", .con = .con))

  }

  cli::cli_h1("Status:")
  md:::validate_md_connection_status(.con)
  md:::cli_show_user(.con)
  md:::cli_show_db(.con)
  md:::cli_create_obj(.con,database_name = database_name,schema_name = schema_name,write_type = write_type)


}

#' @title Move Tables from One Schema to Another
#' @name alter_table_schema
#'
#' @description
#' Moves one or more tables from an existing schema to a new (target) schema
#' using `ALTER TABLE ... SET SCHEMA`. If the target schema does not exist,
#' it is created first.
#'
#' @details
#' - Ensures `new_schema` exists (`CREATE SCHEMA IF NOT EXISTS`).
#' - For each table in `table_names`, runs:
#'   `ALTER TABLE old_schema.table SET SCHEMA new_schema`.
#' - Table and schema identifiers are safely quoted with `glue::glue_sql()`.
#'
#' @param .con A `DBI` connection (DuckDB / MotherDuck).
#' @param old_schema Previous schema name (where the tables currently live).
#' @param new_schema Target schema name (where the tables will be moved).
#' @param table_names Character vector of table names to move.
#' @export
#' @return
#' Invisibly returns a character vector of fully-qualified table names moved.
#' Side effects: creates `new_schema` if needed and alters table schemas.
#'
#' @seealso [DBI::dbExecute()], [DBI::dbGetQuery()]
#'
alter_table_schema <- function(.con, from_table_names, new_schema) {

    schema_exists <- DBI::dbGetQuery(.con, glue::glue("SELECT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = '{new_schema}');"))

    # If the schema doesn't exist, create it
    if (!schema_exists$exists) {
        DBI::dbExecute(.con, glue::glue("CREATE SCHEMA {`new_schema`};"))
        cli::cli_alert_info("Schema {.val {new_schema}} did not exist. It has been created.")
    }


    # Build SQL query to move the table
    sql <- glue::glue("ALTER TABLE {`old_schema`}.{`table_name`} SET SCHEMA {`new_schema`};")

    # Execute the query to move the table
    DBI::dbExecute(.con, sql)

    cli::cli_h1("Status:")
    md:::validate_md_connection_status(.con)
    md:::cli_show_user(.con)
    md:::cli_show_db(.con)
    cli::cli_h2("Action Report:")
    cli::cli_li("Change {from_table_names} schema to {new_schema}")

}



#' @title Drop a Schema from a Database
#' @name delete_schema
#'
#' @description
#' Drops a schema from a specified database.
#' Optionally cascades the deletion to all objects within the schema.
#' Prints helpful CLI information about the current connection and action.
#'
#' @details
#' - Runs `DROP SCHEMA IF EXISTS <db>.<schema>` with optional `CASCADE`.
#' - Intended for DuckDB or MotherDuck connections.
#' - Uses CLI helpers to show current connection and report the deletion.
#'
#' @param .con A valid `DBI` connection (DuckDB / MotherDuck).
#' @param database_name Name of the database containing the schema.
#' @param schema_name Name of the schema to drop.
#' @param cascade Logical; if `TRUE` (default), use `CASCADE` to drop
#'   all dependent objects in the schema. If `FALSE`, drop only if empty.
#' @export
#' @return
#' Invisibly returns `NULL`.
#' Side effect: drops the schema (and contained objects if `cascade = TRUE`)
#' and prints CLI status.
#'
delete_schema <- function(
        .con,
        database_name,
        schema_name,
        cascade = FALSE
) {


suppressMessages(
cd(.con,database_name)
)

  table_count <-  list_all_tables(.con) |>
    filter(
      table_catalog==database_name
      ,table_schema==schema_name
    ) |>
   dplyr::collect() |>
   nrow()


  cli::cli_h1("Status:")
  md:::validate_md_connection_status(.con)
  md:::cli_show_user(.con)
  md:::cli_show_db(.con)
  cli::cli_h2("Action Report:")
  cli::cli_ul("Deleted {.val {schema_name}} schema and {.val {table_count}} tables")


    # Drop the schema
    drop_schema_sql <- glue::glue_sql(
        "DROP SCHEMA IF EXISTS {`database_name`}.{`schema_name`} {DBI::SQL(if (cascade) 'CASCADE' else '')};",
        .con = .con
    )

    DBI::dbExecute(.con, drop_schema_sql)

    cli::cli_h1("Status:")
    md:::validate_md_connection_status(.con)
    md:::cli_show_user(.con)
    md:::cli_show_db(.con)
    cli::cli_h2("Action Report:")
    cli::cli_ul("Deleted {.val {schema_name}} schema and {.val {table_count}} tables")


}

#' @title Copy Tables to a New Database/Schema
#' @name copy_tables_to_new_location
#'
#' @description
#' Copies one or more tables to a new location (database/schema) by creating
#' new tables via `CREATE TABLE ... AS SELECT * FROM ...`.
#' If connected to MotherDuck, the target database is created if missing, and
#' the target schema is created if missing on any connection.
#'
#' @details
#' - Input `from_table_names` must contain columns:
#'   `database_name`, `schema_name`, and `table_name`.
#' - For each source table, the function issues:
#'   `CREATE TABLE <to_db>.<to_schema>.<table> AS SELECT * FROM <src_db>.<src_schema>.<table>`.
#' - On local DuckDB (non-MotherDuck), the target database name is ignored and
#'   defaults to the current database of the connection.
#'
#' @param .con A `DBI` connection (DuckDB / MotherDuck).
#' @param from_table_names A tibble/data frame listing source tables, with
#'   columns `database_name`, `schema_name`, and `table_name`.
#' @param to_database_name Target database name.
#' @param to_schema_name Target schema name.
#'
#' @return
#' Invisibly returns a character vector of fully-qualified destination table
#' names that were created. Side effect: creates target DB/schema if needed and
#' writes new tables.
#'
#' @seealso [DBI::dbExecute()], [DBI::Id()]
#'
#' @export
copy_tables_to_new_location <- function(.con, from_table_names, to_database_name, to_schema_name) {

  md_con_indicator <- validate_md_connection_status(.con, return_type = "arg")

  if (md_con_indicator) {
    # Ensure target database exists (MotherDuck)
    DBI::dbExecute(.con, glue::glue_sql(
      "CREATE DATABASE IF NOT EXISTS {`to_database_name`};", .con = .con
    ))
  }

  # Ensure target schema exists
  DBI::dbExecute(.con, glue::glue_sql(
    "CREATE SCHEMA IF NOT EXISTS {`to_schema_name`};", .con = .con
  ))

  # For local DuckDB, use the current database
  if (!md_con_indicator) {
    to_database_name <- pwd(.con) |> pull(current_database)
  }



  # Validate input
  assertthat::assert_that(any(class(from_table_names) %in% c("data.frame","tbl_dbi")))

  # convert to tibble because downstream depencencies on tibbles
  from_table_names <- from_table_names |> dplyr::collect()

  required_cols <- c("table_catalog", "table_schema", "table_name")

  missing_cols  <- setdiff(required_cols, colnames(from_table_names))

  if (length(missing_cols)) {

    cli::cli_abort("`from_table_names` is missing required columns: {missing_cols}")
  }

  table_names_vec <- unique(from_table_names |> dplyr::pull(table_name))

  # Build destination Ids
  to_ids <- purrr::map(
    .x = table_names_vec,
    .f = \(tbl) DBI::Id(database = to_database_name, schema = to_schema_name, table = tbl)
  )

  # Build source Ids (expects your helper to return a list of DBI::Id or SQL identifiers)
  from_ids <- from_table_names |>
    convert_table_to_sql_id() # must align element order with table_names_vec

  # Execute copy: CREATE TABLE dest AS SELECT * FROM src
  purrr::walk2(
    .x = to_ids,
    .y = from_ids,
    .f = \(to_id, from_id) {
      DBI::dbExecute(
        .con,
        glue::glue_sql("CREATE TABLE {`to_id`} AS SELECT * FROM {`from_id`};", .con = .con)
      )
    }
  )

  # Status / report
  cli::cli_h1("Status:")
  try(md:::validate_md_connection_status(.con), silent = TRUE)
  try(md:::cli_show_user(.con), silent = TRUE)
  try(md:::cli_show_db(.con), silent = TRUE)


  cli::cli_h2("Action Report:")
  cli::cli_ul("{cli::symbol$tick} Copied {.val {length(table_names_vec)}} tables to {.val {to_database_name}} database and {.val {to_schema_name}} schema")
}


#' @title Upload a Local Database to MotherDuck
#' @name upload_database_to_md
#'
#' @description
#' Creates a new database on MotherDuck (if it does not exist) and copies
#' all objects from an existing local database into it using the
#' `COPY FROM DATABASE` command.
#'
#' @details
#' - Runs `CREATE DATABASE <to_db_name>` if the target database does not exist.
#' - Then runs `COPY FROM DATABASE <from_db_name> TO <to_db_name>` to copy all
#'   objects (tables, views, etc.) from the local database.
#' - Prints a CLI status report (connection, user, current DB) after completion.
#'
#' @param .con A valid MotherDuck `DBI` connection.
#' @param from_db_name The local database name to copy from.
#' @param to_db_name The target MotherDuck database to create/overwrite.
#'
#' @return
#' Invisibly returns `NULL`.
#' Side effect: creates the target database and copies all objects; prints a CLI
#' action report.
#'
#' @seealso [DBI::dbExecute()]
#'
#' @examples
#' \dontrun{
#' con <- DBI::dbConnect(duckdb::duckdb())
#' upload_database_to_md(con, from_db_name = "local_db", to_db_name = "analytics")
#' }
#'
#' @export
upload_database_to_md <- function(.con, from_db_name, to_db_name) {

  # CREATE DATABASE and COPY FROM DATABASE
  DBI::dbExecute(
    .con,
    dplyr::sql(
      paste0(
        "CREATE DATABASE IF NOT EXISTS ", to_db_name, "; ",
        "COPY FROM DATABASE ", from_db_name, " TO ", to_db_name, ";"
      )
    )
  )

  cli::cli_h1("Status:")
  try(md:::validate_md_connection_status(.con), silent = TRUE)
  try(md:::cli_show_user(.con), silent = TRUE)
  try(md:::cli_show_db(.con), silent = TRUE)

  cli::cli_h2("Action Report:")
  cli::cli_li("Copied local database {.val {from_db_name}} to MotherDuck as {.val {to_db_name}}")

}


#' @title List Database Functions (DuckDB/MotherDuck)
#' @name list_fns
#' @aliases list_db_fns
#'
#' @description
#' Returns a lazy table listing available SQL functions from the current
#' DuckDB/MotherDuck connection using `duckdb_functions()`.
#'
#' @details
#' This wrapper validates the connection and then queries
#' `duckdb_functions()` to enumerate function metadata. The result is a
#' `dbplyr` lazy tibble (`tbl_dbi`); call `collect()` to materialize it in R.
#'
#' @param .con A valid `DBI` connection (DuckDB or MotherDuck).
#'
#' @return
#' A `dbplyr` lazy tibble (`tbl_dbi`) with function metadata (e.g.,
#' `function_name`, `schema`, `is_aggregate`, `is_alias`, etc.).
#'
#' @seealso [DBI::dbConnect()], [dbplyr::tbl()]
#'
#' @export
list_fns <- function(.con){

  validate_con(.con)

  out <- dplyr::tbl(
    .con,
    "
    SELECT *
    FROM duckdb_functions()
    ORDER BY function_name
    "
  )

  return(out)
}


#' @title List Databases Visible to the Connection
#' @name list_databases
#'
#' @description
#' Returns a lazy tibble of distinct database (catalog) names visible through
#' the current connection, using `information_schema.tables`.
#'
#' @details
#' The result is a `dbplyr` lazy table (`tbl_dbi`). Use `collect()` to bring
#' results into R as a local tibble.
#'
#' @param .con A valid `DBI` connection (DuckDB / MotherDuck).
#'
#' @return
#' A `dbplyr` lazy tibble with one column: `table_catalog`.
#'
#' @seealso [dbplyr::tbl()], [DBI::dbConnect()]
#' @export
list_databases <- function(.con){

  validate_con(.con)

  database_dbi <- dplyr::tbl(
    .con,
    dplyr::sql("
      SELECT DISTINCT database_name
      FROM duckdb_databases()
    ")
  )

  return(database_dbi)

}




#' @title List Schemas in the Current Database
#' @name list_schemas
#'
#' @description
#' Returns a lazy tibble of all schemas in the **current database** of the
#' connection. Queries `information_schema.schemata` and filters to the
#' current database (`catalog_name = current_database()`).
#'
#' @details
#' - This function assumes the connection is valid (checked with
#'   `validate_con()`).
#' - Returns a `dbplyr` lazy table; use `collect()` to bring the result into R.
#'
#' @param .con A valid `DBI` connection (DuckDB / MotherDuck).
#'
#' @return
#' A `dbplyr` lazy tibble with columns:
#' * `catalog_name` — the current database name.
#' * `schema_name` — each schema within that database.
#'
#' @seealso [dbplyr::tbl()], [DBI::dbConnect()]
#' @export
list_schemas <- function(.con) {

  validate_con(.con)

  schema_dbi <- dplyr::tbl(
    .con,
    dplyr::sql("
      SELECT DISTINCT
        catalog_name,
        schema_name
      FROM information_schema.schemata
      WHERE catalog_name = current_database()
    ")
  )

  return(schema_dbi)

}



#' @title List Tables in the Current Database and Schema
#' @name list_current_tables
#'
#' @description
#' Returns a lazy tibble of all tables that exist in the **current database**
#' and **current schema** of the active connection.
#' Queries the standard `information_schema.tables` view and filters to
#' `current_database()` and `current_schema()`.
#'
#' @details
#' - This function validates that the connection is valid with `validate_con()`.
#' - Result is a `dbplyr` lazy table (`tbl_dbi`); call `collect()` to bring it
#'   into R.
#'
#' @param .con A valid `DBI` connection (DuckDB / MotherDuck).
#'
#' @return
#' A `dbplyr` lazy tibble with columns:
#' * `table_catalog` — the current database.
#' * `table_schema`  — the current schema.
#' * `table_name`    — each table name.
#'
#' @seealso [dbplyr::tbl()], [DBI::dbConnect()]
#'
#' @export
list_current_tables <- function(.con) {

  validate_con(.con)

  tables_dbi <- dplyr::tbl(
    .con,
    dplyr::sql("
      SELECT DISTINCT
        table_catalog,
        table_schema,
        table_name
      FROM information_schema.tables
      WHERE table_catalog = current_database()
        AND table_schema  = current_schema()
    ")
  )

  return(tables_dbi)
}



#' @title List All Tables Visible to the Connection
#' @name list_all_tables
#'
#' @description
#' Returns a lazy tibble of all tables visible to the current connection by
#' querying `information_schema.tables` (across all catalogs/databases and
#' schemas).
#'
#' @details
#' The result is a `dbplyr` lazy table (`tbl_dbi`). Use `collect()` to bring
#' results into R as a local tibble.
#'
#' @param .con A valid `DBI` connection (DuckDB / MotherDuck).
#'
#' @return
#' A `dbplyr` lazy tibble with columns:
#' * `table_catalog` — database/catalog name
#' * `table_schema`  — schema name
#' * `table_name`    — table name
#'
#' @seealso [dbplyr::tbl()], [DBI::dbConnect()]
#' @export
list_all_tables <- function(.con) {

  validate_con(.con)

  tables_dbi <- dplyr::tbl(
    .con,
    dplyr::sql("
      SELECT DISTINCT
        table_catalog,
        table_schema,
        table_name
      FROM information_schema.tables
    ")
  )

  return(tables_dbi)
}

#' @title Drop a Database
#' @name delete_database
#'
#' @description
#' Drops a database from the current DuckDB or MotherDuck connection if it exists.
#' Prints a CLI status report after performing the operation.
#'
#' @details
#' - Executes `DROP DATABASE IF EXISTS <database_name>` to remove the database.
#' - Intended for DuckDB or MotherDuck connections.
#' - Prints user, database and action details using CLI helper functions.
#'
#' @param .con A valid `DBI` connection (DuckDB / MotherDuck).
#' @param database_name Name of the database to drop.
#'
#' @return
#' Invisibly returns `NULL`.
#' Side effect: drops the database and prints CLI status messages.
#'
#' @seealso [DBI::dbExecute()]
#'
#' @export
delete_database <- function(.con,database_name) {


  # Status output
  cli::cli_h1("Status:")
  md:::validate_md_connection_status(.con)
  md:::cli_show_user(.con)
  md:::cli_show_db(.con)
  md:::cli_delete_obj(.con = .con, database_name = database_name)


  if(DBI::dbExecute(.con, glue::glue_sql("DROP DATABASE IF EXISTS {`database_name`} CASCADE;",.con = .con))!=0){

    cli::cli_h3("Action Report:")
    cli::cli_ul("{cli::symbol$cross} Failed to delete {`database_name`}")

  }


}



#' @title Retrieve Metadata for One or More Tables
#' @name return_table_attributes
#'
#' @description
#' Returns catalog (database), schema, and table information for one or more
#' tables visible to the connection by querying `information_schema.tables`.
#'
#' @details
#' - Accepts one or more table names and returns their associated
#'   `table_catalog`, `table_schema`, and `table_name` if found.
#' - Uses `information_schema.tables` to look up metadata.
#'
#' @param .con A valid `DBI` connection (DuckDB / MotherDuck).
#' @param table_name Character vector of one or more table names to look up.
#'
#' @return
#' A local tibble (data frame) with columns:
#' * `table_catalog` — database/catalog name
#' * `table_schema`  — schema name
#' * `table_name`    — the matching table names
#'
#' @seealso [DBI::dbGetQuery()], [information_schema.tables]
#' @export
return_table_attributes <- function(.con, table_name) {

  out <- DBI::dbGetQuery(
    .con,
    glue::glue_sql(
      "
      SELECT
        table_catalog,
        table_schema,
        table_name
      FROM information_schema.tables
      WHERE table_name IN ({table_name*})
      ",
      .con = .con
    )
  )

  return(out)
}



#' @title Convert Table Metadata to SQL Identifiers
#' @name convert_table_to_sql_id
#'
#' @description
#' Converts a tibble of table metadata (`table_catalog`, `table_schema`,
#' `table_name`) into a list of `DBI::Id` SQL identifiers.
#' Useful for safely quoting fully qualified table references in
#' `DBI`/`dbplyr` workflows.
#'
#' @param x A tibble or data frame containing the columns:
#'   * `table_catalog` — database/catalog name
#'   * `table_schema` — schema name
#'   * `table_name` — table name
#'
#' @return
#' A list of `DBI::Id` objects, each representing a fully-qualified table.
#'
#' @seealso [DBI::Id()]
#'
#'
convert_table_to_sql_id <- function(x) {

  stopifnot(all(c("table_catalog", "table_schema", "table_name") %in% colnames(x)))

  out <- x |>
    dplyr::rowwise() |>
    dplyr::transmute(
      table_id = list(DBI::Id(
        catalog = table_catalog,
        schema  = table_schema,
        table   = table_name
      ))
    ) |>
    dplyr::ungroup() |>
    purrr::pluck(1)

  out
}

#' @title Drop a Table
#' @name delete_table
#'
#' @description
#' Drops a table from the specified database and schema if it exists.
#' Uses `DROP TABLE IF EXISTS` for safety and prints a CLI status report.
#'
#' @param .con A valid `DBI` connection (DuckDB / MotherDuck).
#' @param database_name Name of the database containing the table.
#' @param schema_name Name of the schema containing the table.
#' @param table_name Name of the table to drop.
#' @param cascade Logical; if `TRUE` (default), drop dependent objects as well
#'   using `CASCADE`. If `FALSE`, the drop will fail if there are dependencies.
#'
#' @return
#' Invisibly returns `NULL`.
#' Side effect: drops the table and prints CLI status messages.
#'
#' @seealso [DBI::dbExecute()], [delete_schema()], [delete_database()]
#' @export
delete_table <- function(.con, database_name, schema_name, table_name, cascade = TRUE) {

  validate_con(.con)

  drop_sql <- glue::glue_sql(
    "DROP TABLE IF EXISTS {`database_name`}.{`schema_name`}.{`table_name`} {DBI::SQL(if (cascade) 'CASCADE' else '')};",
    .con = .con
  )

  DBI::dbExecute(.con, drop_sql)

  cli::cli_h1("Status:")
  try(md:::validate_md_connection_status(.con), silent = TRUE)
  try(md:::cli_show_user(.con), silent = TRUE)
  try(md:::cli_show_db(.con), silent = TRUE)
  cli::cli_h3("Action Report:")
  cli::cli_ul("Deleted {.val {table_name}} from {.val [database_name]} in {.val {schema_name}}")

}
