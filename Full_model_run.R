library(dplyr)
library(ggplot2)
library(recommenderlab)
library(DT)
library(data.table)
library(reshape2)
library(recommenderlab)
library(Matrix)
library(tidytable)
library(knitr)
library(parallel)
library(foreach)
library(doParallel)

set.seed(5234)

url = "https://liangfgithub.github.io/MovieData/"
ratings = read.csv(paste0(url, 'ratings.dat?raw=true'), 
                   sep = ':',
                   colClasses = c('integer', 'NULL'), 
                   header = FALSE)
colnames(ratings) = c('UserID', 'MovieID', 'Rating', 'Timestamp')

movies = readLines(paste0(url, 'movies.dat?raw=true'))
movies = strsplit(movies, split = "::", fixed = TRUE, useBytes = TRUE)
movies = matrix(unlist(movies), ncol = 3, byrow = TRUE)
movies = data.frame(movies, stringsAsFactors = FALSE)
colnames(movies) = c('MovieID', 'Title', 'Genres')
movies$MovieID = as.integer(movies$MovieID)

# convert accented characters
movies$Title[73]
movies$Title = iconv(movies$Title, "latin1", "UTF-8")
movies$Title[73]

# extract year
movies$Year = as.numeric(unlist(
  lapply(movies$Title, function(x) substr(x, nchar(x)-4, nchar(x)-1))))

users = read.csv(paste0(url, 'users.dat?raw=true'),
                 sep = ':', header = FALSE)
users = users[, -c(2,4,6,8)] # skip columns
colnames(users) = c('UserID', 'Gender', 'Age', 'Occupation', 'Zip-code')



# recommnder system

numcores = detectCores()
registerDoParallel((numcores-1))



# avg_popular
system.time({
  lkl = foreach(i=1:10, .combine=rbind) %dopar% {
    
    train.id = sample(nrow(ratings), floor(nrow(ratings)) * 0.8)
    train = ratings[train.id, ]
    test = ratings[-train.id, ]
    
    i = paste0('u', train$UserID)
    j = paste0('m', train$MovieID)
    x = train$Rating
    tmp = data.frame(i, j, x, stringsAsFactors = T)
    Rmat = sparseMatrix(as.integer(tmp$i), as.integer(tmp$j), x = tmp$x)
    rownames(Rmat) = levels(tmp$i)
    colnames(Rmat) = levels(tmp$j)
    Rmat = new('realRatingMatrix', data = Rmat)
    
    rec_POPULAR = Recommender(Rmat, method = 'POPULAR',
                              parameter = list(normalize = 'center'))
    
    POPULAR_recom = predict(rec_POPULAR, 
                            Rmat, type = 'ratingMatrix')
    recom_mat <- as(Rmat, "matrix")
    AVG_POPULAR_recom = colMeans(recom_mat,na.rm=TRUE)
    POPULAR_test.pred = test
    POPULAR_test.pred$rating = NA
    
    # For all lines in test file, one by one
    for (u in 1:nrow(test)){
      
      # Read userid and movieid from columns 2 and 3 of test data
      movieid = paste("m",as.character(test$MovieID[u]), sep ="" )
      
      # handle missing values; replace with weighted average of original user rating distribution of 3.61
      POPULAR_test.pred$rating[u] = ifelse(movieid %in% names(AVG_POPULAR_recom), AVG_POPULAR_recom[[movieid]], 3.61) 
    }
    
    # Calculate RMSE
    sqrt(mean((test$Rating - POPULAR_test.pred$rating)^2)) 
  }
})




#hybrid
system.time({
  hybrid_rmses = foreach(i=1:10, .combine=rbind) %dopar% {
    
    train.id = sample(nrow(ratings), floor(nrow(ratings)) * 0.8)
    train = ratings[train.id, ]
    test = ratings[-train.id, ]
    
    i = paste0('u', train$UserID)
    j = paste0('m', train$MovieID)
    x = train$Rating
    tmp = data.frame(i, j, x, stringsAsFactors = T)
    Rmat = sparseMatrix(as.integer(tmp$i), as.integer(tmp$j), x = tmp$x)
    rownames(Rmat) = levels(tmp$i)
    colnames(Rmat) = levels(tmp$j)
    Rmat = new('realRatingMatrix', data = Rmat)
    
    rec_HYBRID = HybridRecommender(
      Recommender(Rmat, method = "POPULAR"),
      Recommender(Rmat, method = "RANDOM"),
      Recommender(Rmat, method = "RERECOMMEND"),
      weights = c(.6, .2, .2)
    )
    
    HYBRID_recom = predict(rec_HYBRID, 
                           Rmat, type = 'ratings')
    
    HYBRID_rec_list = as(HYBRID_recom, 'list')  # each element are ratings of that user
    
    
    HYBRID_test.pred = test
    HYBRID_test.pred$rating = NA
    
    # For all lines in test file, one by one
    for (u in 1:nrow(test)){
      
      # Read userid and movieid from columns 2 and 3 of test data
      userid = as.integer(test$UserID[u])
      movieid = as.integer(test$MovieID[u])
      
      rating = HYBRID_rec_list[[userid]][movieid]
      # handle missing values; replace with weighted average of original user rating distribution of 3.61
      HYBRID_test.pred$rating[u] = ifelse(is.na(rating), 3.61, rating)
    }
    
    # Calculate RMSE
    HYBRID_RMSE = sqrt(mean((test$Rating - HYBRID_test.pred$rating)^2)) 
    HYBRID_RMSE
  }
})


