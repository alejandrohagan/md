
library(tidyverse)

qt(.975, df = c(1:10,20,50,100,1000))

pak::pak("gss")
# load in the dataset
data <- contoso::sales

# take a look at its structure
dplyr::glimpse(data)

library(infer)

mean(data$gross_revenue)

x_bar <- data |>
    observe(response = gross_revenue, stat = "mean")

data |>
specify(response = gross_revenue) |>
    hypothesize(null = "point", mu = 0) |>
    generate(reps = 1000) |>
    calculate(stat = "mean") |>
    get_p_value(obs_stat = x_bar, direction = "two-sided")
    visualise() +
    shade_p_value(obs_stat = x_bar, direction = "two-sided")




summary_tbl <- data |>
    mutate(
        year=year(order_date)
        ,month=month(order_date)
    ) |>
    filter(
        year!=2021
    ) |>
    summarize(
        .by=c(year,month)
        ,gross_revenue=sum(gross_revenue)
    ) |>
    arrange(
        year,month
    ) |>
    mutate(
        fy_gross_revenue=sum(gross_revenue,na.rm=TRUE)
        ,cumulative_spend=cumsum(gross_revenue)
        ,run_rate=(cumulative_spend/month)*12
        ,.by = year
    ) |>
    mutate(
        delta=run_rate-fy_gross_revenue
    )



summary_tbl |>
    arrange(gross_revenue) |>
    mutate(
        prop=row_number()/max(row_number())
    ) |>
    ggplot(aes(x=gross_revenue,y=prop))+
    geom_line()


distribution_tbl <- summary_tbl |>
    mutate(
        segment=case_when(
            month<5~1
            ,.default=0
        )
    ) |>
    group_by(segment) |>
    arrange(
        gross_revenue,.by_group = TRUE
    ) |>
    ungroup() |>
    mutate(
        prop=row_number()/max(row_number())
        ,.by=segment
    )


distribution_tbl

#rolling six months
six_month_distribution_tbl <- summary_tbl |>
    timetk::tk_augment_slidify(.value = gross_revenue,.period = 6,.f = \(x) sum(x,na.rm=TRUE),.align = "right") |>
    drop_na() |>
    mutate(
        prop=row_number()/max(row_number())
    )


six_month_distribution_tbl |>
    ggplot(aes(x=gross_revenue_roll_6))+
    geom_histogram(bins=10)



summary_tbl |>
    filter(
        month!=12
    ) |>
    lm(fy_gross_revenue~month+cumulative_spend,data=_) |>
    # broom::tidy() |>
    broom::augment() |>
    mutate(
        # run_rate_delta=fy_gross_revenue-run_rate
    ) |>
    ggplot(
        aes(x=fy_gross_revenue,y=cumulative_spend,col=factor(month))
    )+
    geom_point()+
    geom_abline()
    # facet_wrap(~month)+
    # scale_y_continuous(limits=c(-2e6,2e6))+
    # scale_x_continuous(limits=c(-2e6,2e6))+
    geom_vline(xintercept = 0)+
    geom_hline(yintercept = 0)
