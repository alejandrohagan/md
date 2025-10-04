
#'
#' @title Database, Schema, and Table Creator
#' @name cli_create_obj
#'
#' @param .con A database connection object. This is the connection through which the database, schema, and table information
#'             is retrieved.
#' @param database_name The name of the database to create or insert into. If missing, the current database is used.
#' @param schema_name The name of the schema to create or insert into. If missing, the current schema is used.
#' @param table_name The name of the table to create or insert into. If missing, no table-specific action is taken.
#' @param write_type Specifies the type of write operation. Used to describe whether an existing table is updated
#'                   (e.g., "insert" or "update").
#' @description
#' This function creates or inserts data into a specified database, schema, and table. If no database,
#' schema, or table is provided, the function attempts to use the current database, schema, or table.
#' It first checks if the provided database, schema, or table exists, and then either creates a new one
#' or inserts into the existing one, based on the given parameters. It generates an action report
#' indicating the status of the operation, whether a new database, schema, or table was created or
#' whether existing ones were used.
#' @returns This function doesn't return any value. It generates a formatted report showing whether a new database, schema,
#'          or table was created or if existing ones were used.
#'
cli_create_obj <- function(.con, database_name, schema_name, table_name, write_type) {

    # Step 1: Get a list of all tables from the connected database
    all_table_tbl <- list_all_tables(.con) |> dplyr::collect()

    all_database_tbl <- list_databases(.con) |> dplyr::collect()


    # Step 2: If no database name is provided, get the current database from the connection
    if (is_missing(database_name)) {
        database_name <- pwd(.con) |> dplyr::pull(current_database)
    }

    # Step 3: Check how many tables are in the provided database by filtering

    database_name_vec <- database_name

    db_count <-
        all_database_tbl |>
        dplyr::filter(
            database_name %in% database_name   # Filter by the given database name
        ) |>
        nrow()   # Count the rows (number of tables in that database)

    # Step 4: Print action report header
    cli::cli_h2("Action Report:")

    # Step 5: Report whether a new database is created or an existing database is used
    cli::cli_text(
        if_else(!db_count > 0,
                "{cli::symbol$tick} Created new database {.val {database_name}}",
                "{cli::symbol$tick} Inserted into existing database {.val {database_name}}"
                )
    )

    # Step 6: If no schema name is provided, get the current schema from the connection
    if (rlang::is_missing(schema_name)) {
        schema_name <- pwd(.con) |> pull(current_schema)
    }

    # Step 7: If schema name is provided, check how many tables exist in the schema
    if (!rlang::is_missing(schema_name)) {

        schema_name_vec <- schema_name

        suppressMessages(
        cd(.con,database = database_name)
        )

        schema_count <- list_schemas(.con) |>
            dplyr::collect() |>
            dplyr::filter(
                catalog_name %in% database_name   # Filter by database
                , schema_name %in% schema_name_vec    # Filter by schema
            ) |>
            nrow()   # Count the rows (number of tables in the schema)

        # Step 8: Report whether a new schema is created or an existing schema is used
        cli::cli_text(
            if_else(!schema_count > 0,
                    "{cli::symbol$tick} Created new schema {.val {schema_name}}",
                    "{cli::symbol$tick} Using existing schema {.val {schema_name}}")
        )
    }

    # Step 9: If a table name is provided, check how many times the table exists in the schema
    if (!rlang::is_missing(table_name)) {
        table_name_vec <- table_name   # Convert table_name to vector (it could be a single name or multiple)

        table_count <- all_table_tbl |>
            filter(
                table_catalog %in% database_name  # Filter by database
                , table_schema %in% schema_name   # Filter by schema
                , table_name %in% table_name_vec  # Filter by table name
            ) |>
            nrow()   # Count the rows (number of matching tables)

        # Step 10: Report whether a new table is created or an existing table is used (based on write_type)
        cli::cli_text(
            if_else(!table_count > 0,
                    "{cli::symbol$tick} Created new table {.val {table_name_vec}}",
                    "{cli::symbol$tick} {str_to_sentence(write_type)} existing table {.val {table_name_vec}}")
        )
    }
}


