library(DEoptimR)
library(parallel)
library(foreach)
library(doParallel)

set.seed(1234)

load("work.Rdata")

theta <- c()
theta$par <- t0

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
  return(out)
}

consElasticNet <- function(par) { 
  c(sum(par^2) - 5, sum(abs(par)) - 10)  
}

nIter <- length((winSize+1):nrow(wDF))

cl <- makeCluster(nIter)
registerDoParallel(cl, cores = nIter)

out = foreach(t = (winSize+1):nrow(wDF), .packages = c("DEoptimR"), .combine = rbind) %dopar% {
  try({
    dft <- df[(t-winSize):(t-1),]
    set.seed(1234)
    theta <- JDEoptim(rep(-1.2, nCat), rep(1.2, nCat), fn=meanUOptim, constr=consElasticNet, maxiter=200) #, trace = TRUE, triter = 1) 
    return(theta$par)
  })
}
stopCluster(cl)

write.csv(file="outElasticNetFinal.csv", x=out, row.names=FALSE)

# Clear the wDF dataframe 
wDF[,3:ncol(wDF)] <- 0

# Write the thetas to wDF
for(t in (1:(nrow(df)-winSize)) ) { 
  wDF[(t+winSize),(3:(length(theta$par)+2))] <- out[t,]
}


# Compute PPP weights, returns and utilities
wDF$rPPP <- wDF$u <- 0
for(t in (winSize+1):nrow(df)) { 
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
for(t in (winSize+1):nrow(df)) { 
  wDF$PPP[t] <- (1 + wDF$rPPP[t])*wDF$PPP[(t-1)]
}


## The 1/N portfolio
# compute the 1/N return
wDF$rOneN <- 0
for(t in (winSize+1):nrow(df)) { 
  # The vector of countries in period t
  ctryT <- c()
  # Loop over the countries
  for ( c in seq(4, (ncol(df)-length(ctry)), (nCat+2) )  ) {
    # Only for currencies in period t
    if(df[t,c] != 0) { 
      ctryT <- c(ctryT, colnames(df)[(c-1)])  
    }
  }
  
  # The vector of returns
  returnT <- c()
  
  # Loop over the countries
  for ( c in seq(4, (ncol(df)-length(ctry)), (nCat+2) )  ) {
    if(colnames(df)[(c-1)] %in% ctryT) { 
      returnT <- c(returnT, df[t,colnames(df)[c]])
    }
  }
  
  wDF$rOneN[t] <- mean(returnT)
}

# Compute the 1/N cumulative return
wDF$OneN <- 1
for(t in (winSize+1):nrow(df)) { 
  wDF$OneN[t] <- (1 + wDF$rOneN[t])*wDF$OneN[(t-1)]
}

#### EDIT THE FILE NAME ####
write.csv(file="PPPElasticNetFinal.csv", x=wDF, row.names=FALSE)



