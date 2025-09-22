
#' @title List motherduck extensions, their description and status
#' @name list_extensions
#' @param .con DuckDB connection
#' @description
#' Lists available DuckDB extensions, their description, load / installed status and more
#'
#' @returns tbi
#' @export
#'
#' @examples
#' con <- DBI::dbConnect(duckdb::duckdb())
#' list_extensions(con)
list_extensions <- function(.con){

  validate_con(.con)

  out <- DBI::dbGetQuery(
    .con,
    "
    SELECT *
    FROM duckdb_extensions()
    "
  ) |> tibble::as_tibble()

  return(out)

}

#' @title Validate  Motherduck extensions are correctly loaded
#' @name validate_extension_load_status
#'
#' @param .con connection obj
#' @param extension_names list of extension names that you want to validate
#' @param return_type 'msg' or 'ext'
#'
#' @returns message or extension names
#' @export
#'
#' @examples
#' con <- DBI::dbConnect(duckdb::duckdb())
#' validate_extension_load_status(con,extension_names=c('excel','arrow'),return_type='ext')
validate_extension_load_status <- function(.con,extension_names,return_type="msg"){


  # extension_names <- "motherduck"

  return_type <- rlang::arg_match(
    return_type
    ,values = c("msg","ext","arg")
    ,multiple = FALSE
    ,error_arg = "Please only select 'msg', 'ext' or 'arg'"
  )


  # validate duckdb connection
  validate_con(.con)

  # validate valid extensions

  valid_ext_vec <- list_extensions(.con) |> dplyr::pull(extension_name)

  # pull status of the named exstensions
  ext_tbl <- list_extensions(.con) |>
    dplyr::filter(
      extension_name %in% extension_names
    ) |>
    dplyr::select(extension_name,loaded)

  # create a list to capture results
  ext_lst <- list()

  # assign extension status
  ext_lst$success_ext <- ext_tbl |>
    dplyr::filter(
      loaded==TRUE
    ) |>
    dplyr::pull(extension_name)

  ext_lst$fail_ext <- ext_tbl |>
    dplyr::filter(
      loaded==FALSE
    ) |>
    dplyr::pull(extension_name)

  ext_lst$missing_ext <- extension_names[!extension_names%in% valid_ext_vec]

  # create a list of extensions messages
  msg_lst <- list()

  if(length(ext_lst$missing_ext)>0){
    msg_lst$missing_ext <- "{.pkg {ext_lst$missing_ext}} can't be found"
  }

  if(length(ext_lst$success_ext)>0){

    msg_lst$sucess_ext <- "{.pkg {ext_lst$success_ext}} loaded"
  }

  if(length(ext_lst$fail_ext)>0){
    msg_lst$fail_ext <- "{.pkg {ext_lst$fail_ext}} did not load"
  }


  # create message
  cli_ext_status_msg <- function() {
    cli::cli_par()
    cli::cli_h1("Extension load status")
    purrr::map(
      msg_lst
      ,.f = \(x) cli::cli_text(x)
    )
    cli::cli_end()
    cli::cli_par()
    cli::cli_text("Use {.fn list_extensions} to list extensions and their descriptions")
    cli::cli_text("Use {.fn install_extensions} to install new {cli::col_red('duckdb')} extensions")
    cli::cli_text("See {.url https://duckdb.org/docs/stable/extensions/overview.html} for more information")
    cli::cli_end()
  }


  if(!length(ext_lst$fail_ext)>0){

    status <- TRUE

  }else{
    status <- FALSE
  }

  if(return_type=="msg"){

    cli_ext_status_msg()

  }

  if(return_type=="ext"){
    return(ext_lst)
  }

  if(return_type=="arg"){
    return(status)
  }

}


