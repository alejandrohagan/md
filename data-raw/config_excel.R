## code to prepare `excel_config` dataset goes here

config_excel <- tibble::tribble(
    ~Option, ~Type, ~Default, ~Description,
    "header", "BOOLEAN", "automatically inferred", "Whether to treat the first row as containing the names of the resulting columns.",
    "sheet", "VARCHAR", "automatically inferred", "The name of the sheet in the xlsx file to read. Default is the first sheet.",
    "all_varchar", "BOOLEAN", "false", "Whether to read all cells as containing VARCHARs.",
    "ignore_errors", "BOOLEAN", "false", "Whether to ignore errors and silently replace cells that cant be cast to the corresponding inferred column type with NULL's.",
    "range", "VARCHAR", "automatically inferred", "The range of cells to read, in spreadsheet notation. For example, A1:B2 reads the cells from A1 to B2. If not specified the resulting range will be inferred as rectangular region of cells between the first row of consecutive non-empty cells and the first empty row spanning the same columns.",
    "stop_at_empty", "BOOLEAN", "automatically inferred", "Whether to stop reading the file when an empty row is encountered. If an explicit range option is provided, this is false by default, otherwise true.",
    "empty_as_varchar", "BOOLEAN", "false", "Whether to treat empty cells as VARCHAR instead of DOUBLE when trying to automatically infer column types."
)



usethis::use_data(config_excel, overwrite = TRUE)
