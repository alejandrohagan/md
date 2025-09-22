

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
read_excel_duckdb <- function(.con,to_database_name,to_schema_name,to_table_name,file_path,header,sheet,all_var_char,ignore_errors,range,stop_at_empty,empty_as_varchar){

    md::load_extensions(temp_con,"excel")


    DBI::dbExecute(conn = .con,glue::glue_sql("CREATE TABLE starwars AS SELECT * FROM read_xlsx({`file_path`});",.con = .con))


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
read_parquet_duckdb <- function(.con,to_database_name,to_schema_name,to_table_name,file_path,header,sheet,all_var_char,ignore_errors,range,stop_at_empty,empty_as_varchar){

    md::load_extensions(temp_con,"excel")


    DBI::dbExecute(conn = .con,glue::glue_sql("CREATE TABLE {`to_table_name`} AS SELECT * FROM read_parquet({`file_path`});",.con = .con))

}

