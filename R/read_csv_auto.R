#
#
# this but for excel
#
# readxl::read_excel()
# #make a function for this
#
# read_excel <- function(.con,file_path,column_names,sheet,range,header,skip,na){}
#


#
# col_names_fn <- function(col_names){
#
#     # test input
#     col_names <- c("test_name","test_name2")
#
#     assertthat::assert_that(
#         all(class(col_names) %in% c("logical","character"))
#     )
#
#     lst <- list()
#
#     if(is.logical(col_names)){
#
#         if(col_names){
#             lst$header <- "true"
#         }
#         if(!col_names){
#             lst$header <- "false"
#         }
#     }
#
#     if(is.character(col_names)){
#
#         lst$header <- "false"
#
#         lst$header <- "false"
#
#
#         names_len <- length(col_names)
#         type_vec <- rep('ANY',names_len)
#         names(col_names) <- type_vec
#
#
#
#         lst$column <-  str_flatten_comma(
#             paste0(
#                 "'",col_names,"'",": ","'",names(col_names),"'"
#             )
#         )
#
#         return(lst)
#
#
#     }
#
#
#     skip_fn <- function(skip){
#
#         #test
#         skip=1
#
#         # validate
#         assertthat::assert_that(
#             is.numeric(skip)
#         )
#
#         lst <- list()
#
#         lst$skip <- skip
#
#         return(lst)
#
#     }



#
# t1 <- cols(
#     column_one = col_integer(),
#     column_two = col_number()
# )
#
# dat <- read_csv(fp)
#
# spec(dat)
#
# validate_md_connection_status(.con)
#
# usethis::use_r("read_csv_auto")
#
# ?read_csv(fp,)
# spec(test)
# function(.con,file,col_names,skip,col_types,col_select,id,n_max,guess_max,name_repair,na,show_col_types)
#
#     col_types_fn <- function(col_types){
#
#         col_types <- c("c","c","c","D","i")
#
#         valid_column_types <- c("c","i","n","d","l","f","D","T","t","_","-","?")
#
#         assertthat::assert_that(
#             all(col_types %in% valid_column_types)
#         )
#
#         r_to_duckdb_type_map <- list(
#             "c" = "VARCHAR",    # character
#             "i" = "INTEGER",    # integer
#             "n" = "DECIMAL",    # number (general numeric)
#             "d" = "DOUBLE",     # double
#             "l" = "BOOLEAN",    # logical
#             "f" = "VARCHAR",    # factor (stored as string in DuckDB)
#             "D" = "DATE",       # date
#             "T" = "TIMESTAMP",  # date time
#             "t" = "TIME",       # time
#             "?" = "ANY",      # guess (DuckDB infers type)
#             "_" = "SKIP",     # skip column
#             "-" = "SKIP"      # skip column
#         )
#
#         lst <- list()
#
#         # lst$col_names <-
#
#         unname(r_to_duckdb_type_map[col_types]) |> purrr::list_simplify()
#
#
#
#
#     }
