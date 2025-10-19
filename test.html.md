---
title: "test"
format: html
---

## Quarto

Quarto enables you to weave together content and executable code into a finished document. To learn more about Quarto see <https://quarto.org>.

## Running Code

When you click the **Render** button a document will be generated that includes both content and the output of embedded code. You can embed code like this:


::: {.cell}

```{.r .cell-code}
library(tidyverse)
library(md)
```
:::



::: {.cell}

```{.r .cell-code}
con_md <- md::connect_to_motherduck()
```

::: {.cell-output .cell-output-stderr}

```

```


:::

::: {.cell-output .cell-output-stderr}

```
── Extension Load & Install Report ─────────────────────────────────────────────
```


:::

::: {.cell-output .cell-output-stderr}

```
Installed and loaded 1 extension: motherduck
```


:::

::: {.cell-output .cell-output-stderr}

```

```


:::

::: {.cell-output .cell-output-stderr}

```
Use `list_extensions()` to list extensions, status and their descriptions
```


:::

::: {.cell-output .cell-output-stderr}

```
Use `install_extensions()` to install new duckdb extensions
```


:::

::: {.cell-output .cell-output-stderr}

```
See <https://duckdb.org/docs/stable/extensions/overview.html> for more
information
```


:::

::: {.cell-output .cell-output-stderr}

```

```


:::

::: {.cell-output .cell-output-stderr}

```
── Connection Status Report: ──
```


:::

::: {.cell-output .cell-output-stderr}

```

```


:::

::: {.cell-output .cell-output-stderr}

```
✔ You are connected to MotherDuck
```


:::
:::




::: {.cell}

```{.r .cell-code}
ggplot2::diamonds 
```

::: {.cell-output .cell-output-stdout}

```
# A tibble: 53,940 × 10
   carat cut       color clarity depth table price     x     y     z
   <dbl> <ord>     <ord> <ord>   <dbl> <dbl> <int> <dbl> <dbl> <dbl>
 1  0.23 Ideal     E     SI2      61.5    55   326  3.95  3.98  2.43
 2  0.21 Premium   E     SI1      59.8    61   326  3.89  3.84  2.31
 3  0.23 Good      E     VS1      56.9    65   327  4.05  4.07  2.31
 4  0.29 Premium   I     VS2      62.4    58   334  4.2   4.23  2.63
 5  0.31 Good      J     SI2      63.3    58   335  4.34  4.35  2.75
 6  0.24 Very Good J     VVS2     62.8    57   336  3.94  3.96  2.48
 7  0.24 Very Good I     VVS1     62.3    57   336  3.95  3.98  2.47
 8  0.26 Very Good H     SI1      61.9    55   337  4.07  4.11  2.53
 9  0.22 Fair      E     VS2      65.1    61   337  3.87  3.78  2.49
10  0.23 Very Good H     VS1      59.4    61   338  4     4.05  2.39
# ℹ 53,930 more rows
```


:::
:::



::: {.cell}

```{.r .cell-code}
    # Validate the connection (assume this is a custom function)
.data <- ggplot2::diamonds

.con <- con_md

database_name <- "vignette"
schema_name <- "raw"
table_name <- "diamonds"
write_type="overwrite"

    # Validate write_type
    write_type <- rlang::arg_match(write_type,values = c("overwrite","append"))

    # Validate the connection (assume this is a custom function)

    md_con_indicator <- validate_md_connection_status(.con,return_type="arg")

    if(rlang::is_missing(database_name)){
      database_name <- pwd(.con) |> pull(current_database)
    }

    if(rlang::is_missing(schema_name)){
      schema_name <- pwd(.con) |> pull(current_schema)
    }

      Sys.sleep(1)
      
    # if(md_con_indicator){
        
        # Create and connect to the database
        # DBI::dbExecute(.con, glue::glue_sql("CREATE DATABASE IF NOT EXISTS {database_name};", .con = .con))
        
        Sys.sleep(1)
        
        # DBI::dbExecute(.con, glue::glue_sql("USE {`database_name`};", .con = .con))

    # }
 Sys.sleep(1)
    # Create schema
    # DBI::dbExecute(.con, glue::glue_sql("CREATE SCHEMA IF NOT EXISTS {`schema_name`};", .con = .con))
    Sys.sleep(1)
    # DBI::dbExecute(.con, glue::glue_sql("USE {`schema_name`};", .con = .con))

    # DBI::dbExecute(.con, glue::glue_sql("CREATE TABLE IF NOT EXISTS {`table_name`}", .con = .con))

    # Add audit fields
    # out <- .data |>
    #     dplyr::mutate(
    #         upload_date = Sys.Date(),
    #         upload_time = format(Sys.time(), "%H:%M:%S  %Z",tz = Sys.timezone())
    #     )
    # 
    # # Use DBI::Id to ensure schema is used explicitly
    # 
    # if(!md_con_indicator){
    # 
    #     database_name <- pwd(.con)$current_database
    # }

    # table_id <- DBI::Id(database=database_name,schema = schema_name, table = table_name)
    # table_id <- DBI::Id(table = table_name)
    # 
    # # Write table
    # if (write_type == "overwrite") {
    #     
    # # 
    #     DBI::dbWriteTable(.con, name = table_id, value = out, overwrite = TRUE)
    #     # DBI::dbWriteTable(.con, name = "vignette.raw.diamonds", value = out, overwrite = TRUE)
    # # 
    # } else if (write_type == "append") {
    # # 
    #     DBI::dbWriteTable(.con, name = table_id, value = out, append = TRUE)
    # # 
    # }
    # 
```
:::




::: {.cell}

```{.r .cell-code}
ggplot2::diamonds |>  #<1>
    md::create_table(
        .con = con_md #<2>
        ,database_name = "vignette" #<3>
        ,schema_name = "raw" #<4>
        ,table_name = "diamonds" #<5>
        ,write_type="overwrite"  #<6>
        )

DBI::dbDisconnect(con_md, shutdown = TRUE)
```
:::





::: {.cell}

```{.r .cell-code}
library(DBI)
# Create in-memory DuckDB connection
.con <- dbConnect(duckdb::duckdb(), dbdir = ":memory:")

# Use built-in diamonds dataset
out <- ggplot2::diamonds

 schema_name <- "raw"
table_name <- "diamonds"

 table_id <- DBI::Id(schema = "raw", table = "diamonds")

    DBI::dbExecute(.con, glue::glue_sql("CREATE SCHEMA IF NOT EXISTS {`schema_name`};", .con = .con))
    Sys.sleep(1)
    DBI::dbExecute(.con, glue::glue_sql("USE {`schema_name`};", .con = .con))

 

# Write the data to DuckDB
dbWriteTable(.con, name = table_id, value = out, overwrite = TRUE)

# Check the table exists and view some data
dbListTables(.con)
tbl(.con,table_id)

# Clean up
dbDisconnect(.con, shutdown = TRUE)
```
:::


