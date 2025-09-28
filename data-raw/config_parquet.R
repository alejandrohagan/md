## code to prepare `config_parquet` dataset goes here

library(tibble)

config_parquet <- tribble(
    ~name,               ~default,
    "binary_as_string",  "false",
    "encryption_config", "-",
    "filename",          "false",
    "file_row_number",   "false",
    "hive_partitioning", "(auto-detected)",
    "union_by_name",     "false"
)


usethis::use_data(config_parquet, overwrite = TRUE)
