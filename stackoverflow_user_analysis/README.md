Stack Overflow User Analysis
================
Yifu Yan
2018年6-26

Project Description
-------------------

Notice
------

Executable Rmd file is saved in [README.Rmd](README.Rmd), which is used to create this report. Seperate sql file is saved in [stack\_overflow\_query.sql](stack_overflow_query.sql).

``` r
knitr::opts_chunk$set(echo = FALSE)
library(bigrquery) # to use bigquery api 
library(tidyverse) 
library(lubridate)
source("multiplot.R") # to concatenate graphs
project <- "machinelearning-196501"
```

1.
--

![](README_files/figure-markdown_github/unnamed-chunk-2-1.png)

2. Users' monthly Year over Year increase
-----------------------------------------

![](README_files/figure-markdown_github/unnamed-chunk-4-1.png)

3. Stack Overflow Active User Analysis
--------------------------------------

![](README_files/figure-markdown_github/unnamed-chunk-6-1.png)

4. User Status
--------------

Following Analysis display how how many users have what types of activities.

![df](stackoverflow_user_flag.PNG)
