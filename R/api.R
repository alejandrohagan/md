
#' @title Show current user
#' @name show_current_user
#' @param motherduck_token motherduck token
#'
#' @param return msg or arg
#'
#'
#' @returns tibble or print statement
#' @export
#'

show_current_user <- function(.con,motherduck_token="MOTHERDUCK_TOKEN",return="msg"){

    return_valid_vec <- c("msg","arg")

    rlang::arg_match(
        return
        ,values = c("msg","arg")
        ,multiple = FALSE
        ,error_arg ="return"
    )

    if(missing(.con)){

   .con<-  suppressMessages(connect_to_motherduck(motherduck_token))

    }

    current_user_tbl <- DBI::dbGetQuery(.con,"select current_user") |>
    tibble::as_tibble()

    if(return=="msg"){

    cli::cli_alert("FYI Your current user name is {cli::col_br_red(current_user_tbl$current_user)}")

    }

    if(return=="arg"){

    return(current_user_tbl)

    }

}

#' @title Check resp status and tidy output to a tibble
#' @name check_resp_status_and_tidy_response
#' @param resp response code
#' @param json_response response object
#' @param column_name1 first column of name of response object
#' @param column_name2 second column of name of response object
#'
#' @returns tibble
#'
check_resp_status_and_tidy_response <- function(resp,json_response,column_name1,column_name2){


    # column_name1="test1"
    # column_name2="test2"
    print(resp)

    if (all(resp$status_code == 200)){

        # If the 'accounts' field in the response is empty, return the whole JSON response
        if (all(json_response |> pluck(1) |> length()==0)) {

            return(json_response)
        }

        # Otherwise, transform the response into a tibble with two columns:

        out <- json_response |>
            unlist() |>  # Flatten the list
            utils::stack() |>  # Convert to data frame
            tibble::as_tibble() |>  # Convert to tibble
            dplyr::select(
                !!column_name1:= ind,
                !!column_name2:= values
            )

        # Return the formatted output
        return(out)
    }

}


#' @title Validate if motherduck token in environment file
#' @name validate_motherduck_token_env
#' @param motherduck_token your motherduck token
#'
#' @returns character vector
#'
validate_motherduck_token_env <- function(motherduck_token="MOTHERDUCK_TOKEN"){

    assertthat::assert_that(
        is.character(motherduck_token)
    )

    motherduck_token_env <- Sys.getenv(motherduck_token)


    # If the environment variable is not empty, override 'motherduck_token' with its value
    if (!nchar(motherduck_token_env) == 0) {
        motherduck_token = motherduck_token_env
    }

    return(motherduck_token)
}



#' @title List active motherduck accounts
#' @name list_md_active_accounts
#' @param motherduck_token admin user's token
#'
#' @returns tibble
#' @export
#'
list_md_active_accounts <- function(motherduck_token="MOTHERDUCK_TOKEN"){

    # https://motherduck.com/docs/sql-reference/rest-api/ducklings-get-duckling-config-for-user/

    motherduck_token_env=validate_motherduck_token_env(motherduck_token)

    show_current_user(motherduck_token = motherduck_token)

    # Make a GET request to the MotherDuck API to retrieve active accounts
    resp <- httr2::request("https://api.motherduck.com/v1/active_accounts") |>
        httr2::req_headers(
            "Accept" = "application/json",  # Request JSON response
            "Authorization" = paste("Bearer", motherduck_token_env)  # Add auth token to header
        ) |>
        httr2::req_error(is_error = function(resp) FALSE) |>
        httr2::req_perform()  # Perform the HTTP request

    # Parse the JSON response body
    json_response <- httr2::resp_body_json(resp)

    out <- check_resp_status_and_tidy_response(
        resp = resp
        ,json_response = json_response
        ,column_name1 = "account_settings"
        ,column_name2 = "account_values"
        )


    return(out)
}




#' @title List a motherduck user's tokens
#' @name list_md_user_tokens
#' @param .con duckdb connection
#' @param user_name motherduck user name
#' @param motherduck_token motherduck token or environment nick name
#'
#' @returns tibble
#' @export
#'
list_md_user_tokens <- function(user_name,motherduck_token="MOTHERDUCK_TOKEN"){


    #https://motherduck.com/docs/sql-reference/rest-api/users-list-tokens/

    # test
    # user_name="alejandro_hagan"
    # motherduck_token="MOTHERDUCK_TOKEN"

    show_current_user(user_name = user_name,motherduck_token = motherduck_token)

    motherduck_token <- validate_motherduck_token_env(motherduck_token)

    resp <- httr2::request(paste0("https://api.motherduck.com/v1/users/",user_name,"/tokens")) |>
        httr2::req_headers(
            "Accept" = "application/json",
            "Authorization" = paste("Bearer",motherduck_token)
        ) |>
        httr2::req_error(is_error = function(resp) FALSE) |>
        httr2::req_perform()

    # Parse the response JSON
    json_response <- resp_body_json(resp)

    out <- check_resp_status_and_tidy_response(resp,json_response,column_name1 = "token_settings",column_name2="token_values")

    return(out)

}