#' @title Validate that the Motherduck extension correctly loaded
#' @name validate_extension_install_status
#'
#' @param .con connection obj
#' @param extension_names list of extension names that you want to validate
#' @param return_type 'msg' or 'ext'
#'
#' @returns message or extension names
#' @export
#'
#' @examples
#' library(DBI)
#' con <- dbConnect(duckdb::duckdb())
#' validate_extension_install_status(con,extension_names=c('excel','arrow'),return_type='ext')
validate_extension_install_status <- function(.con,extension_names,return_type="msg"){

  ## need to first validate those that are returned from the table
  ## Then filter against the vector for those that aren't in table
  # extension_names <- c("arrow","excel","Adsfd","motherduck")


  return_type <- rlang::arg_match(
    return_type
    ,values = c("msg","ext","arg")
    ,multiple = FALSE
    ,error_arg = "Please only select 'msg', 'ext' or 'arg'"
  )

  validate_con(.con)

  valid_ext_vec <- list_extensions(.con) |> dplyr::pull(extension_name)

  ext_tbl <- list_extensions(.con) |>
    dplyr::filter(
      extension_name %in% c(extension_names)
    ) |>
    dplyr::select(extension_name,installed)




  ext_lst <- list()
  # load exntesion status
  ext_lst$success_ext <- ext_tbl |>
    dplyr::filter(
      installed==TRUE
    ) |>
    dplyr::pull(extension_name)

  ext_lst$fail_ext <- ext_tbl |>
    dplyr::filter(
      installed==FALSE
    ) |>
    dplyr::pull(extension_name)

  msg_lst <- list()

  if(length(ext_lst$missing_ext)>0){
    msg_lst$missing_ext <- "{.pkg {ext_lst$fail_ext}} can't be found"
  }

  if(length(ext_lst$success_ext)>0){

    msg_lst$sucess_ext <- "{.pkg {ext_lst$success_ext}} is installed"
  }

  if(length(ext_lst$fail_ext)>0){
    msg_lst$fail_ext <- "{.pkg {ext_lst$fail_ext}} is not installed"
  }


  # create message
  cli_ext_status_msg <- function() {
    cli::cli_par()
    cli::cli_h1("Extension install status")
    purrr::map(
      msg_lst
      ,.f = \(x) cli::cli_text(x)
    )
    cli::cli_end()
    cli::cli_par()
    cli::cli_text("Use {.fn list_extensions} to list extensions and their descriptions")
    cli::cli_text("Use {.fn install_extensions} to install new {cli::col_red('duckdb')} extensions")
    cli::cli_text("See {.url https://duckdb.org/docs/stable/extensions/overview.html} for more information")
    cli::cli_end()
  }

  # check

  if(!length(ext_lst$fail_ext)>0){

    status <- TRUE

  }else{
    status <- FALSE
  }

  if(return_type=="msg"){

    cli_ext_status_msg()

  }

  if(return_type=="ext"){
    return(ext_lst)
  }

  if(return_type=="arg"){
    return(status)
  }

}



#' @title Install motherduck extensions
#' @name install_extensions
#' @description
#' Installs and loads valid DuckDB extensions
#'
#' @param .con duckdb connection
#' @param extension_names DuckDB extension names
#' @param silent_msg indicate if you want a success / failure report after installation and loading
#'
#' @returns message
#' @export
#'
#' @examples
#' con <- DBI::dbConnect(duckdb::duckdb())
#' install_extensions(con,'motherduck',silent_msg=TRUE)
#'
install_extensions <- function(.con,extension_names){

  # extension_names <- c("fts")
  # silent_msg <- TRUE
  # .con <- con

  # assertthat::assert_that(is.logical(silent_msg),msg = "silent_msg must be TRUE or FALSE")

  validate_con(.con)

  valid_ext_vec <- list_extensions(.con) |>
    dplyr::pull(extension_name)

 ext_lst <- list()

 ext_lst$invalid_ext <-  extension_names[!extension_names%in%valid_ext_vec ]

 ext_lst$valid_ext <- extension_names[extension_names%in%valid_ext_vec ]

  # install packages

 # validate_extension_install_status(.con,ext_lst$valid_ext,return_type = "arg")

 if(!validate_extension_install_status(.con,ext_lst$valid_ext,return_type = "arg")){

   purrr::map(
     ext_lst$valid_ext
     ,\(x)  DBI::dbExecute(.con, glue::glue("INSTALL {x};"))
   )

 }

  msg_lst <- list()

  if(length(ext_lst$valid_ext)>0){
    n_ext <- length(ext_lst$valid_ext)
    msg_lst$valid_msg <- "Installed {cli::col_yellow({cli::no(n_ext)})} extension{?s}: {.pkg {ext_lst$valid_ext}}"

  }

  if(length(ext_lst$invalid_ext)>0){
    n_ext <- length(ext_lst$invalid_ext)
    msg_lst$invalid_msg <- "Failed to install {cli::col_yellow({cli::no(n_ext)})} extension{?s}: {.pkg {ext_lst$invalid_ext}} are not valid"

  }


  cli_ext_status_msg <- function() {
    cli::cli_par()
    cli::cli_h1("Extension Install Report")
    purrr::map(
      msg_lst
      ,.f = \(x) cli::cli_text(x)
    )
    cli::cli_end()
    cli::cli_par()
    cli::cli_text("Use {.fn list_extensions} to list extensions, status and their descriptions")
    cli::cli_text("Use {.fn install_extensions} to install new {cli::col_red('duckdb')} extensions")
    cli::cli_text("See {.url https://duckdb.org/docs/stable/extensions/overview.html} for more information")
    cli::cli_end()
  }
# if(!silent_msg){
  cli_ext_status_msg()
# }

}


