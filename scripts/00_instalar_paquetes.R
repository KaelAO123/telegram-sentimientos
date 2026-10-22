paquetes <- c(
  "rvest", "xml2", "dplyr", "tidyr", "stringr", "stringi", "purrr",
  "lubridate", "ggplot2", "readr", "scales", "rmarkdown", "knitr",
  "tm", "quanteda", "syuzhet", "SnowballC"
)
faltantes <- paquetes[!vapply(paquetes, requireNamespace, logical(1), quietly = TRUE)]
if (length(faltantes)) install.packages(faltantes, repos = "https://cloud.r-project.org")
message("Paquetes listos.")
