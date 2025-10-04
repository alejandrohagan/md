
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
#' @param to_database_name Target database name.
#' @param to_schema_name Target schema name.
#' @param to_table_name Target table name to create.
#' @param file_path Path to the Excel file (`.xlsx`).
#' @param header Logical; if `TRUE`, first row is header.
#' @param sheet Character; sheet name or index (as character) to read.
#' @param all_varchar Logical; coerce all columns to `VARCHAR`.
#' @param ignore_errors Logical; continue on cell/row errors.
#' @param range Character; Excel range like `"A1"` or `"A1:C100"`.
#' @param stop_at_empty Logical; stop at first completely empty row.
#' @param empty_as_varchar Logical; treat empty columns as `VARCHAR`.
#'
#' @return Invisibly returns `NULL`.
#' Side effect: creates `<database>.<schema>.<table>` with the Excel data.
#'
#' @seealso [DBI::dbExecute()], DuckDB **excel** extension (`read_xlsx`)
read_excel_duckdb <- function(.con,to_database_name,to_schema_name,to_table_name,file_path,header,sheet,all_varchar,ignore_errors,range,stop_at_empty,empty_as_varchar){

    # stop_at_empty <- TRUE
    # range <- "a1"
    # all_varchar <- TRUE
    # header <-TRUE
    # sheet <- "sheet1"

    if(!missing(range)){

    assertthat::assert_that(is.character(range))

        range_vec <- "range={range}"

    }else{

        range_vec <- ''
    }

    # stop_at_empty args

    if(!missing(stop_at_empty)){

        assertthat::assert_that(is.logical(stop_at_empty))

        stop_at_empty <- if (stop_at_empty) "true" else "false"

        stop_at_empty_vec <- "stop_at_empty={stop_at_empty}"

    }else{

        stop_at_empty_vec <- ''
    }

    # all_varchar args

    if(!missing(all_varchar)){

        assertthat::assert_that(is.logical(all_varchar))

        all_varchar <- if (all_varchar) "true" else "false"


        all_varchar_vec <- "all_varchar={all_varchar}"

    }else{

        all_varchar_vec <- ''
    }



    # header args

    if(!missing(header)){

        assertthat::assert_that(is.logical(header))

        header <- if (header) "true" else "false"

        header_vec <- "stop_at_empty={stop_at_empty}"

    }else{

        header_vec <- ''
    }


    # sheet args

    if(!missing(sheet)){

        assertthat::assert_that(is.character(sheet))

        sheet_vec <- "sheet={sheet}"

    }else{

        sheet_vec <- ''
    }




# need to convert logic values to lowercase chracter

    md::load_extensions(.con,"excel")

    DBI::dbExecute(conn = .con,glue::glue_sql("USE {`to_database_name`}",.con=.con))

    DBI::dbExecute(conn = .con,glue::glue_sql("USE {`to_schema_name`}",.con=.con))

    DBI::dbExecute(
        conn = .con
        ,glue::glue(
            "CREATE TABLE {`to_table_name`} AS SELECT * FROM read_xlsx({`file_path`},",sheet_vec,header_vec,all_varchar_vec,stop_at_empty_vec,range_vec,");"
            ,.con = .con
            )
        )


}
