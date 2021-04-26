library(data.table)
pkg <- "SPARSEMODr"
u <- paste0("https://cran.r-project.org/src/contrib/Archive/", pkg)
html <- readLines(u)
release.dt <- nc::capture_all_str(
  html, date="[0-9]{4}-[0-9]{2}-[0-9]{2}", as.POSIXct)
first.release <- release.dt[1, as.Date(date)]

yesterday <- as.Date(Sys.time()-60*60*24)
all_days <- seq(first.release, yesterday, by = 'day')
all_days_dt <- data.table(
  Date=all_days,
  counts.csv=file.path("figure-SPARSEMOD-logs-data", paste0(all_days, "-counts.csv")))
todo_days_dt <- all_days_dt[!file.exists(counts.csv)]
for(day.i in seq_along(todo_days_dt[["Date"]])){
  todo_days_row <- todo_days_dt[day.i]
  date <- todo_days_row[["Date"]]
  csv.gz <- paste0(date, ".csv.gz")
  f <- file.path("figure-SPARSEMOD-logs-data", csv.gz)
  if(!file.exists(f)){
    dir.create(dirname(f), showWarnings=FALSE, recursive=TRUE)
    year <- strftime(date, "%Y")
    log.url <- paste0("http://cran-logs.rstudio.com/", year, "/", csv.gz)
    download.file(log.url, f)
  }
  hits.dt <- data.table::fread(f)
  counts.dt <- hits.dt[, .(
    downloads.per.day=.N
  ), by=package]
  data.table::fwrite(counts.dt, todo_days_row[["counts.csv"]])
}

