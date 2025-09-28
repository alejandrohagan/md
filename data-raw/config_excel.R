## code to prepare `excel_config` dataset goes here

config_excel <- tribble(
    ~option,            ~default,
    "header",           "automatically inferred",
    "sheet",            "automatically inferred",
    "all_varchar",      "false",
    "ignore_errors",    "false",
    "range",            "automatically inferred",
    "stop_at_empty",    "automatically inferred",
    "empty_as_varchar", "false"
)


usethis::use_data(config_excel, overwrite = TRUE)
