
#' Overwrite or append tibble to motherduck database
#'
#' @param .con A DuckDB connection object. The database connection used to execute the SQL queries.
#' @param database_name The name of the database where the schema should be created or replaced.
#' @param schema_name The name of the schema to be created or replaced.
#' @description
#' This function drops an existing schema (if it exists) in the specified database and creates a new schema
#' in that database. It first checks if a connection to Motherduck (via DuckDB) is valid. If the connection
#' is active, it executes the necessary SQL commands to switch to the specified database and schema.
#' It also generates a success message upon successfully creating the schema.
#'
#' @returns message
#' @export
create_or_replace_schema <- function(.con,database_name,schema_name){

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



#' Overwrite or append tibble to motherduck database
#'
#' @param .con duckdb connection
#' @param database_name name of database
#' @param schema_name name of schema
#'
#' @returns nothing
#' @export
create_schema <- function(.con,database_name,schema_name){

    # Validate write_type

    # validate_con(.con)

    md_con_indicator <- validate_md_connection_status(.con,return_type="arg")

    if(md_con_indicator){
        # Create and connect to the database
        DBI::dbExecute(.con, glue::glue_sql("USE {`database_name`};", .con = .con))
    }

    # Create schema
    DBI::dbExecute(.con, glue::glue_sql("CREATE SCHEMA IF NOT EXISTS {`schema_name`};", .con = .con))
    DBI::dbExecute(.con, glue::glue_sql("USE {`schema_name`};", .con = .con))


    # Use DBI::Id to ensure schema is used explicitly

    cli::cli_h1("Status:")
    md:::validate_md_connection_status(.con)
    md:::cli_show_user(.con)
    md:::cli_show_db(.con)
    md:::cli_create_obj(.con,database_name = database_name,schema_name = schema_name)

}

#' @title Overwrite or append tibble to database
#' @name create_table
#' @param .data tibble
#' @param .con duckdb connection
#' @param database_name name of database
#' @param schema_name name of schema
#' @param table_name name of table
#' @param write_type overwrite or append
#'
#' @returns nothing
create_table_tbl <- function(.data,.con,database_name,schema_name,table_name,write_type="overwrite"){

    # Validate write_type
    write_type <- rlang::arg_match(write_type,values = c("overwrite","append"))

    # Validate the connection (assume this is a custom function)
    validate_con(.con)

    md_con_indicator <- validate_md_connection_status(.con,return_type="arg")

    if(md_con_indicator){
        # Create and connect to the database
        DBI::dbExecute(.con, glue::glue_sql("CREATE DATABASE IF NOT EXISTS {`database_name`};", .con = .con))
        DBI::dbExecute(.con, glue::glue_sql("USE {`database_name`};", .con = .con))

    }

    # Create schema
    DBI::dbExecute(.con, glue::glue_sql("CREATE SCHEMA IF NOT EXISTS {`schema_name`};", .con = .con))
    DBI::dbExecute(.con, glue::glue_sql("USE {`schema_name`};", .con = .con))

    # Add audit fields
    out <- .data |>
        dplyr::mutate(
            upload_date = Sys.Date(),
            upload_time = format(Sys.time(), "%H:%M:%S  %Z",tz = Sys.timezone())
        )

    # Use DBI::Id to ensure schema is used explicitly

    if(!md_con_indicator){

        database_name <- pwd(.con)$current_database
    }

    table_id <- DBI::Id(database=database_name,schema = schema_name, table = table_name)

    # Write table
    if (write_type == "overwrite") {

        DBI::dbWriteTable(.con, name = table_id, value = out, overwrite = TRUE)

    } else if (write_type == "append") {

        DBI::dbWriteTable(.con, name = table_id, value = out, append = TRUE)

    }


}

#' @title Create table from DBI object
#'
#' @param .data dbi object
#' @param .con connection
#' @param database_name database name
#' @param schema_name schema name
#' @param table_name table name
#' @param write_type overwrite or append
#'
#' @returns message
#'
create_table_dbi <- function(.data,.con,database_name,schema_name,table_name,write_type="overwrite"){

  # Validate write_type
  write_type <- rlang::arg_match(write_type,values = c("overwrite","append"))

  # Validate the connection (assume this is a custom function)
  validate_con(.con)

  md_con_indicator <- validate_md_connection_status(.con,return_type="arg")

  if(md_con_indicator){
    # Create and connect to the database
    DBI::dbExecute(.con, glue::glue_sql("CREATE DATABASE IF NOT EXISTS {`database_name`};", .con = .con))
    DBI::dbExecute(.con, glue::glue_sql("USE {`database_name`};", .con = .con))
  }

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

  table_id <- DBI::Id(database=database_name,schema = schema_name, table = table_name)

  table_name_id <- DBI::dbQuoteIdentifier(.con,table_name)
  # Write table
  if (write_type == "overwrite") {

    dbExecute(.con, glue::glue_sql("DROP TABLE IF EXISTS {table_name_id};",.con = .con))

    dbExecute(.con,glue::glue_sql("CREATE TABLE {table_name_id} AS ",query_plan,.con = .con))


  } else if (write_type == "append") {

    dbExecute(.con,glue::glue_sql("INSERT INTO {table_name_id} ",query_plan,.con = .con))

  }

}



#' Title
#'
#' @param .data tibble or dbi object
#' @param .con duckdb or MD connection
#' @param database_name database name
#' @param schema_name schema name
#' @param table_name table name
#' @param write_type overwrite or append
#'
#' @returns message
#' @export
#'
create_table <- function(.data,.con,database_name,schema_name,table_name,write_type="overwrite"){


  data_class <- class(.data)

  if(!any(data_class %in% c("tbl_dbi","data.frame"))){

    cli::cli_abort("data must be either {.var tbl_dbi} or {.var data.frame} not {data_class}")

  }

  if(any(data_class %in% c("tbl_dbi"))){

    create_table_dbi(.data=.data,.con=.con,database_name=database_name,schema_name=schema_name,table_name=table_name,write_type=write_type)

  }

  if(any(data_class %in% c("data.frame"))){

    create_table_tbl(.data=.data,.con=.con,database_name=database_name,schema_name=schema_name,table_name=table_name,write_type=write_type)
  }

  cli::cli_h1("Status:")
  md:::validate_md_connection_status(.con)
  md:::cli_show_user(.con)
  md:::cli_show_db(.con)
  md:::cli_create_obj(.con,database_name = database_name,schema_name = schema_name,write_type = write_type)


}



#' @title Create or replace database
#' @name create_or_replace_database
#' @param .con connection
#' @param database_name new database name
#'
#' @returns message
#' @export
create_or_replace_database <- function(.con,database_name){

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

#' Title
#'
#' @param .con  connection
#' @param old_schemapreviou shema name
#' @param new_schema  new schema name
#' @param table_name  table name
#'
#' @returns
#' @export
#'
#' @examples
alter_table_schemas <- function(.con, from_table_names, new_schema) {

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



#' Title
#'
#' @param .con connection
#' @param database_name database name
#' @param schema_name schema name
#' @param cascade
#'
#' @returns message
#' @export
#'
delete_schema <- function(
        .con,
        database_name,
        schema_name,
        cascade = TRUE
) {

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
    md:::cli_delete_obj(.con = .con,database_name = database_name,schema_name = schema_name)

}



#' @title Copy tables to new schema
#'
#' @param .con connection
#' @param from_table_names tibble of tables to be copied with `database_name`,`schema_name` and `table_name` columns
#' @param to_database_name target database name
#' @param to_schema_name   target schema_name
#'
#' @returns message
#' @export
#'
copy_tables_to_new_location <- function(.con,from_table_names,to_database_name,to_schema_name){

  md_con_indicator <- validate_md_connection_status(.con,return_type="arg")

  if(md_con_indicator){
    # Create and connect to the database
    DBI::dbExecute(.con, glue::glue_sql("CREATE DATABASE IF NOT EXISTS {`to_database_name`};", .con = .con))
    # DBI::dbExecute(.con, glue::glue_sql("USE {`to_database_name`};", .con = .con))

  }

  # Create schema
  DBI::dbExecute(.con, glue::glue_sql("CREATE SCHEMA IF NOT EXISTS {`to_schema_name`};", .con = .con))
  # DBI::dbExecute(.con, glue::glue_sql("USE {`to_schema`};", .con = .con))

  if(!md_con_indicator){

    to_database_name <- pwd(.con)$current_database

  }

  assertthat::assert_that(
    any(class(from_table_names) %in% c("data.frame"))
  )


  assertthat::assert_that(
    any(colnames(from_table_names) %in% c("table_name"))
  )

  table_names_vec <- unique(from_table_names$table_name)

  to_db <-  map(
    .x=table_names_vec
    ,.f=\(.x){

      DBI::Id(database_name=to_database_name,schema_name=to_schema_name,table_name=.x)
    }
  )

  from_db <- from_table_names |>
    convert_table_to_sql_id()

  map2(
    .x=to_db
    ,.y=from_db
    ,.f=\(.x,.y){
      DBI::dbExecute(.con,glue::glue_sql("CREATE TABLE {`.x`} AS   SELECT * FROM {`.y`};",.con=.con))
    }
  )

  cli::cli_h1("Status:")
  md:::validate_md_connection_status(.con)
  md:::cli_show_user(.con)
  md:::cli_show_db(.con)
  cli::cli_h2("Action Report:")
  cli::cli_li("Copied {from_table_names} to {database_name}")

}



#' @title Upload a local database to motherduck
#' @name upload_database_to_md
#'
#' @param .con motherduck connection
#' @param from_db_name the local database to be copied
#' @param to_db_name the name of the motherduck database to be created
#'
#' @returns print statement
#' @export
#'
upload_database_to_md <- function(.con,from_db_name,to_db_name){

    DBI::dbExecute(
        .con
        ,dplyr::sql(
            paste0(
                "CREATE DATABASE",to_db_name,";","COPY FROM DATABASE ",from_db_name,"TO ",to_db_name,";"
            )
        )
    )

  cli::cli_h1("Status:")
  md:::validate_md_connection_status(.con)
  md:::cli_show_user(.con)
  md:::cli_show_db(.con)
  cli::cli_h2("Action Report:")
  cli::cli_li("Copied {to_db_name} from {from_db_name}")


}


#' List database functions
#' @name list_fns
#' @param .con connection
#'
#' @returns tibble
#' @export
#'
#' @examples
#' con <- DBI::dbConnect(duckdb::duckdb())
#' list_db_fns(con)
list_fns <- function(.con){

    validate_con(.con)
    validate_md_connection_status(.con)


    out    <- dplyr::tbl(
        .con
        ," SELECT *
        FROM duckdb_functions()
        ORDER BY function_name"
    )

    return(out)

}


#' list database objects
#'
#' @param .con connection
#' @param type 'database', 'schema' or 'views'
#'
#' @returns tibble
#' @export
#'
#' @examples
#' #' con <- DBI::dbConnect(duckdb::duckdb())
#' lmd(con,type='database')
list_databases<- function(.con){



    assertthat::assert_that(
        validate_con(.con)
    )

    database_dbi <-
        dplyr::tbl(
            .con
            ,sql("
      SELECT DISTINCT
      table_catalog
      FROM  information_schema.tables
      ")
        )

    suppressWarnings(
        return(database_dbi)
    )

}



#' list database objects
#'
#' @param .con connection
#' @param type 'database', 'schema' or 'views'
#'
#' @returns tibble
#' @export
#'
#' @examples
#' #' con <- DBI::dbConnect(duckdb::duckdb())
#' lmd(con,type='database')
list_schemas<- function(.con){



    assertthat::assert_that(
        validate_con(.con)
    )
#
#     assertthat::assert_that(
#         validate_md_connection_status(.con,return_type = "arg")
#     )


    schema_dbi <-
        dplyr::tbl(
            .con
            ,dplyr::sql("
          SELECT DISTINCT
          catalog_name
          ,schema_name
          FROM  information_schema.schemata
          WHERE
          TRUE
          AND catalog_name = current_database()
          ")
        )

    suppressWarnings(
        return(schema_dbi)
    )

}


#' list database objects
#'
#' @param .con connection
#' @param type 'database', 'schema' or 'views'
#'
#' @returns tibble
#' @export
#'
#' @examples
#' #' con <- DBI::dbConnect(duckdb::duckdb())
list_current_tables<- function(.con){


    assertthat::assert_that(
        validate_con(.con)
    )



    tables_dbi <-
        dplyr::tbl(
            .con
            ,dplyr::sql("
    SELECT DISTINCT
    table_catalog
    ,table_schema
    ,table_name
    FROM
    information_schema.tables
    WHERE
    TRUE
    AND table_catalog = current_database()
    AND table_schema =  current_schema()

")
        )

    suppressWarnings(
        return(tables_dbi)
    )

}



#' list database objects
#'
#' @param .con connection
#' @param type 'database', 'schema' or 'views'
#'
#' @returns tibble
#' @export
#'
#' @examples
#' #' con <- DBI::dbConnect(duckdb::duckdb())
#' list_all_tables(con,type='database')
list_all_tables<- function(.con){


    assertthat::assert_that(
        validate_con(.con)
    )

    tables_dbi <-
    dplyr::tbl(
      .con
      ,dplyr::sql("
        SELECT DISTINCT
        table_catalog
        ,table_schema
        ,table_name
        FROM
        information_schema.tables
                  ")
      )

    suppressWarnings(
        return(tables_dbi)
    )

}



#' Title
#'
#' @param .con connection
#' @param database_name database name
#'
#' @returns message
#' @export
#'
delete_database <- function(
        .con
        ,database_name
) {

    # Drop the database (no need to ATTACH)
    drop_db_sql <- glue::glue_sql(
        "DROP DATABASE IF EXISTS {`database_name`};",
        .con = .con
    )

    DBI::dbExecute(.con, drop_db_sql)

    cli::cli_h1("Status:")
    md:::validate_md_connection_status(.con)
    md:::cli_show_user(.con)
    md:::cli_show_db(.con)
    md:::cli_delete_obj(.con,database_name=database_name)



}


#' Title
#'
#' @param .con connection
#' @param table_name table name
#'
#' @returns tibble
#' @export
#'
return_table_attributes <- function(.con,table_name){

    out <- DBI::dbGetQuery(
        .con
        ,glue::glue_sql(
            "SELECT table_catalog, table_schema, table_name
     FROM information_schema.tables
     WHERE table_name IN ({table_name*})"
            ,.con = .con
        )
    )
    return(out)

}


#' @title Convert table to SQL IDs
#' @name convert_table_to_sql_id
#'
#' @param x tibble of database, schemas and tables
#'
#' @returns list of sql IDs
#'
convert_table_to_sql_id <- function(x){

  out <-  x |>
    rowwise() |>
    transmute(
      table_id=list(DBI::Id(table_catalog=table_catalog,table_schema=table_schema,table_name=table_name))
    ) |>
    ungroup() |>
    pluck(1)

  return(out)

}