#' @title List motherduck user's instance settings
#' @name list_md_user_instance
#' @param user_name mother duck user name
#' @param motherduck_token admin's motherduck user's instance
#'
#' @returns tibble
#' @export
#'
list_md_user_instance <- function(user_name,motherduck_token="MOTHERDUCK_TOKEN"){

    #https://motherduck.com/docs/sql-reference/rest-api/ducklings-get-duckling-config-for-user/

    # user_name <- "alejandro_hagan"
    motherduck_token_env <- validate_motherduck_token_env(motherduck_token)

    show_current_user(motherduck_token_env)

    resp <- httr2::request(paste0("https://api.motherduck.com/v1/users/",user_name, "/instances")) |>
        httr2::req_headers(
            "Accept" = "application/json",
            "Authorization" = paste("Bearer", motherduck_token)
        ) |>
        httr2::req_error(is_error = function(resp) FALSE) |>
        httr2::req_perform()

    # Parse JSON response
    json_response <- httr2::resp_body_json(resp)

    out <- check_resp_status_and_tidy_response(resp = resp,json_response = json_response,column_name1 = "instance_desc",column_name2 = "instance_values")

    return(out)

}

#' @title Delete a motherduck user
#' @name delete_md_user
#' @param user_name motherduck user name
#' @param motherduck_token motherduck token or environment variable
#'
#' @returns tibble
#' @export
#'
delete_md_user <- function(user_name,motherduck_token) {

    #https://motherduck.com/docs/sql-reference/rest-api/users-delete/

    # user_name <- "alejandro_hagan_contoso_01"
    # motherduck_token <- "MOTERHDUCK_TOKEN"

    motherduck_token_env=validate_motherduck_token_env(motherduck_token)

    show_current_user(motherduck_token = motherduck_token_env,return = "msg")


    # Build and send the DELETE request
    resp <- httr2::request(paste0("https://api.motherduck.com/v1/users/",user_name)) |>
        httr2::req_method("DELETE") |>
        httr2::req_headers(
            Accept = "application/json",
            Authorization = paste("Bearer", motherduck_token_env)
        ) |>
        httr2::req_error(is_error = function(resp) FALSE) |>
        httr2::req_perform()

    # Parse the response
    json_response <-  httr2::resp_body_json(resp)

    out <- check_resp_status_and_tidy_response(
        resp = resp
        ,json_response =json_response
        ,column_name1 = "username"
        ,column_name2 = "value"
    )

    return(out)
}




#' @title Create a new motherduck token
#' @name create_md_user
#'
#' @param user_name new motherduck user name
#' @param motherduck_token admin user's token
#'
#' @returns tibble
#' @export
#'
create_md_user <- function(user_name,motherduck_token="MOTHERDUCK_TOKEN"){
    # user_name <- c("test_20250913")

    assertthat::assert_that(
        length(user_name)==1
        ,all(is.character(user_name))
    )


    # Replace <token> with your actual Bearer token
    motherduck_token_env <- validate_motherduck_token_env(motherduck_token)

    show_current_user(motherduck_token = motherduck_token,return = "msg")


    # validate_and_show_current_user(user_name = user_name,motherduck_token = motherduck_token,return = "msg")

    # Create the request
    resp <- httr2::request("https://api.motherduck.com/v1/users") |>
        httr2::req_method("POST") |>   # Since -d is used, this is a POST request
        httr2::req_headers(
            "Content-Type" = "application/json",
            "Accept" = "application/json",
            "Authorization" = paste("Bearer", motherduck_token_env)
        ) |>
        httr2::req_body_json(list(
            username = user_name
        )) |>
        httr2::req_error(is_error = function(resp) FALSE) |>
        httr2::req_perform()


    # Parse the response
    json_response <-  httr2::resp_body_json(resp)

    out <- check_resp_status_and_tidy_response(
        resp = resp
        ,json_response =json_response
        ,column_name1 = "username"
        ,column_name2 = "value"
        )

    return(out)

}


