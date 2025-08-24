describe(
    "list_extensions()",{
        it("will return a tibble"
            ,{
               con <- connect_to_motherduck("MOTHERDUCK_TOKEN")
               extension_tbl <-  md::list_extensions(con)
               testthat::expect_s3_class(extension_tbl,"data.frame")
               }
            )
        }
    )

