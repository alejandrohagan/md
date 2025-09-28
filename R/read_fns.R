

#' Title
#'
#' @param .con
#' @param to_database_name
#' @param to_schema_name
#' @param to_table_name
#' @param file_path
#' @param header
#' @param sheet
#' @param all_var_char
#' @param ignore_errors
#' @param range
#' @param stop_at_empty
#' @param empty_as_varchar
#'
#' @returns
#' @export
#'
#' @examples
read_excel_duckdb <- function(.con,to_database_name,to_schema_name,to_table_name,file_path,header,sheet,all_varchar,ignore_errors,range,stop_at_empty,empty_as_varchar){

    stop_at_empty <- TRUE
    range <- "a1"
    all_varchar <- TRUE
    header <-TRUE
    sheet <- "sheet1"

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

    md::load_extensions(temp_con,"excel")

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


#' Title
#'
#' @param .con
#' @param to_database_name
#' @param to_schema_name
#' @param to_table_name
#' @param file_path
#' @param header
#' @param sheet
#' @param all_var_char
#' @param ignore_errors
#' @param range
#' @param stop_at_empty
#' @param empty_as_varchar
#'
#' @returns
#' @export
#'
#' @examples
read_parquet_duckdb <- function(.con,to_database_name,to_schema_name,to_table_name,file_path){

    md::load_extensions(temp_con,"httpfs")


    DBI::dbExecute(conn = .con,glue::glue_sql("CREATE TABLE {`to_table_name`} AS SELECT * FROM read_parquet({`file_path`});",.con = .con))

}

