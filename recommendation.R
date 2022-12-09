library(proxy)
library(recommenderlab)
library(reshape2)


load_movie_data = function() {
  movies_data = readLines('movies.dat')
  movies_data = strsplit(movies_data, split = "::", fixed = TRUE, useBytes = TRUE)
  movies_data = matrix(unlist(movies_data), ncol = 3, byrow = TRUE)
  movies_data = data.frame(movies_data, stringsAsFactors = FALSE)
  colnames(movies_data) = c('MovieID', 'Title', 'Genres')
  movies_data$MovieID = as.integer(movies_data$MovieID)
  
  movies_data$Title = iconv(movies_data$Title, "latin1", "UTF-8")
  
  movies_data$Year = as.numeric(unlist(
    lapply(movies_data$Title, function(x) substr(x, nchar(x)-4, nchar(x)-1))))
  
  genres = as.data.frame(gsub("'","",movies_data$Genres), stringsAsFactors=FALSE)
  tmp = as.data.frame(tstrsplit(genres[,1], '[|]',
                                type.convert=TRUE),
                      stringsAsFactors=FALSE)
  
  genrelist = c("Action", "Adventure", "Animation", 
                 "Childrens", "Comedy", "Crime",
                 "Documentary", "Drama", "Fantasy",
                 "Film-Noir", "Horror", "Musical", 
                 "Mystery", "Romance", "Sci-Fi", 
                 "Thriller", "War", "Western")
  
  m = length(genrelist)
  genres = matrix(0, nrow(movies_data), length(genrelist))
  for(i in 1:nrow(tmp)){
    genres[i,genrelist %in% tmp[i,]]=1
  }
  colnames(genres) = genrelist
  movies_data = cbind(movies_data,genres)
  return(movies_data)
}


moviesData = load_movie_data()
ratings = read.csv("ratings.csv", header = TRUE)
moviesData_new = moviesData[-which((moviesData$MovieID %in% ratings$MovieID) == FALSE),]



movie_recom = function(movieRatedIds,movieRatedIdsRatings) {

  selected_movies = which(moviesData_new$MovieID == movieRatedIds)
  
  rating_matrix = dcast(ratings, UserID~MovieID, value.var = "Rating", na.rm=FALSE)
  rating_matrix = rating_matrix[,-1]
  
  userSelect = matrix(NA,ncol(rating_matrix))
  userSelect[selected_movies] = movieRatedIdsRatings
  userSelect = t(userSelect)
  
  
  colnames(userSelect) = colnames(rating_matrix)
  rating_matrix_new = rbind(userSelect,rating_matrix)
  rating_matrix_new = as.matrix(rating_matrix_new)
  
  #Convert rating matrix into a sparse matrix
  rating_matrix_new = as(rating_matrix_new, "realRatingMatrix")
  
  userId = sample(1:6000,1)
  
  #Create Recommender Model. We are using UBCF for recommender filtering here
  recommender_model = Recommender(rating_matrix_new, method = "UBCF",param=list(method="Cosine",nn=5))
  recommender = predict(recommender_model, rating_matrix_new[userId], n=10)
  recom_list = as(recommender, "list")
  no_result = data.frame(matrix(NA,1))
  recom_result = data.frame(matrix(NA,10))
  
  
  if (as.character(recom_list[1])=='character(0)'){
    no_result[1,1] = "There are no similar movie recommendations based on the movie datset selected. Please update your choices!!"
    colnames(no_result) = "No Recommendations"
    return(no_result) 
  } else {
    for (i in c(1:10)){
      recom_result[i,1] = as.character(subset(moviesData, 
                                               moviesData$MovieID == as.integer(recom_list[[1]][i]))$Title)
    }
    colnames(recom_result) = "Movies Data Recommendations based on User based Collaborative filtering"
    return(recom_result)
  }
}

movie_recom_popular = function(selectedGenres) {
  
  rating_matrix = dcast(ratings, UserID~MovieID, value.var = "Rating", na.rm=FALSE)
  rating_matrix = rating_matrix[,-1]
  
  rating_matrix_new = as(as.matrix(rating_matrix), "realRatingMatrix")
  
  recommender_model = Recommender(rating_matrix_new, method = "POPULAR",param = list(normalize = "Z-score"))
  recommender = predict(recommender_model, rating_matrix_new, type="ratings")
  recom_mat = as(recommender, "matrix")
  avg_movie_ratings = cbind(colnames(recom_mat),colMeans(recom_mat,na.rm=TRUE))  # calculate movie avg ratings
  colnames(avg_movie_ratings) = c("MovieID","avg_ratings")
  avg_movie_ratings_df = as.data.frame(avg_movie_ratings)
  avg_movie_ratings_df$avg_ratings=as.numeric(avg_movie_ratings_df$avg_ratings)
  
  moviesData_new_with_rating = merge(moviesData,avg_movie_ratings_df, by = "MovieID")
  
  no_result = data.frame(matrix(NA,1))
  
  returnList = list()
  column_names = c()
  for(input in selectedGenres) {
    tmp = subset(moviesData_new_with_rating,eval(parse(text=paste(input,"== 1"))),select = c('MovieID','Title','avg_ratings'))
    returnList = cbind(returnList, tmp[order(-tmp$avg_ratings),][1:5,]$Title)
    column_names = c(column_names,input)
  }
  
  if (length(returnList) == 0){
    no_result[1,1] = "There are no similar movie recommendations based on the movie datset selected. Please update your choices!!"
    colnames(no_result) = "No Recommendations"
    return(no_result) 
  } else {
    colnames(returnList) = column_names
    return(returnList)
  }
}