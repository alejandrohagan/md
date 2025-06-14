
#' @title Validate connection is DuckDB
#' @name validate_duckdb_con
#' @description
#' Validates that your connection object is a DuckDB connection
#'
#'
#' @param .con connection
#
#' @returns logical value or error message
#' @export
#'
#' @examples
#' con <- DBI::dbConnect(duckdb::duckdb())
#' validate_duckdb_con(con)
validate_duckdb_con <- function(.con){

  dbIsValid_poss <- purrr::possibly(DBI::dbIsValid)


  valid_test <- is.null(dbIsValid_poss(.con))

  if(valid_test){
    cli::cli_abort("Connection string is not valid, please try again")

  }else{
    return(TRUE)
  }



}


#' @title List motherduck extensions, their description and status
#' @name list_extensions
#' @param .con DuckDB connection
#' @description
#' Lists available DuckDB extensions, their description, load / installed status and more
#'
#' @returns tibble
#' @export
#'
#' @examples
#' con <- DBI::dbConnect(duckdb::duckdb())
#' list_extensions(con)
list_extensions <- function(.con){

  validate_duckdb_con(.con)

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


  return_type <- match.arg(
    return_type
    ,choices = c("msg","ext")
  )

  # validate duckdb connection
  validate_duckdb_con(.con)

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

  if(return_type=="msg"){
    cli_ext_status_msg()
  }else{
    return(ext_lst)
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

  return_type <- match.arg(
    return_type
    ,choices = c("msg","ext","arg")
  )

  validate_duckdb_con(.con)

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

  if(all(ext_lst$success_ext %in% extension_names)){

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
install_extensions <- function(.con,extension_names,silent_msg=TRUE){

  # extension_names <- c("excel")
  # silent_msg <- TRUE

  assertthat::assert_that(is.logical(silent_msg),msg = "silent_msg must be TRUE or FALSE")

  validate_duckdb_con(.con)

  valid_ext_vec <- list_extensions(.con) |>
    dplyr::pull(extension_name)

 ext_lst <- list()

 ext_lst$invalid_ext <-  extension_names[!extension_names%in%valid_ext_vec ]

 ext_lst$valid_ext <- extension_names[extension_names%in%valid_ext_vec ]

  # install packages

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
if(!silent_msg){
  cli_ext_status_msg()
}

}


#' @title Validate Mother Duck Connection Status
#' @name validate_connection_status
#'
#' @param .con connection
#' @param return_type return message or logical value of connection status
#'
#' @returns confirmation or warning message
#' @export
#'
#' @examples
#' con <- DBI::dbConnect(duckdb::duckdb())
#' validate_connection_status(con)
validate_connection_status <- function(.con,return_type="msg"){

  # return_type <- "arg"
  return_type <- match.arg(
    return_type
    ,choices = c("msg","arg")
  )
  validate_duckdb_con(.con)

  dbExectue_safe <- purrr::safely(DBI::dbExecute)

  out <- dbExectue_safe(.con, "PRAGMA md_connect")

  status_lst <- list()

  if(stringr::str_detect(out$error$message,"Error: already connected")==TRUE){

    status_lst$msg <-  \(x) cli::cli_alert_success("You are connected to MotherDuck")
    status_lst$arg <- TRUE

    }else{

      status_lst$msg <-\(x) cli::cli_alert_warning("You are not connected to MotherDuck")
      status_lst$arg <- FALSE

    }

  if(return_type=="msg"){

    return(status_lst$msg())

  }else{

    return(status_lst$arg)

  }

}

#' Create connection to motherduck
#'
#' @param motherduck_token motherduck token saved in your environment file
#' @description
#' creates a DuckDB connection, installs and loads the motherduck extension and finally
#' executes  `DBI::dbExecute(con, "PRAGMA MD_CONNECT")` to connect to motherduck through your
#' motherduck token
#'
#' @returns connection
#' @export
#'
connect_to_motherduck <- function(motherduck_token){

    # motherduck_token="MOTHERDUCK_TOKEN"

    # pull your token from your R environment page

    motherduck_token <- Sys.getenv(motherduck_token)

    cli_msg <- function() {
      cli::cli_par()
      cli::cli_h1("Motherduck token status")
      cli::cli_ul()
      cli::cli_li("Enter the variable name that matches the MotherDuck token variable assigned in your {.file ~/.Renviron}.")
      cli::cli_li("In {.url https://www.motherduck.com}, goto 'Settings' > 'Integrations' and click 'Access Tokens' to create a new token")
      cli::cli_li("Use {.fn usethis::edit_r_environ} to open and edit your {.file ~/.Renviron} file.")
      cli::cli_li("Enter {.code MOTHERDUCK_TOKEN = ...} in your {.file ~/.Renviron} file and save")
      cli::cli_li("Pass {.envvar MOTHERDUCK_TOKEN} to {.fn connect_to_motherduck}")
      cli::cli_end()
      cli::cli_par()
      cli::cli_end()
    }

    assertthat::assert_that(
      motherduck_token!=""
      ,msg=cli_msg()
      )

    .con <-pool::dbPool(duckdb::duckdb(dbdir = tempfile()),...=list(motherduck_token=motherduck_token))

    # if(!validate_extension_install_status(.con,"motherduck",return_type="arg")){

      install_extensions(.con,"motherduck")

    # }



    # connect to motherduck

    # if(!validate_connection_status(.con,return_type = "arg")){


    DBI::dbExecute(.con, "PRAGMA MD_CONNECT")

    # }

      return(.con)

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

  validate_duckdb_con(.con)
  validate_connection_status(.con)

  DBI::dbGetQuery(.con, 'PRAGMA print_md_token;')

}

#' Overwrite or append tibble to motherduck database
#'
#' @param .data tibble
#' @param .con duckdb connection
#' @param database_name name of database
#' @param schema_name name of schema
#' @param table_name name of table
#' @param write_type overwrite or append
#'
#' @returns nothing
#' @export
create_or_replace_database <- function(.data,.con,database_name,schema_name,table_name,write_type="overwrite"){


    # motherduck_token <- Sys.getenv(motherduck_token)
    #
    # if(!DBI::dbIsValid(con)){
    #
    #   con <- DBI::dbConnect(duckdb::duckdb(),":mem:",list(motherduck_token=motherduck_token))
    #
    # }

    # DBI::dbExecute(con, "LOAD 'motherduck';")



    # check that existing has loaded correctly
  validate_duckdb_con(.con)

  validate_connection_status(.con,return_type = "arg")

    # database_name <- "tsa"
    create_db_query <- paste0("CREATE DATABASE IF NOT EXISTS ",database_name)
    use_db_query <- paste0("USE ",database_name,"; ")


    # schema_name <- "main"

    create_schema_query <- paste0(use_db_query,"CREATE SCHEMA IF NOT EXISTS ",schema_name,";")
    use_schema_query <- paste0("USE ",schema_name,";")



    create_table_query <- paste0(use_db_query,use_schema_query)

    # create database

    DBI::dbExecute(.con,create_db_query)
    DBI::dbExecute(.con,create_schema_query)
    DBI::dbExecute(.con,create_table_query)


    #add upload date

   out <-  .data |>
      dplyr::mutate(
        upload_date=Sys.Date()
        ,upload_time=format(Sys.time(), "%H:%M:%S")
      )
   # upload data



    # type <- "append"
    write_type_vec <- match.arg(write_type,c("overwrite","append"))

    if(write_type_vec=="overwrite"){

        DBI::dbWriteTable(.con,table_name,out,overwrite=TRUE)

    message("succesfully upload query")

    }

    if(write_type_vec=="append"){

        DBI::dbWriteTable(.con,table_name,out,append=TRUE)

    message("succesfully upload query")

    }

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

  validate_duckdb_con(.con)

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
read_httpfs <- function(.con,file_path){

  validate_duckdb_con(.con)

  validate_connection_status(.con)

.con <- con
  DBI::dbGetQuery(
    .con,
    paste0(
    "INSTALL httpfs;
     LOAD httpfs;

     SELECT *
     FROM read_csv_auto('",file_path,"');"
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

  validate_duckdb_con(.con)
  validate_connection_status(.con)

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

  validate_duckdb_con(.con)

  out <- DBI::dbGetQuery(.con,"select current_database();") |>
    tibble::as_tibble(.name_repair = janitor::make_clean_names)

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
#' @examples
cd <- function(.con,database){

  validate_duckdb_con(.con)

  database_valid_vec <- lsd(.con) |>
    pull(name)

  if(database %in% database_valid_vec){

    DBI::dbExecute(.con,glue::glue("USE {database};"))

    current_database_vec <- pwd(.con) |>
      pull(current_database)

    cli::cli_text("Current database: {.pkg {current_database_vec}}")

  }else{

    cli::cli_abort("
                   {.pkg {database}} is not valid,
                   Use {.fn lsd} to list valid databases:
                   {.or {database_valid_vec}}
                   ")
  }

}


#' List database functions
#'
#' @param .con connection
#'
#' @returns
#' @export
#'
#' @examples
#' con <- DBI::dbConnect(duckdb::duckdb())
#' list_db_fns(con)
list_db_fns <- function(.con){


  out    <- DBI::dbGetQuery(
    .con
    ," SELECT *
        FROM duckdb_functions()
        ORDER BY function_name;"
  ) |>
    as_tibble()
}


summarise <- function(x, ...) {
  UseMethod("summarise")
}

#' Summarize for DBI objects
#'
#' @param .data dbi object
#'
#' @returns DBI object
#' @export
#'
summarise.tbl_lazy <- function(.data){

  con <- dbplyr::remote_con(.data)
  query <- dbplyr::remote_query(.data)
  summary_query <- paste0("summarize (",query,")")

  out <- tbl(con,sql(summary_query))
  return(out)
}


ls <- function(x, ...) {
  UseMethod("ls")
}


#' list database objects
#'
#' @param .con connection
#'
#' @returns tibble
#' @export
#'
#' @examples
#' #' con <- DBI::dbConnect(duckdb::duckdb())
#' list_db_fns(con)
ls.Pool <- function(.con){

  validate_duckdb_con(.con)

  out <- suppressWarnings(
    DBI::dbGetQuery(.con,"PRAGMA database_list;") |>
      tibble::as_tibble(.name_repair = janitor::make_clean_names)
  )

  return(out)

}






utils::globalVariables(c("con", "extension_name", "installed", "loaded"))