#' @title Create a motherduck access token
#' @name  create_md_access_token
#' @param user_name new users name
#' @param token_type the token type
#' @param token_name the token name
#' @param token_expiration_number the token expiration number - minimum 300 seconds
#' @param token_expiration_unit the token expiration unit (`seconds`,`minutes`,`days`,`weeks`,`months`,`years`,`never`)
#' @param motherduck_token admin user's token
#'
#' @returns tibble
#' @export
#'
create_md_access_token <- function(user_name,token_type,token_name,token_expiration_number,token_expiration_unit,motherduck_token="MOTHERDUCK_TOKEN"){

    # test inputs
    # user_name <- "alejandro_hagan"
    # token_type <- "read_write"
    # token_expiration_number=300
    # token_expiration_unit="second"
    # token_name <- "temp"

    valid_token_type_vec <- c("read_write", "read_scaling")


    rlang::arg_match(
        token_type
        ,valid_token_type_vec
        ,multiple = FALSE
        ,error_arg = cli::format_error("Please select {.or {valid_token_type_vec}} instead of {token_type}")
    )

    seconds_vec <- convert_to_seconds(number = token_expiration_number,units = token_expiration_unit)

    # Replace these with your actual values
    validate_motherduck_token_env <- validate_motherduck_token_env(motherduck_token="MOTHERDUCK_TOKEN")

    assertthat::assert_that(
        is.character(user_name)
        ,is.character(token_name)
    )

    active_accounts_tbl <- list_md_active_accounts(motherduck_token = motherduck_token)


    # account_values_vec <- active_accounts_tbl |>
    #     dplyr::filter(
    #         account_settings=="accounts.username"
    #     ) |> pull(account_values)
    #
    #
    # assertthat::assert_that(
    #     any(user_name %in% account_values_vec)
    # )

    # Construct the URL
    url <- paste0("https://api.motherduck.com/v1/users/",user_name,"/tokens")

    # Create and send the request
    resp <- httr2::request(url) |>
        httr2::req_method("POST") |>
        httr2::req_headers(
            "Content-Type" = "application/json",
            "Accept" = "application/json",
            "Authorization" = paste("Bearer",validate_motherduck_token_env)
        ) |>
        httr2::req_body_json(
            list(
                ttl = seconds_vec
                ,name = token_name
                ,token_type = token_type
                )
            ) |>
        httr2::req_error(is_error = function(resp) FALSE) |>
        httr2::req_perform()

    # Parse the JSON response
    json_response <- resp_body_json(resp)

    out <- check_resp_status_and_tidy_response(
        resp = resp
        ,json_response =json_response
        ,column_name1 = "username"
        ,column_name2 = "value"
    )


    return(out)


}

#' @title Delete MD user's access token
#' @name delete_md_access_token
#' @param user_name motherduck user name
#' @param token_name motherduck token name
#' @param motherduck_token admin user's token
#'
#' @returns tibble
#' @export
#'
delete_md_access_token <- function(user_name,token_name,motherduck_token="MOTHERDUCK_TOKEN"){

    motherduck_token_env <- validate_motherduck_token_env(motherduck_token)

    url <- paste0("https://api.motherduck.com/v1/users/", user_name, "/tokens/", motherduck_token_env)

    # Create the request
    resp <- httr2::request(url) |>
        httr2::req_method("DELETE") |>
        httr2::req_headers(
            "Accept" = "application/json",
            "Authorization" = paste("Bearer", motherduck_token_env)
        ) |>
        httr2::req_error(is_error = function(resp) FALSE) |>  # Optional: prevent automatic errors
        httr2::req_perform()

    json_response <- resp_body_json(resp)

    out <- check_resp_status_and_tidy_response(
        resp = resp
        ,json_response =json_response
        ,column_name1 = "username"
        ,column_name2 = "value"
    )

}


