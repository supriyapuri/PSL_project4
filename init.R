my_packages = c("pkgdown", "ragg","devtools", "DT","Matrix","shiny","tidytable","proxy","recommenderlab","reshape2","shinyjs","data.table","dplyr","shinyWidgets","tidyverse","reticulate","DT","data.table")

install_if_missing = function(p) {
  if (p %in% rownames(installed.packages()) == FALSE) {
    install.packages(p, dependencies = TRUE)
  }
}

invisible(sapply(my_packages, install_if_missing))


devtools::install_github("stefanwilhelm/ShinyRatingInput")



