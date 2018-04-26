library(caret)
library(DEoptimR)
library(parallel)
library(foreach)
library(doParallel)

set.seed(1234)

load("work.Rdata")

meanUOptim <- function(par) {
  # Add a column of utilities
  dft$u <- 0
  # Loop over every period
  for(t in 1:nrow(dft)) {
    # Define the period-t return
    Rpt <- 0
    # The vector of countries in period t
    ctryT <- c()
    # Loop over the countries
    for ( c in seq(4, (ncol(dft)-length(ctry)), (nCat+2) )  ) {
      # Only for currencies in period t
      if(dft[t,c] != 0) { 
        ctryT <- c(ctryT, colnames(dft)[(c-1)])  
      }
    }
    #Loop over the countries
    for ( c in seq(4, (ncol(dft)-length(ctry)), (nCat+2) )  ) {
      if(colnames(dft)[(c-1)] %in% ctryT) { 
        #Get the weight of country c
        wC <- ( 1/length(ctryT) + ( (1/length(ctryT))*( t(as.matrix(par)) %*% as.numeric(dft[t,c:(c+nCat-1)]) ) ) )
        # Add to the the periot t return with multiplying by period t return
        Rpt <- Rpt + wC*dft[t,c]  
      }
    }
    dft$u[t] <- u(Rpt, gamma)
  }
  out <- -mean(dft$u)
  #print(out)
  return(out)
}

n <- nrow(wDF)
k <- 8

# We already have flds from the work.Rdata image
#flds <- createFolds(1:n, k = k, list = TRUE, returnTrain = FALSE)

# Construct the dataframe of Sharpe Ratios 
LassoFold <- data.frame(d <- seq(5,30,5), SR <- rep(0,6))
colnames(LassoFold) <- c("d", "SR")
rownames(LassoFold) <- LassoFold$d

d <- 15

#for(d in seq(5,30,5)) { 
  print(c(d, "/30")) 
  
  consLasso <- function(par) { 
    c(sum(abs(par)) - d)  
  }
  
  cl <- makeCluster(k)
  registerDoParallel(cl, cores = k)
  
  out = foreach(i = 1:k, .packages = c("DEoptimR"), .combine = rbind) %dopar% {
    try({
      validate <- flds[paste("Fold", i, sep="")] 
      validate <- unlist(validate, use.names=FALSE)
      train <- setdiff(1:n, validate)
      dft <- df[train,]
      
      set.seed(1234)
      theta <- JDEoptim(rep(-1, nCat), rep(1, nCat), fn=meanUOptim, constr=consLasso, maxiter=170) #, trace = TRUE, triter = 1)
      return(theta$par)
    })
  }
  stopCluster(cl)
  
  write.csv(file=paste("out", d, ".csv", sep=""), x=out, row.names=FALSE)
  
  # Clear the wDF dataframe 
  wDF[,3:ncol(wDF)] <- 0
  
  # Write weights to data frame
  for(i in 1:k) { 
    validate <- flds[paste("Fold", i, sep="")] 
    validate <- unlist(validate, use.names=FALSE)
    
    for(t in validate) { 
      wDF[t,(3:(length(theta$par)+2))] <- out[i,]
    }
  }
  
  
  # Compute PPP weights, returns and utilities
  wDF$rPPP <- wDF$u <- 0
  for(t in 1:nrow(wDF)) { 
    # The vector of countries in period t
    ctryT <- c()
    # Loop over the countries
    for ( c in seq(4, (ncol(df)-length(ctry)), (nCat+2) )  ) {
      # Only for currencies in period t
      if(df[t,c] != 0) { 
        ctryT <- c(ctryT, colnames(df)[(c-1)])  
      }
    }
    
    #Loop over the countries
    Rpt <- 0
    for ( c in seq(4, (ncol(df)-length(ctry)), (nCat+2) )  ) {
      if(colnames(df)[(c-1)] %in% ctryT) { 
        #Get the weight of country c
        wDF[t, paste("w",colnames(df)[(c-1)],sep="")] <- ( 1/length(ctryT) + ( (1/length(ctryT))* (t(as.matrix(as.numeric(wDF[t,3:(nCat+2)]))) %*% as.numeric(df[t,c:(c+nCat-1)]))) )
        
        # Add to the the periot t return with multiplying by period t return
        Rpt <- Rpt + as.numeric(wDF[t, paste("w",colnames(df)[(c-1)],sep="")])*df[t,c]     
      }
    }
    
    wDF$rPPP[t] <- Rpt
    wDF$u[t] <- u(Rpt, gamma)
  }
  
  # Compute the PPP cumulative return
  wDF$PPP <- 1
  for(t in 2:nrow(wDF)) { 
    wDF$PPP[t] <- (1 + wDF$rPPP[t])*wDF$PPP[(t-1)]
  }

  write.csv(file=paste("wDF", d, ".csv", sep=""), x=wDF, row.names=FALSE)

  SR <- mean(wDF$rPPP)/sd(wDF$rPPP)
  
  LassoFold[LassoFold$d == d,]$SR <- SR

  write.csv(file=paste("LassoFold", d, ".csv", sep=""), x=LassoFold, row.names=FALSE)

#}

#print("All done writing LassoFold.")
#write.csv(file="LassoFold.csv", x=LassoFold, row.names=FALSE)



