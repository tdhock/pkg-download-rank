#after download and conversion,
library(data.table)
library(ggplot2)
counts.dt <- data.table(counts.csv=Sys.glob("figure-SPARSEMOD-logs-data/*-counts.csv"))[, {
  data.table::fread(counts.csv)
}, by=.(date=as.Date(gsub("figure-SPARSEMOD-logs-data/|-counts.csv", "", counts.csv)))]
month.dt <- counts.dt[package != "", .(
  downloads.per.month=sum(downloads.per.day)
), by=.(package, month=sub("-[0-9]{2}$", "", date))]

## set NAs to zero?
counts.wide <- data.table::dcast(
  month.dt, package ~ month, value.var="downloads.per.month")
counts.tall <- data.table::melt(
  counts.wide,
  id.vars="package",
  value.name="downloads.per.month",
  variable.name="month")
counts.tall[is.na(downloads.per.month), downloads.per.month := 0]

## Or not?
counts.tall <- month.dt


counts.tall[, rank := rank(-downloads.per.month), by=month]
counts.tall[, rank.percent := 100*(rank-1)/(.N-1), by=month ]
counts.tall[, pkgs := .N, by=month ]
show.pkgs <- c("SPARSEMODr", "Rcpp", "directlabels")
counts.some <- counts.tall[package %in% show.pkgs]
gg <- ggplot()+
  ggtitle("Distribution of downloads per month over all R packages,
Data from Rstudio CRAN mirror logs")+
  scale_y_log10()+
  geom_histogram(aes(
    y=downloads.per.month),
    data=counts.tall)+
  facet_grid(month ~ ., labeller=label_both)+
  xlab("packages")+
  theme(legend.position="none")+
  geom_hline(aes(
    yintercept=downloads.per.month, color=package),
    data=counts.some)+
  geom_label(aes(
    Inf, downloads.per.month, color=package,
    label=sprintf(
      "%s rank=%.1f%% = %.0f of %d packages",
      package, rank.percent, rank, pkgs)),
    vjust=1,
    hjust=1,
    alpha=0.5,
    data=counts.some)
png("figure-SPARSEMOD-logs.png", width=6, height=10, units="in", res=200)
print(gg)
dev.off()