#' @title User Information Report
#' @name cli_show_user
#'
#' @param .con A database connection object. This is the connection through which the current user and role
#'             information is retrieved.
#'
#' @returns This function doesn't return any value. It generates a formatted user report with the current user's
#'          name and role as output.
#'
#' @description
#' This function generates a report that shows the current user and their assigned role within the database.
#' It queries the database to retrieve the current user using `current_user()` and the current role using
#' `current_role()`. The output is displayed in a clear and formatted manner, with the user name and role
#' listed in an unordered list.
cli_show_user <- function(.con) {

    # Step 1: Get the current user by querying the database
    # Uses `current_user()` to retrieve the current database user
    current_user <- dplyr::tbl(.con, sql("select current_user() as user")) |>
        dplyr::pull(user)  # Extract the user value from the result

    # Step 2: Get the current role by querying the database
    # Uses `current_role()` to retrieve the current role of the user
    current_role <- dplyr::tbl(.con, sql("select current_role() as role")) |>
        dplyr::pull(role)  # Extract the role value from the result

    # Step 3: Start the user report section with a header
    cli::cli_h2("User Report:")  # Adds a second-level header "User Report:"

    # Step 4: Start an unordered list (bullet points)
    cli::cli_ul()

    # Step 5: Print user name
    cli::cli_li("User Name: {.val {current_user}}")  # Prints the user name in the list

    # Step 6: Print role name
    cli::cli_li("Role: {.val {current_role}}")  # Prints the role in the list

    # Step 7: End the unordered list
    cli::cli_end()  # Closes the list and the user report section
}





#'
#' @title Catalog Report Generator
#' @name cli_show_db
#'
#' @param .con A database connection object. This is the connection through which the catalog and schema information
#'             is retrieved.
#'
#' @returns This function doesn't return any value. It generates a formatted catalog report as output, including the
#'          current database, schema, and access counts for catalogs, tables, and shares.
#' @description
#' This function generates a report that provides details about the current database catalog, schema, and
#' the number of resources (such as catalogs, tables, and shares) that the user has access to in the
#' connected database. It also offers helpful functions for navigating the catalog, schema, and databases.
#' The report includes:
#' - Current database (catalog)
#' - Current schema
#' - Number of catalogs the user has access to
#' - Number of tables the user has access to
#' - Number of shares the user has access to
#'
#' In addition, the function lists several useful functions like `cd`, `pwd`, `list_database`, etc.,
#' that help manage and explore the database resources.
cli_show_db <- function(.con) {

    # Step 1: Get the number of shares the user has access to
    # Calls `md::list_shares` to list all shares and counts the rows
    suppressWarnings(
    share_count <- md::list_shares(.con) |> nrow()
    )
    # Step 2: Get the current database (catalog) from the connection
    # Uses `current_catalog()` to get the current database name
    current_db <- dplyr::tbl(.con, sql("select current_catalog() as catalog")) |>
        dplyr::pull(catalog)  # Extracts the database name

    # Step 3: Get the current schema from the connection
    # Uses `current_schema()` to get the current schema name
    current_schema <- dplyr::tbl(.con, sql("select current_schema() as schema")) |>
        dplyr::pull(schema)  # Extracts the schema name

    # Step 4: Get the number of catalogs (databases) the user has access to
    # Calls `md::list_databases` to list all databases and counts them
    db_count <- md::list_databases(.con) |>
        dplyr::pull(database_name) |>
        length()  # Counts the available catalogs

    # Step 5: Get the number of tables the user has access to
    # Calls `md::list_all_tables` to list all tables and counts them
    table_count <- md::list_all_tables(.con) |>
        dplyr::collect() |>
        nrow()  # Counts the available tables

    table_count_in_db <- md::list_all_tables(.con) |>
        dplyr::collect() |>
        dplyr::filter(
            table_catalog %in% c(current_db)
        ) |> nrow()


    table_count_in_db_schema <- md::list_all_tables(.con) |>
        dplyr::collect() |>
        dplyr::filter(
            table_catalog %in% c(current_db)
            ,table_schema %in% c(current_schema)
        ) |> nrow()

    # Step 6: Start the Catalog Report section with a header
    cli::cli_h2("Catalog Report:")  # Adds a second-level header "Catalog Report:"

    # Step 7: Start an unordered list (bullet points)
    cli::cli_ul()

    # Step 8: Display the current database and schema
    cli::cli_li("Current Database: {.val {current_db}}")  # Displays the current database
    cli::cli_li("Current Schema: {.val {current_schema}}")  # Displays the current schema

    # Step 9: Display the counts for catalogs, tables, and shares
    cli::cli_li("# Total Catalogs you have access to: {.val {db_count}}")  # Displays the number of catalogs
    cli::cli_li("# Total Tables you have access to: {.val {table_count}}")  # Displays the number of tables
    cli::cli_li("# Total Shares you have access to: {.val {share_count}}")  # Displays the number of shares
    cli::cli_li("# Tables in this catalog you have access to: {.val {table_count_in_db}}")  # Displays the number of shares
    cli::cli_li("# Tables in this catalog & schema you have access to: {.val {table_count_in_db_schema}}")  # Displays the number of shares
}


