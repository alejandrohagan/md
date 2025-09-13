
#' @title Show current user
#' @name show_current_user
#'
#' @param .con duckdb/md connectoin
#'
#' @returns tibble
#' @export
#'

show_current_user <- function(motherduck_token="MOTHERDUCK_TOKEN",return="msg"){


    return_valid_vec <- c("msg","arg")

    rlang::arg_match(
        return
        ,values = c("msg","arg")
        ,multiple = FALSE
        ,error_arg ="return"
    )

    # motherduck_token_env=validate_motherduck_token_env(motherduck_token)

   .con<-  suppressMessages(connect_to_motherduck(motherduck_token))

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
#' @returns
#'
#' @examples
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


#' Validate if motherduck token in Environment file
#'
#' @param motherduck_token
#'
#' @returns character vector
#'
#' @examples
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




#' Title
#'
#' @param motherduck_token
#'
#' @returns list
#' @export
#'
list_md_active_accounts <- function(motherduck_token="MOTHERDUCK_TOKEN"){

    # https://motherduck.com/docs/sql-reference/rest-api/ducklings-get-duckling-config-for-user/

    # Ensure that 'motherduck_token' is a character string
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

    out <- check_resp_status_and_tidy_response(resp,json_response,column_name1 = "account_settings",column_name2 = "account_values")


    return(out)
}




#' Title
#'
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





#' Title
#'
#' @param user_name mother duck user name
#' @param motherduck_token mother duck token or environment name
#'
#' @returns
#' @export
#'
#' @examples
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

#' Title
#'
#' @param user_name motherduck user name
#' @param motherduck_token motherduck token or environment variable
#'
#' @returns
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




#' Title
#'
#' @param user_name
#' @param motherduck_token
#'
#' @returns
#' @export
#'
#' @examples
create_md_user <- function(user_name,motherduck_token="MOTHERDUCK_TOKEN"){
    # user_name <- "testq_20250909"

    assertthat::assert_that(
        is.character(user_name)
    )


    # Replace <token> with your actual Bearer token
    motherduck_token_env=validate_motherduck_token_env(motherduck_token)

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


#' Title
#'
#' @param user_name
#' @param token_type
#' @param token_name
#' @param token_expiration_number
#' @param token_expiration_unit
#' @param motherduck_token
#'
#' @returns
#' @export
#'
#' @examples
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

#' Title
#'
#' @param user_name
#' @param token_name
#' @param motherduck_token
#'
#' @returns
#' @export
#'
#' @examples
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


#' Title
#'
#' @param user_name
#' @param motherduck_token
#' @param token_type
#' @param instance_size
#' @param flock_size
#'
#' @returns
#' @export
#'
#' @examples
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

#' Title
#'
#' @param number
#' @param units
#'
#' @returns
#' @export
#'
#' @examples
convert_to_seconds <- function(number,units){

    # units <- "day"
    # number <- 100

    valid_units <- c("second","minute","day","month","year","never")

    units <- tolower(units)

    assertthat::assert_that(
        all(is.character(units))
        ,all(is.numeric(number))
    )

    unit_vec <- rlang::arg_match(
        ,arg=units
        ,values = valid_units
        ,multiple = TRUE
    )


    conversion_factors_vec = c(
        "second"= 1,
        "minute"= 60,
        "day"= 86400,
        "month"= 2592000,
        "year"= 31536000
    )

    if(unit_vec=="never"){
        out <- NA
        return(out)
    }

   seconds <-  conversion_factors_vec[unit_vec]*number
   out <- unname(seconds)

   return(out)

}


#' @tile Validate MD token type input
#' @name validate_token_type
#' @param token_type character vector either read_write or read_scaling
#'
#' @returns
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