#' @title Loand (and install) motherduck extensions
#' @name load_extensions
#' @description
#' Installs and loads valid DuckDB extensions
#'
#' @param .con duckdb connection
#' @param extension_names DuckDB extension names
#' @param silent_msg indicate if you want a success / failure report after installation and loading
#'
#' @returns message
#' @export
#'
#' @examples
#' con <- DBI::dbConnect(duckdb::duckdb())
#' load_extensions(con,'motherduck')
#'
load_extensions <- function(.con,extension_names){

  # extension_names <- c("motherduck")
  # silent_msg <- TRUE
  # .con <- connect_to_motherduck()

  # assertthat::assert_that(is.logical(silent_msg),msg = "silent_msg must be TRUE or FALSE")

  validate_con(.con)

  valid_ext_vec <- list_extensions(.con) |>
    dplyr::pull(extension_name)

  ext_lst <- list()

  ext_lst$invalid_ext <-  extension_names[!extension_names%in%valid_ext_vec ]

  ext_lst$valid_ext <- extension_names[extension_names%in%valid_ext_vec ]

  # install packages

  # validate_extension_install_status(.con,ext_lst$valid_ext,return_type = "arg")

  if(!validate_extension_install_status(.con,ext_lst$valid_ext,return_type = "arg")){


    purrr::map(
      ext_lst$valid_ext
      ,\(x)  DBI::dbExecute(.con, glue::glue("INSTALL {x};"))
    )

  }

  # load packages
  purrr::map(
    ext_lst$valid_ext
    ,\(x)  DBI::dbExecute(.con, glue::glue("LOAD {x};"))
  )

  msg_lst <- list()

  if(length(ext_lst$valid_ext)>0){
    n_ext <- length(ext_lst$valid_ext)
    msg_lst$valid_msg <- "Installed and loaded {cli::col_yellow({cli::no(n_ext)})} extension{?s}: {.pkg {ext_lst$valid_ext}}"

  }

  if(length(ext_lst$invalid_ext)>0){
    n_ext <- length(ext_lst$invalid_ext)
    msg_lst$invalid_msg <- "Failed to install and load {cli::col_yellow({cli::no(n_ext)})} extension{?s}: {.pkg {ext_lst$invalid_ext}} are not valid"

  }


  cli_ext_status_msg <- function() {
    cli::cli_par()
    cli::cli_h1("Extension Load & Install Report")
    purrr::map(
      msg_lst
      ,.f = \(x) cli::cli_text(x)
    )
    cli::cli_end()
    cli::cli_par()
    cli::cli_text("Use {.fn list_extensions} to list extensions, status and their descriptions")
    cli::cli_text("Use {.fn install_extensions} to install new {cli::col_red('duckdb')} extensions")
    cli::cli_text("See {.url https://duckdb.org/docs/stable/extensions/overview.html} for more information")
    cli::cli_end()
  }


    cli_ext_status_msg()


}




#' @title Show your motherduck token
#' @name show_motherduck_token
#'
#' @param .con connection
#'
#' @returns message
#' @export
#'
show_motherduck_token <- function(.con){

  validate_con(.con)
  validate_connection_status(.con)

  DBI::dbGetQuery(.con, 'PRAGMA print_md_token;')

}








#' Show DuckDB settings
#'
#' @param .con connection
#'
#' @returns tibble
#' @export
#'
#' @examples
#' con <- DBI::dbConnect(duckdb::duckdb())
#' show_duckdb_settings(con)
show_duckdb_settings <- function(.con){

  validate_con(.con)

 out <-  DBI::dbGetQuery(.con,"SELECT * from duckdb_settings();") |> tibble::as_tibble()

 return(out)

}

#' @title read httpfs files
#' @name read_httpfs
#' @description
#' Enables reading of httpfs files
#'
#' @param .con DuckDB connection
#' @param file_path to httpfs files
#'
#' @returns message
#' @export
#'
read_csv_auto <- function(.con,file_path,...){

  assertthat::assert_that(
  validate_md_connection_status(.con,return_type = "arg")
  )


  out <- dplyr::tbl(
    .con,
    sql(
      "
     SELECT *
     FROM read_csv_auto('",file_path,"')"
    )
  )
  return(out)

}


#' @title read httpfs files
#' @name read_httpfs
#' @description
#' Enables reading of httpfs files
#'
#' @param .con DuckDB connection
#' @param file_path to httpfs files
#'
#' @returns message
#' @export
#'
read_httpfs <- function(.con,file_path){

  validate_con(.con)

  validate_md_connection_status(.con)

.con <- con
  DBI::dbGetQuery(
    .con,
    paste0(
    "INSTALL httpfs;
     LOAD httpfs;

     SELECT *
     FROM read_parquet('",file_path,"');"
    )
  )

}