#' @title CLI print deleted objects
#' @name cli_delete_obj
#' @param .con A connection object to the database.
#' @param database_name Name of the database to be deleted (optional).
#' @param schema_name Name of the schema to be deleted (optional).
#' @param table_name Name of the table to be deleted (optional).
#' @description
#' This function allows you to delete specified objects (database, schema, or table) from the connected
#' database. The function will check if the provided database, schema, or table exists. If they do,
#' it will proceed to delete them and print an action report detailing what was deleted and how many
#' schemas or tables were affected. If the object does not exist, it will not delete anything.
#'
#' @returns This function does not return any values. It prints a message indicating
#'          the deleted objects (database, schema, or table) and the number of schemas/tables
#'          affected by the deletion.
#'
cli_delete_obj <- function(.con, database_name, schema_name, table_name) {


    # database_name <- "test"
    all_table_tbl <- list_all_tables(.con) |> dplyr::collect()

    if (is_missing(database_name)) {
        database_name <- pwd(.con) |> dplyr::pull(current_database)
    }

    if(!rlang::is_missing(database_name)){


        db_tbl <-
            all_table_tbl |>
            dplyr::filter(
                table_catalog %in% database_name
            )
    }

    if(!rlang::is_missing(schema_name)){

        schema_tbl <-
            all_table_tbl |>
            dplyr::filter(
                table_catalog %in% database_name
                ,table_schema %in% schema_name
            )

    }


    if(!rlang::is_missing(table_name)){

        table_name_vec <- table_name

        table_tbl <-
            all_table_tbl |>
            dplyr::filter(
                table_catalog %in% database_name
                ,table_schema %in% schema_name
                ,table_name %in% table_name_vec
            )
    }

    cli::cli_h2("Action Report:")

    if(!rlang::is_missing(database_name)){


            schema_count <- db_tbl |> pull(table_schema) |> unique() |> length()

            table_count <- db_tbl |> pull(table_name) |> unique() |> length()

            cli::cli_li("Deleted {.val {database_name}} database with {.val {schema_count}} schemas and {.val {table_count}} tables")
    }

    if(!rlang::is_missing(schema_name)){

        if(nrow(schema_tbl)>0){

            table_count <- schema_tbl |> nrow()

            cli::cli_li("Deleted schema {.val {schema_name}} with {.val {table_count}} tables")
        }
    }

    if(!rlang::is_missing(table_name)){

        if(nrow(table_tbl)>0){

            cli::cli_li("Deleted table {.val {table_name}}")

        }
    }

}