#UBCF


system.time({
  ucbf_rmses = foreach(i=1:10, .combine=rbind) %dopar% {
    
    train.id = sample(nrow(ratings), floor(nrow(ratings)) * 0.8)
    train = ratings[train.id, ]
    test = ratings[-train.id, ]
    
    i = paste0('u', train$UserID)
    j = paste0('m', train$MovieID)
    x = train$Rating
    tmp = data.frame(i, j, x, stringsAsFactors = T)
    Rmat = sparseMatrix(as.integer(tmp$i), as.integer(tmp$j), x = tmp$x)
    rownames(Rmat) = levels(tmp$i)
    colnames(Rmat) = levels(tmp$j)
    Rmat = new('realRatingMatrix', data = Rmat)
    
    rec_UBCF = Recommender(Rmat, method = 'UBCF',
                           parameter = list(normalize = 'Z-score', 
                                            method = 'Cosine', 
                                            nn = 25))
    
    UBCF_recom = predict(rec_UBCF, 
                         Rmat, type = 'ratings')  
    UBCF_rec_list = as(UBCF_recom, 'list')  # each element are ratings of that user
    
    UBCF_test.pred = test
    UBCF_test.pred$rating = NA
    
    # For all lines in test file, one by one
    for (u in 1:nrow(test)){
      
      # Read userid and movieid from columns 2 and 3 of test data
      userid = as.integer(test$UserID[u])
      movieid = as.integer(test$MovieID[u])
      
      rating = UBCF_rec_list[[userid]][movieid]
      # handle missing values; replace with weighted average of original user rating distribution of 3.61
      UBCF_test.pred$rating[u] = ifelse(is.na(rating), 3.61, rating)
    }
    
    # Calculate RMSE
    UBCF_RMSE = sqrt(mean((test$Rating - UBCF_test.pred$rating)^2)) 
    UBCF_RMSE
  }
})


#IBCF

system.time({
  icbf_rmses = foreach(i=1:10, .combine=rbind) %dopar% {
    
    train.id = sample(nrow(ratings), floor(nrow(ratings)) * 0.8)
    train = ratings[train.id, ]
    test = ratings[-train.id, ]
    
    i = paste0('u', train$UserID)
    j = paste0('m', train$MovieID)
    x = train$Rating
    tmp = data.frame(i, j, x, stringsAsFactors = T)
    Rmat = sparseMatrix(as.integer(tmp$i), as.integer(tmp$j), x = tmp$x)
    rownames(Rmat) = levels(tmp$i)
    colnames(Rmat) = levels(tmp$j)
    Rmat = new('realRatingMatrix', data = Rmat)
    
    rec_IBCF = Recommender(Rmat, method = 'IBCF',
                           parameter = list(normalize = 'Z-score', 
                                            method = 'Cosine'))
    
    IBCF_recom = predict(rec_IBCF, 
                         Rmat, type = 'ratings')  
    IBCF_rec_list = as(IBCF_recom, 'list')  # each element are ratings of that user
    
    IBCF_test.pred = test
    IBCF_test.pred$rating = NA
    
    for (u in 1:nrow(test)){
      
      # Read userid and movieid from columns 2 and 3 of test data
      userid = as.integer(test$UserID[u])
      movieid = as.integer(test$MovieID[u])
      
      rating = IBCF_rec_list[[userid]][movieid]
      # handle missing values; replace with weighted average of original user rating distribution of 3.61
      IBCF_test.pred$rating[u] = ifelse(is.na(rating), 3.61, rating)
    }
    
    # Calculate RMSE
    IBCF_RMSE = sqrt(mean((test$Rating - IBCF_test.pred$rating)^2))
    IBCF_RMSE
  }
})



stopImplicitCluster()



results = data.frame("System I: Avg Popular" = popular_rmses, "System I: Hybrid" = hybrid_rmses, "System II: UBCF"= ucbf_rmses, "System II: IBCF"= icbf_rmses)

kable(results)