#' @title Configure motherduck user's settings
#' @name configure_md_user_settings
#' @param user_name motherduck user name
#' @param motherduck_token user's access token
#' @param token_type the to be token type
#' @param instance_size the to be instance size
#' @param flock_size the to be flock size
#'
#' @returns tibble
#' @export
#'
configure_md_user_settings <- function(
        user_name
        ,motherduck_token="MOTHERDUCK_TOKEN"
        ,token_type="read_write"
        ,instance_size="pulse"
        ,flock_size=0
        ){

    assertthat::assert_that(
        is.character(user_name)
        ,is.numeric(flock_size)
    )


    token_type_vec <- validate_token_type(token_type)

    motherduck_token_env <- validate_motherduck_token_env(motherduck_token)

    # URL
    url <- paste0("https://api.motherduck.com/v1/users/", user_name, "/instances")

    # Request body
    body <- list(
        config = list(
            token_type_vec = list(
                instance_size =instance_size
            )
        )
    )

    # Make the PUT request
    resp <- httr2::request(url) |>
        httr2::req_method("PUT") |>
        httr2::req_headers(
            "Content-Type" = "application/json",
            "Accept" = "application/json",
            "Authorization" = paste("Bearer", motherduck_token_env)
        ) |>
        httr2::req_body_json(body) |>
        httr2::req_error(is_error = function(resp) FALSE) |>  # Optional: handle errors manually
        httr2::req_perform()


    json_response <- resp_body_json(resp)

    out <- check_resp_status_and_tidy_response(
        resp = resp
        ,json_response =json_response
        ,column_name1 = "username"
        ,column_name2 = "value"
    )
}

#' @title Convert units to seconds
#' @name convert_to_seconds
#' @param number numeriv value
#' @param units second, minute, day, month, year or never
#'
#' @returns number
#'
#' @examples
#' \dontrun{
#' convert_to_seconds(300,"days")
#' }
convert_to_seconds <- function(number,units){

    # units <- "day"
    # number <- 100

    valid_units <- c("seconds","second","minutes","minute","days","day","months","month","years","year","never")

    units <- tolower(units)

    assertthat::assert_that(
        length(units)==1
        ,length(number)==1
        ,is.character(units)
        ,is.numeric(number)
    )

    unit_vec <- rlang::arg_match(
        ,arg=units
        ,values = valid_units
        ,multiple = TRUE
    )


    conversion_factors_vec = c(
        "second"= 1,
        "seconds"=1,
        "minute"= 60,
        "minutes"=60,
        "day"= 86400,
        "days"= 86400,
        "month"= 2592000,
        "months"= 2592000,
        "year"= 31536000,
        "years"= 31536000
    )

    if(unit_vec=="never"){
        out <- NA
        return(out)
    }

   seconds <-  conversion_factors_vec[unit_vec]*number
   out <- unname(seconds)

   return(out)

}


#' @title Validate MD token type args
#' @name validate_token_type
#' @param token_type character vector either read_write or read_scaling
#'
#' @returns vector
#'
validate_token_type <- function(token_type){

    valid_token_type_vec <- c("read_write", "read_scaling")


    token_type_vec <- rlang::arg_match(
        token_type
        ,valid_token_type_vec
        ,multiple = FALSE
        ,error_arg = "token_type"
    )

    return(token_type_vec)



}

#' @title Validate instance size args
#' @name validate_instance_size
#' @param instance_size select either "pulse", "standard", "jumbo", "mega", "giga"
#'
#' @returns character vector
#'
validate_instance_size <- function(instance_size){

    valid_instance_size <- c("pulse", "standard", "jumbo", "mega", "giga")

    instance_size_vec <- rlang::arg_match(
        tolower(instance_size)
        ,valid_instance_size
        ,multiple = FALSE
        ,error_arg = "instance_size"
    )

    return(instance_size_vec)

}



#' @title Validate flock size args
#' @name validate_flock_size
#' @param flock_size whole number between 0-60
#'
#' @returns integer
#'
validate_flock_size <- function(flock_size){

    valid_flock_size <- 0:60

    flock_size_int <- as_integer(flock_size)

    assertthat::assert_that(
        length(flock_size_int)==1
        ,is.integer(flock_size_int)
        ,flock_size_int %in% valid_flock_size
        ,env = cli::cli_abort("Enter a single whole number between 0-60. You entered {flock_size}")
    )


    return(flock_size_int)

}



