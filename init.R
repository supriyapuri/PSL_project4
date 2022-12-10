my_packages = c("dplyr","rmarkdown","httpuv","shiny","shinythemes","shinycssloaders","shinyjs","shinyratinginput","dplyr","ggplot2","DT","data.table","reshape2","recommenderlab","Matrix","tidytable","knitr","data.table","tidytable" )

install_if_missing = function(p) {
  if (p %in% rownames(installed.packages()) == FALSE) {
    install.packages(p, dependencies = TRUE)
  }
}

invisible(sapply(my_packages, install_if_missing))


#devtools::install_github("stefanwilhelm/ShinyRatingInput")

#install.packages(c("dplyr","ggplot2","DT","data.table","reshape2","recommenderlab","Matrix","tidytable","knitr","data.table","tidytable"))

#install.packages(c())

