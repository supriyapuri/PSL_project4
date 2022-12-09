#loading Libraries
library(shinyWidgets)
library(ShinyRatingInput)
library(shinycssloaders)
library(shinyjs)
library(shiny)
library(dplyr)

jsCode <- "shinyjs.reset_1 = function(params){$('.rating-symbol-foreground').css('width', params);}"

genre_list <- c("Select","Action", "Adventure", "Animation", "Childrens", 
                "Comedy", "Crime","Documentary", "Drama", "Fantasy",
                "Film-Noir", "Horror", "Musical", "Mystery","Romance",
                "Sci-Fi", "Thriller", "War", "Western")

#UI for Webpage
shinyUI(
  fluidPage(
    useShinyjs(),
    extendShinyjs(text = jsCode,functions = "reset_1"),
    tags$head(
      tags$style(
        HTML(".shiny-notification {
                height: 1100px;
                width: 550px;
                position:fixed;
                top: calc(40% - 550px);
                left: calc(40% - 210px);
              }"
            )
      )
    ),
  
  titlePanel(h1("Movies Recommender", align = "center")),
  
  verticalTabsetPanel( id = "tabs", color = "#112446", menuSide = "left",
     verticalTabPanel("Recommender by Genre", box_height = "65px",
        tags$style("body {
                  background: url(https://png.pngtree.com/background/20210710/original/pngtree-film-and-television-festival-grey-atmospheric-movie-element-poster-picture-image_1058645.jpg) 
                  no-repeat center center fixed; 
                  background-size: cover;}"),
        fluidRow(
          column(3,
                 uiOutput("renderGenres"),
          ),
          column(9, 
                 wellPanel(h4("Popular Highest Rating Movies based selected Genre")),
                 wellPanel(tableOutput("table2") %>% withSpinner(color="#0f55c1")) 
          )
        )
     ),        
               
     verticalTabPanel("Recommender by Rating", box_height = "65px",
       tags$style("body {
                  background: url(https://png.pngtree.com/background/20210710/original/pngtree-film-and-television-festival-grey-atmospheric-movie-element-poster-picture-image_1058645.jpg) 
                  no-repeat center center fixed; 
                  background-size: cover; }"),
       fluidRow(
          column(7, 
                 uiOutput("recommenderButton"),
                 uiOutput("renderMoviesForRatings")
                 ),
          
          column(5,
                 wellPanel(h4("Suggested Movies Based on your Rating")),
                 wellPanel(tableOutput("table")  %>% withSpinner(color="#0dc5c1") ))
        )
      )
    )
  )
)
