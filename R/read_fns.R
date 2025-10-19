
#' @title Read an Excel file into a DuckDB/MotherDuck table
#' @name read_excel_duckdb
#'
#' @description
#' Loads the DuckDB **excel** extension and creates a table from an Excel file
#' using the `read_xlsx()` table function. The destination is fully qualified
#' as `<database>.<schema>.<table>`. Only the options you supply are forwarded
#' to `read_xlsx()` (e.g., `sheet`, `header`, `all_varchar`, `ignore_errors`,
#' `range`, `stop_at_empty`, `empty_as_varchar`).
#'
#' @param .con A valid `DBI` connection (DuckDB / MotherDuck).
#' @param to_database_name Target database name
#' @param to_schema_name Target schema name
#' @param to_table_name Target table name to create
#' @param file_path Path to the Excel file (`.xlsx`)
#' @param header Logical; if `TRUE`, first row is header
#' @param sheet Character; sheet name or index (as character) to read
#' @param all_varchar Logical; coerce all columns to `VARCHAR`
#' @param ignore_errors Logical; continue on cell/row errors
#' @param range Character; Excel range like `"A1"` or `"A1:C100"`
#' @param stop_at_empty Logical; stop at first completely empty row
#' @param empty_as_varchar Logical; treat empty columns as `VARCHAR`
#' @param write_type Logical, will drop previous table and replace with new table
#' @export
#'
#' @return Invisibly returns `NULL`.
#' Side effect: creates `<database>.<schema>.<table>` with the Excel data.
#'
#' @seealso [DBI::dbExecute()], DuckDB **excel** extension (`read_xlsx`)
read_excel_duckdb <- function(.con,to_database_name,to_schema_name,to_table_name,file_path,header,sheet,all_varchar,ignore_errors,range,stop_at_empty,empty_as_varchar,write_type){

    # stop_at_empty <- TRUE
    # range <- "a1"
    # all_varchar <- TRUE
    # header <-TRUE
    # sheet <- "sheet1"
    # to_database_name="vignette"
    # to_schema_name="raw"
    # to_table_name="starwars"
    # file_path = "starwars.xlsx"


    write_type <- rlang::arg_match(write_type,c("overwrite","append"))
    # file path check and quotation

    assertthat::assert_that(is.character(file_path),file.exists(file_path))

    file_path <- DBI::dbQuoteIdentifier(conn = .con,x = file_path)

    # cell range validation


    if(!missing(range)){

    assertthat::assert_that(is.character(range))

        range_vec <- ",range={range}"

    }else{

        range_vec <- ''
    }

    # stop_at_empty args validation

    if(!missing(stop_at_empty)){

        assertthat::assert_that(is.logical(stop_at_empty))

        stop_at_empty <- if (stop_at_empty) "true" else "false"

        stop_at_empty_vec <- ",stop_at_empty={`stop_at_empty`}"

    }else{

        stop_at_empty_vec <- ''
    }

    # all_varchar validation

    if(!missing(all_varchar)){

        assertthat::assert_that(is.logical(all_varchar))

        all_varchar <- if (all_varchar) "true" else "false"


        all_varchar_vec <- ",all_varchar={all_varchar}"

    }else{

        all_varchar_vec <- ''
    }



    # header args

    if(!missing(header)){

        assertthat::assert_that(is.logical(header))

        header <- if (header) "true" else "false"

        header_vec <- ",header={header}"

    }else{

        header_vec <- ''
    }


    # empty as varcar

    if(!missing(empty_as_varchar)){

        assertthat::assert_that(is.logical(empty_as_varchar))

        empty_as_varchar <- if (header) "true" else "false"

        empty_as_varchar_vec <- ",empty_as_varchar={empty_as_varchar}"

    }else{

        empty_as_varchar_vec <- ''
    }


    # ignore errors

    if(!missing(ignore_errors)){

        assertthat::assert_that(is.logical(ignore_errors))

        ignore_errors <- if (ignore_errors) "true" else "false"

        ignore_errors_vec <- ",ignore_errors={ignore_errors}"

    }else{

        ignore_errors_vec <- ''
    }


    # sheet args

    if(!missing(sheet)){

        assertthat::assert_that(is.character(sheet))

        sheet <- DBI::dbQuoteIdentifier(conn=.con,x=sheet)
        sheet_vec <- ",sheet={`sheet`}"

    }else{

        sheet_vec <- ''
    }



# .con <- con_md
# need to convert logic values to lowercase chracter

    md::load_extensions(.con,"excel")

    #need this to be create if not exists and then use
    DBI::dbExecute(conn = .con,glue::glue_sql("CREATE DATABASE IF NOT EXISTS {`to_database_name`}; USE {`to_database_name`};",.con=.con))

    #need this to be create if not exists and then use
    DBI::dbExecute(conn = .con,glue::glue_sql("CREATE SCHEMA IF NOT EXISTS {`to_schema_name`}; USE {`to_schema_name`}; ",.con=.con))

    if(write_type=="overwrite"){

        DBI::dbExecute(
            conn = .con,
            glue::glue_sql("DROP TABLE IF EXISTS {`to_table_name`};", .con = .con)
        )

        DBI::dbExecute(
            conn = .con
            ,glue::glue(
                "CREATE TABLE IF NOT EXISTS {`to_table_name`} AS SELECT * FROM read_xlsx({file_path}",range_vec,stop_at_empty_vec,all_varchar_vec,header_vec,sheet_vec,ignore_errors_vec,empty_as_varchar_vec,");"
            )
            ,.con = .con
        )


    }

    if(write_type=="append"){

        DBI::dbExecute(
            conn = .con,
            glue::glue_sql("DROP TABLE IF EXISTS {`to_table_name`};", .con = .con)
        )

        DBI::dbExecute(
            conn = .con
            ,glue::glue(
                "CREATE TABLE IF NOT EXISTS {`to_table_name`}; INSERT INTO {`to_table_name`} SELECT * FROM read_xlsx({file_path}",range_vec,stop_at_empty_vec,all_varchar_vec,header_vec,sheet_vec,ignore_errors_vec,empty_as_varchar_vec,");"
            )
            ,.con = .con
        )


    }



    md:::cli_create_obj(.con,database_name = to_database_name,schema_name = to_schema_name,table_name = to_table_name,write_type = write_type)
}

