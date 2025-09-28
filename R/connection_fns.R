
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

        cli::cli_h2(text="Connection Status Report:")
        return(status_lst$msg())

    }else{

        return(status_lst$arg)

    }

}

#' Create connection to motherduck
#' @name  connect_to_motherduck
#' @param motherduck_token motherduck token saved in your environment file
#' @description
#' creates a DuckDB connection, installs and loads the motherduck extension and finally
#' executes  `DBI::dbExecute(con, "PRAGMA MD_CONNECT")` to connect to motherduck through your
#' motherduck token
#'
#' @returns connection
#' @export
#'
connect_to_motherduck <- function(motherduck_token="MOTHERDUCK_TOKEN",config){

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
        motherduck_token_code!=""
        ,msg=cli_msg()
    )

    if(!missing(config)){

    .con <- DBI::dbConnect(
        duckdb::duckdb(
            dbdir = tempfile()
            ,config=config
        )
    )
    }else{
        .con <-DBI::dbConnect(
            duckdb::duckdb(
                dbdir = tempfile()
            )
        )
    }

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




#' Title
#'
#' @param .con duckdb connection
#'
#' @returns print message
#'
validate_and_print_database_loction <- function(.con){

    file_location <- .con@driver@dbdir

    assertthat::assert_that(
        file.exists(file_location)
        ,msg = cli::format_error("Failed to find file or database at {.file {file_location}}")
    )
    cli::cli_alert_success("created or located a database at {.file {file_location}}")
}