#' @@title Create or replace a motherduck share
#'
#' @param .con md connection
#' @param share_name shame name
#' @param database_name database name to be shared
#' @param access either "RESTRICTED" or "PUBLIC"
#' @param visibility either "HIDDEN"or  "LISTED"
#' @param update either "AUTOMATIC" or "MANUAL"
#'
#' @returns message
#' @export
#'
create_or_replace_share <- function(.con,
                                    share_name,
                                    database_name,
                                    access        =  "PUBLIC",
                                    visibility    = "LISTED",
                                    update        =  "AUTOMATIC") {
    # Validate arguments

    valid_access_vec = c("RESTRICTED", "PUBLIC")
    valid_visibility_vec = c("HIDDEN", "LISTED")
    valid_update_vec = c("AUTOMATIC", "MANUAL")

    assertthat::assert_that(
        is.character(share_name)
        ,is.character(database_name)
    )

    rlang::arg_match(
        access
        ,values = valid_access_vec
        ,multiple = FALSE
        ,error_arg = "access"
    )

    rlang::arg_match(
        visibility
        ,values = valid_visibility_vec
        ,multiple = FALSE
        ,error_arg = "visibility"
    )


    rlang::arg_match(
        update
        ,values = valid_visibility_vec
        ,multiple = FALSE
        ,error_arg = "update"
    )


    # Build SQL statement
    query <- glue::glue("
    CREATE OR REPLACE SHARE {share_name} FROM {database_name} (
      ACCESS {access},
      VISIBILITY {visibility},
      UPDATE {update}
    );
  ")

    show_current_user(.con=.con)
    # Execute query
    DBI::dbExecute(.con, query)
}



#' Create a MD share of a database
#' @name create_if_not_exists_share
#' @param .con MD connection
#' @param share_name new share name
#' @param database_name target database
#' @param access "RESTRICTED" or "PUBLIC"
#' @param visibility "HIDDEN" or "LISTED"
#' @param update "AUTOMATIC" or "MANUAL"
#'
#' @returns message
#' @export
#'
create_if_not_exists_share <- function(.con,
                         share_name,
                         database_name,
                         access        =  "PUBLIC",
                         visibility    = "LISTED",
                         update        =  "AUTOMATIC") {
    # Validate arguments

    valid_access_vec = c("RESTRICTED", "PUBLIC")
    valid_visibility_vec = c("HIDDEN", "LISTED")
    valid_update_vec = c("AUTOMATIC", "MANUAL")

    assertthat::assert_that(
        is.character(share_name)
        ,is.character(database_name)
    )

    rlang::arg_match(
        access
        ,values = valid_access_vec
        ,multiple = FALSE
        ,error_arg = "access"
    )

    rlang::arg_match(
        visibility
        ,values = valid_visibility_vec
        ,multiple = FALSE
        ,error_arg = "visibility"
    )


    rlang::arg_match(
        update
        ,values = valid_visibility_vec
        ,multiple = FALSE
        ,error_arg = "update"
    )

    validate_md_connection_status(.con,return_type = "arg")

    # Build SQL statement
   DBI::dbExecute(
   .con
   ,glue::glue_sql("
    CREATE IF NOT EXISTS {share_name} FROM {database_name} (
      ACCESS {access},
      VISIBILITY {visibility},
      UPDATE {update}
    );",.con=.con)
    )

    show_current_user(.con=.con)

}






#' @title Describe share
#' @name describe_share
#' @param .con connection
#' @param share_path shared path name
#'
#' @returns tibble
#' @export
#'
describe_share <- function(.con, share_path) {

    assertthat::asserthat(
        is.character(share_name)
    )


    # Build and run the query
    out <-DBI::dbGetQuery(.con,glue::glue_sql("SELECT * FROM md_describe_database_share('{share_path}');",.con=.con)) |>
      tibble::as_tibble()

    # Return the result as a data frame
    return(out)
}



#' @title Drop a MD share name
#' @name drop_share
#'
#' @param .con MD connection
#' @param share_name Share name
#'
#' @returns message
#' @export
#'
drop_share <- function(.con, share_name) {

  # .con <- con_md
  # share_name <- "test"
    #validate inputs
    md::validate_md_connection_status(.con,return_type = "arg")

    assertthat::assert_that(
        is.character(share_name)
    )

    # Sanitize share_name by wrapping with double quotes
    share_name_quoted <- DBI::dbQuoteIdentifier(.con, share_name)

    suppressWarnings(
    valid_share_name <- unique(md::list_shares(.con)$name)
    )

    if(any(share_name %in% valid_share_name)){

    DBI::dbExecute(.con,glue::glue_sql("DROP SHARE IF EXISTS {share_name_quoted};",.con=.con))

    }else{

      cli::cli_alert_warning("There is no share named {share_name}")

    }

    show_current_user(.con)

}


#' @title List all owned shares
#' @name list_owned_shares
#' @param .con motherduck connection
#'
#' @returns tibble
#' @export
#'
list_owned_shares <- function(.con) {

    DBI::dbGetQuery(.con, "LIST SHARES;") |>
        tibble::as_tibble()
}

#' @title List all shares that are shared with you
#' @name list_shared_with_me_shares
#' @param .con motherduck connection
#'
#' @returns tibble
#' @export
#'
list_shared_with_me_shares <- function(.con) {

    DBI::dbGetQuery(.con, "select * from MD_INFORMATION_SCHEMA.SHARED_WITH_ME;") |>
        tibble::as_tibble()
}

