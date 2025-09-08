

#' Title
#'
#' @param .con duckdb connectoin
#'
#' @returns tibble
#' @export
#'

validate_and_show_current_user <- function(motherduck_token,user_name,return="msg"){


    rlang::arg_match(
        return
        ,values = c("msg","arg")
        ,multiple = FALSE
    )

    if(!missing(user_name)){
    assertthat::assert_that(
    is.character(user_name)
    )
    }

    motherduck_token=validate_motherduck_token_env(motherduck_token)

    suppressMessages(
    connect_to_motherduck(motherduck_token)
    )

    current_user_tbl <- DBI::dbGetQuery(.con,"select current_user") |>
    tibble::as_tibble()

    if(return=="msg"){

    cli::cli_alert("FYI Your current user name is {cli::col_br_red(current_user_tbl$current_user)}")

    }

    if(return=="arg"){

    return(current_user_tbl)

    }

}

#' Title
#'
#' @param resp response code
#' @param json_response response object
#' @param column_name1 first column of name of response object
#' @param column_name2 second column of name of response object
#'
#' @returns
#'
#' @examples
check_resp_success_and_tidy_response_to_tbl <- function(resp,json_response,column_name1,column_name2){


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


    # Ensure that 'motherduck_token' is a character string
    motherduck_token=validate_motherduck_token_env(motherduck_token)

    validate_and_show_current_user(motherduck_token = motherduck_token)

    # Make a GET request to the MotherDuck API to retrieve active accounts
    resp <- httr2::request("https://api.motherduck.com/v1/active_accounts") |>
        httr2::req_headers(
            "Accept" = "application/json",  # Request JSON response
            "Authorization" = paste("Bearer", motherduck_token)  # Add auth token to header
        ) |>
        httr2::req_perform()  # Perform the HTTP request

    # Print the raw response object (useful for debugging)

    # Parse the JSON response body
    json_response <- httr2::resp_body_json(resp)




    out <- check_resp_success_and_tidy_response_to_tbl(resp,json_response,column_name1 = "account_settings",column_name2 = "account_values")


    validate_and_show_current_user(motherduck_token = motherduck_token)
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

    # test
    # user_name="alejandro_hagan"
    # motherduck_token="MOTHERDUCK_TOKEN"

    validate_and_show_current_user(user_name = user_name,motherduck_token = motherduck_token)

    motherduck_token <- validate_motherduck_token_env(motherduck_token)

    resp <- httr2::request(paste0("https://api.motherduck.com/v1/users/",user_name,"/tokens")) |>
        httr2::req_headers(
            "Accept" = "application/json",
            "Authorization" = paste("Bearer",motherduck_token)
        ) |>
        httr2::req_perform()

    # Parse the response JSON
    json_response <- resp_body_json(resp)

    out <- check_resp_success_and_tidy_response_to_tbl(resp,json_response,column_name1 = "token_settings",column_name2="token_values")

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


    # user_name <- "alejandro_hagan"
    motherduck_token <- validate_motherduck_token_env(motherduck_token)

    resp <- httr2::request(paste0("https://api.motherduck.com/v1/users/",user_name, "/instances")) |>
        httr2::req_headers(
            "Accept" = "application/json",
            "Authorization" = paste("Bearer", motherduck_token)
        ) |>
        httr2::req_perform()

    # Parse JSON response
    json_response <- httr2::resp_body_json(resp)

    out <- check_resp_success_and_tidy_response_to_tbl(resp = resp,json_response = json_response,column_name1 = "instance_desc",column_name2 = "instance_values")

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

    # user_name <- "alejandro_hagan_contoso_01"
    # motherduck_token <- "MOTERHDUCK_TOKEN"

    validate_and_show_current_user(user_name = user_name,motherduck_token = motherduck_token,return = "msg")

    motherduck_token=validate_motherduck_token_env(motherduck_token)

    # Build and send the DELETE request
    resp <- httr2::request(paste0("https://api.motherduck.com/v1/users/",user_name)) |>
        httr2::req_method("DELETE") |>
        httr2::req_headers(
            Accept = "application/json",
            Authorization = paste("Bearer", motherduck_token)
        ) |>
        httr2::req_perform()
    # Optionally return the response status or body
    return(resp)
}

