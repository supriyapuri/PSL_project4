#loading Libraries
library(shiny)
library(proxy)
library(recommenderlab)
library(reshape2)
library(data.table)
library(shinyjs)
library(ShinyRatingInput)

#can support displaying more than 1 genre filter. 
numberGenres = 1

genrelist = c("Select","Action", "Adventure", "Animation", "Childrens", 
                "Comedy", "Crime","Documentary", "Drama", "Fantasy",
                "Film-Noir", "Horror", "Musical", "Mystery","Romance",
                "Sci-Fi", "Thriller", "War", "Western")

loadRatingData = function() {
  ratingsData = read.csv('ratings.dat', sep = ':', header = FALSE,
                     colClasses = c('integer', 'NULL'))
  colnames(ratingsData) = c('UserID', 'MovieID', 'Rating', 'Timestamp')
  ratingsData
}

loadMovieData = function() {
  moviesData = readLines('movies.dat')
  moviesData = strsplit(moviesData, split = "::", fixed = TRUE, useBytes = TRUE)
  moviesData = matrix(unlist(moviesData), ncol = 3, byrow = TRUE)
  moviesData = data.frame(moviesData, stringsAsFactors = FALSE)
  colnames(moviesData) = c('MovieID', 'Title', 'Genres')
  moviesData$MovieID = as.integer(moviesData$MovieID)
  
  moviesData$Title = iconv(moviesData$Title, "latin1", "UTF-8")
  
  moviesData$Year = as.numeric(unlist(
    lapply(moviesData$Title, function(x) substr(x, nchar(x) - 4, nchar(x) - 1))))
  
  genres = as.data.frame(gsub("'","",moviesData$Genres), stringsAsFactors=FALSE)
  tmp = as.data.frame(tstrsplit(genres[,1], '[|]', type.convert=TRUE),
                      stringsAsFactors=FALSE)

  m = length(genrelist)
  genre = matrix(0, nrow(moviesData), length(genrelist))
  for(i in 1:nrow(tmp)){
    genre[i, genrelist %in% tmp[i,]]=1
  }
  
  colnames(genre) = genrelist
  moviesData = cbind(moviesData, genre)
  moviesData
}

moviesData = loadMovieData()
ratingsData = read.csv("ratings.csv")
moviesData = moviesData[-which((moviesData$MovieID %in% ratingsData$MovieID) == FALSE),]

source("recommendation.R")

formatInput = function(v,a,d){
  c(v,a,d)
}

shinyServer(function(input, output) {
  final_output = reactiveValues()
  
  observeEvent(
    input$recBtn, {
       ratedMovieIds = c()
       ratedMovieIdsRatings = c()
       for(i in randMovieIds$ids) {
         if(input[[paste0("movieId",i)]] != "") {
           ratedMovieIds = c(ratedMovieIds,paste0("movieId",i))
           ratedMovieIdsRatings = c(ratedMovieIdsRatings,input[[paste0("movieId",i)]])
         }
       }
       final_output$rec_ucbf = movie_recom(ratedMovieIds,ratedMovieIdsRatings)
    })
  
  observeEvent(input$addNew, { 
    numberGenres = length(inputGenre$InputGenres) + 1
    inputGenre$InputGenres[[numberGenres]] = 
      selectInput(paste0("input_genre",numberGenres), 
                  paste0("Genre #",numberGenres),
                  genrelist)
  })
  
  observeEvent(input$resetbtn, {
    js$reset_1(0)
  })
  
  #output data to UI
  output$table = renderTable({
    input$recBtn
    if(!is.null(final_output$rec_ucbf)) {
      return(final_output$rec_ucbf)
    } 
  })
  
  #output data to UI
  output$table2 = renderTable({
    numberGenres = length(inputGenre$InputGenres)
    if(numberGenres == 0) return()
    getRec = FALSE
    selectedGenres = c()
    for(i in 1:numberGenres) {
      if( !is.null(input[[paste0("input_genre",i)]]) && 
        input[[paste0("input_genre",i)]] != "Select" ) {
          getRec = TRUE
          selectedGenres = c(selectedGenres,input[[paste0("input_genre",i)]])
      }
    }
    
    if(getRec)
      return (movie_recom_popular(selectedGenres))
    
    return()
  })
  
  inputGenres = list(3)
  for(i in 1:numberGenres) {
    inputGenres[[i]] = selectInput(paste("input_genre",sep = "",i), 
                                   "Select Movie Genre", genrelist)
  }
  
  inputGenre  = reactiveValues( InputGenres = inputGenres)
  
  output$recommenderButton = renderUI({
    wellPanel("Set or View Your Movies Rating ",
              actionButton("recBtn","Set and View Movies Rating"),
              actionButton("resetbtn", "Reset Rating"))
  })
  
  output$renderGenres = renderUI( {
    wellPanel(do.call(fluidRow,inputGenre$InputGenres)
    )})

    randMovieIds = reactiveValues(ids=list())

  output$renderMoviesForRatings = renderUI( {
    if(length(randMovieIds$ids) == 0) {
      randMovieIds$ratingInputList = list()
      ids = list()
      for(i in 1:100) {
        id = sample(1:3600,1)
        ids[[i]] = moviesData[id,]$MovieID
        randMovieIds$ratingInputList[[i]] = 
          column(12,
                ratingInput(
                  paste("movieId",
                        sep="",
                        moviesData_new[id,]$MovieID), 
                        label = moviesData_new[id,]$Title, 
                        dataStop=5))
      }
      randMovieIds$ids = ids
    }

    wellPanel(do.call(fluidRow,randMovieIds$ratingInputList)
    )})
})