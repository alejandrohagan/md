
#' @title Validate connection is DuckDB
#' @name validate_con
#' @description
#' Validates that your connection object is a DuckDB connection
#'
#' @param .con connection
#
#' @returns logical value or error message
#'
#' @examples
#' con <- DBI::dbConnect(duckdb::duckdb())
#' validate_duckdb_con(con)
validate_con <- function(.con){

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
#' install_extensions(con,'motherduck',silent_msg=TRUE)
#'
load_extensions <- function(.con,extension_names){

  # extension_names <- c("fts")
  # silent_msg <- TRUE
  # .con

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
  # if(!silent_msg){
    cli_ext_status_msg()
  # }

}



#' @title Validate Mother Duck Connection Status
#' @name validate_md_connection_status
#'
#' @param .con connection
#' @param return_type return message or logical value of connection status
#'
#' @returns confirmation or warning message
#' @export
#'
#' @examples
#' con <- DBI::dbConnect(duckdb::duckdb())
#' validate_md_connection_status(con)
validate_md_connection_status <- function(.con,return_type="msg"){

  # return_type <- "msg"
  return_type <- rlang::arg_match(
    return_type
    ,values  = c("msg","arg")
  )

  validate_con(.con)

  dbExectue_safe <- purrr::safely(DBI::dbExecute)

  out <- dbExectue_safe(.con, "PRAGMA MD_CONNECT")

  status_lst <- list()

  if(any(stringr::str_detect(out$error$message,"Error: already connected")==TRUE)){

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

    motherduck_token_code <- Sys.getenv(motherduck_token)

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

    .con <-DBI::dbConnect(
      duckdb::duckdb(
        dbdir = tempfile()
        ,config=list(
          allow_unsigned_extensions = 'true'
          ,allow_extensions_metadata_mismatch='true'
          ,allow_unredacted_secrets='true'
          )
      )
      # ,...=list(motherduck_token=motherduck_token_code)
    )

    if(!validate_extension_load_status(.con,"motherduck",return_type="arg")){

      load_extensions(.con,"motherduck")

    }

    # connect to motherduck

    dbExectue_safe <- purrr::safely(DBI::dbExecute)

    dbExectue_safe(.con, "PRAGMA MD_CONNECT")

    validate_md_connection_status(.con,return_type = "msg")

#
#     reg.finalizer(.con, function(.con) {
#       cli::cli("Finalizer: closing DBI connection")
#       DBI::dbDisconnect(.con)
#     }, onexit = TRUE)
#


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

  validate_con(.con)
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
  validate_con(.con)

  validate_md_connection_status(.con,return_type = "arg")

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
      ) |>
     tibble::as_tibble()
   # upload data



    # type <- "append"
    write_type_vec <- rlang::arg_match(write_type,values=c("overwrite","append"))

    if(write_type_vec=="overwrite"){

        DBI::dbWriteTable(conn = .con,name = table_name,value = out,overwrite=TRUE)

    cli::cli_alert_info("succesfully upload query")

    }

    if(write_type_vec=="append"){

        DBI::dbWriteTable(conn = .con,name = table_name,value = out,append=TRUE)

      cli::cli_alert_info("succesfully upload query")

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

  database_valid_vec <- list_database(.con) |>
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

  schema_valid_vec <- list_schema(.con) |>
    dplyr::pull(table_schema)




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
list_database<- function(.con){



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
list_schema<- function(.con){



  assertthat::assert_that(
    validate_con(.con)
  )

  assertthat::assert_that(
    validate_md_connection_status(.con,return_type = "arg")
  )


    schema_dbi <-
      dplyr::tbl(
        .con
        ,dplyr::sql("
          SELECT DISTINCT
          table_catalog
          ,table_schema
          FROM  information_schema.tables
          WHERE
          TRUE
          AND table_catalog = current_database()
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
#' lmd(con,type='database')
list_table<- function(.con){


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


#' Title
#'
#' @param .con
#' @param from_db_name
#' @param to_db_name
#'
#' @returns
#' @export
#'
#' @examples
upload_database_to_md <- function(.con,from_db_name,to_db_name){

  DBI::dbExecute(
    .con
    ,dplyr::sql(
      paste0(
        "CREATE DATABASE",to_db_name,";","COPY FROM DATABASE ",from_db_name,"TO ",to_db_name,";"
      )
    )
  )

}




#' Title
#'
#' @param .con
#'
#' @returns
#' @export
#'
#' @examples
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


create_share <- function(.con,database_name,share_name,access,visibility,update){


  cd(.con,database = database_name)

  out <-  DBI::dbGetQuery(

    validate_md_connection_status(.con)
    ,paste0(
      "USE ",database_name,";"
      ,"CREATE OR REPLACE SHARE;"
    )
  )

  # CREATE SHARE birds_share FROM birds (
    # ACCESS RESTRICTED,  -- Only the share owner has initial access
    # VISIBILITY HIDDEN,    -- Not listed; requires direct URL access
    # UPDATE AUTOMATIC      -- Automatically updates with source DB changes
  # );

  # -- If ducks_share exists, it will be replaced with a new share.
  # --A new share URL is returned.
  # CREATE OR REPLACE SHARE ducks_share;

  # -- If ducks_share exists, nothing is done. Its existing share URL is returned.
  # --Otherwise, a new share is created and its share URL is returned.
  # CREATE SHARE IF NOT EXISTS ducks_share;


  return(out)

}


list_shares <- function(.con){

  out <- DBI::dbGetQuery(
    .con
    ,"LIST SHARES;"
  ) |>
    tibble::as_tibble()

  return(out)

}

utils::globalVariables(c("con", "extension_name", "installed", "loaded"))