#' @title read httpfs files
#'
#' @param .con connection
#' @param file_path file path to parquet files
#'
#' @returns message
#' @export
#'
read_parquet <- function(.con,file_path){

  validate_con(.con)
  validate_md_connection_status(.con)

  DBI::dbExecute(
    .con,
    paste0(
      "
CREATE OR REPLACE VIEW my_parquet_view AS
SELECT * FROM read_parquet('",file_path,"');"
    )
  )

}




#' @title  Print current databases
#' @name pwd
#' @description
#' Prints the current database that you are in (adopts language from linux)
#'
#' @param .con
#'
#' @returns tibble
#' @export
#'
#' @examples
#' #' con <- DBI::dbConnect(duckdb::duckdb())
#' pwd(con)
pwd <- function(.con){

  validate_con(.con)

  database_tbl <-
    DBI::dbGetQuery(.con,"select current_database();") |>
    tibble::as_tibble(.name_repair = janitor::make_clean_names)

  schema_tbl <- DBI::dbGetQuery(.con,"select current_schema();") |>
    tibble::as_tibble(.name_repair = janitor::make_clean_names)

  role_vec <- DBI::dbGetQuery(.con,"select current_role();") |>
    tibble::as_tibble(.name_repair = janitor::make_clean_names) |>
    pull(current_role)


  out <- bind_cols(database_tbl,schema_tbl)

  cli::cli_alert("Current role: {.envvar {role_vec}}")

  return(out)
}


#' Change Database
#'
#' @param .con connection
#' @param database database name
#'
#' @returns message
#' @export
#'
cd <- function(.con,database,schema){

  validate_con(.con)

  database_valid_vec <- list_databases(.con) |>
    dplyr::pull(table_catalog)

  if(database %in% database_valid_vec){

    DBI::dbExecute(.con,glue::glue("USE {database};"))

    current_database_vec <- pwd(.con) |>
      dplyr::pull(current_database)

    cli::cli_text("Current database: {.pkg {current_database_vec}}")

  }else{

    cli::cli_abort("
                   {.pkg {database}} is not valid,
                   Use {.fn ls} to list valid databases:
                   {.or {database_valid_vec}}
                   ")
  }

  if(!missing(schema)){

  schema_valid_vec <- list_schemas(.con) |>
    dplyr::pull(schema_name)




  if(schema %in% schema_valid_vec){

    DBI::dbExecute(.con,glue::glue("USE {schema};"))

    current_schema_vec <-   suppressMessages(
      pwd(.con) |>
      dplyr::pull(current_schema)
    )

    cli::cli_text("Current schema: {.pkg {current_schema_vec}}")

  }else{

    cli::cli_abort("
                   {.pkg {schema}} is not valid,
                   Use {.fn list_schema} to list valid schemas:
                   {.or {schema_valid_vec}}
                   ")
  }
}


}






#' Summarize for DBI objects
#'
#' @param .data dbi object
#'
#' @returns DBI object
#' @export

summary.tbl_lazy <- function(.data){

  con <- dbplyr::remote_con(.data)

  ## assert connection

  assertthat::assert_that(
  validate_con(con)
  )

  query <- dbplyr::remote_query(.data)
  summary_query <- paste0("summarize (",query,")")

  out <- dplyr::tbl(con,dplyr::sql(summary_query))
  return(out)
}








#' @title List database settings
#' @name list_settings
#' @param .con dubdb or md connection
#'
#' @returns tibble
#' @export
#'
list_setting <- function(.con){

  out <- DBI::dbGetQuery(
    .con
    ,"
  SELECT *
  FROM duckdb_settings()
  "
  ) |>
    dplyr::as_tibble()

  return(out)

}




# sample_frac.tbl_lazy <- function(.con,table_name,frac_prop){
#
#   # table_name <- "orders"
#   # frac_prop <- 10
#
#   validate_md_connection_status(.con,return_type = "msg")
#
#   out <-  dplyr::tbl(
#     .con
#     ,dplyr::sql(
#       paste0("
#            SELECT * FROM ",table_name," USING SAMPLE ",frac_prop,"%"
#       )
#     )
#   )
#
#   return(out)
#
# }


#' Title
#'
#' @param .con connection
#'
#' @returns message
#' @export
#'
list_shares <- function(.con){

  out <- DBI::dbGetQuery(
    .con
    ,"LIST SHARES;"
  ) |>
    tibble::as_tibble()

  return(out)

}







utils::globalVariables(c("con", "extension_name", "installed", "loaded"))
