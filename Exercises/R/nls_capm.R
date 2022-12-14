#==========================================================================
#
# Robust estimation of the CAPM model
# Monthly excess returns for the company Martin-Marietta adn the value
# weighted CRSP index for the period Jan. 1982 to Dec. 1986 are taken from 
# Butler et. al. Review of Economics and Statistics (1990), Table A1.
#
#=========================================================================

rm (list = ls(all=TRUE))
graphics.off()

#
#--------------------------- Helper Functions -----------------------------------
#

# load required functions - inv
source("EMTSUtil.R")

#----------------------------------------------------------------------
#   Negative log-likelihood function     
#----------------------------------------------------------------------
neglog <- function(b,y,x) {
  logl <- -mean( lnltst(b,y,x) )  
}

#----------------------------------------------------------------------
#   Log-likelihood function for a Student t disturbance     
#----------------------------------------------------------------------
lnltst <- function( b,y,x ){
  u     <- y - (b[1] + b[2]*x)
  s2    <- abs( b[3] )
  gam   <- abs( b[4] )           
  z     <- u/sqrt(s2) 
  const <- gamma( (gam+1)/2 ) / ( sqrt(pi*(gam-2)) * gamma( gam/2 ) )
  loglt <- log(const) - 0.5*log(s2) - 0.5*(gam+1)*log( 1 + (z^2)/(gam-2) )                                                                                                                                                                                        
  return(loglt) 
}
   


#
#--------------------------- CAPM Estimation ------------------------------
#

nls_capm  <- function (){
  # Load and plot the data
  data <- matrix(c(-0.1365, -0.0300,         
               -0.0769, -0.0584,         
               -0.0575, -0.0181,         
               0.0526,  0.0306,         
               -0.0449, -0.0397,         
               -0.0859, -0.0295,         
               -0.0742, -0.0316,         
               0.6879,  0.1176,         
               -0.0770,  0.0075,         
               0.0850,  0.1098,         
               0.0030,  0.0408,         
               0.0754,  0.0095,         
               -0.0412,  0.0301,         
               -0.0890,  0.0221,         
               0.2319,  0.0269,         
               0.1087,  0.0655,         
               0.0375, -0.0030,         
               0.0958,  0.0325,         
               0.0174, -0.0374,         
               -0.0724,  0.0049,         
               0.0750,  0.0105,         
               -0.0588, -0.0257,         
               -0.0620,  0.0186,         
               -0.0378, -0.0155,         
               0.0169, -0.0165,         
               -0.0799, -0.0440,         
               -0.0147,  0.0094,         
               0.0106, -0.0028,         
               -0.0421, -0.0591,         
               -0.0036,  0.0158,         
               0.0876, -0.0238,         
               0.1025,  0.1031,         
               -0.0499, -0.0065,         
               0.1953, -0.0067,         
               -0.0714, -0.0167,         
               0.0469,  0.0188,         
               0.1311,  0.0733,         
               0.0461,  0.0105,         
               -0.0328, -0.0070,         
               -0.0096, -0.0099,         
               0.1272,  0.0521,         
               -0.0077,  0.0117,         
               0.0165, -0.0099,         
               -0.0150, -0.0102,         
               -0.1479, -0.0428,         
               -0.0065,  0.0376,         
               0.0390,  0.0628,         
               0.0223,  0.0391,         
               -0.0690,  0.0002,         
               0.1338,  0.0688,         
               0.1458,  0.0486,         
               0.0063, -0.0174,         
               0.0692,  0.0460,         
               -0.0239,  0.0100,         
               -0.0568, -0.0594,         
               0.0814,  0.0680,         
               -0.0889, -0.0839,         
               -0.0887,  0.0481,         
               0.1037,  0.0136,         
               -0.1163, -0.0322), ncol=2, byrow=T)    

  t <- nrow(data)

  r <- data[,1]
  m <- data[,2]

  figure()
    
  plot(m,r, pch=19, 
       main = "Excess returns: Martin-Marietta and CRSP index", 
       xlab = expression(m[t]),
       ylab = expression(r[t]), 
       bty="l")
       
  # Estimate the model by OLS
  Y <- r
  X <- cbind(rep(1,t),  m)   # Create X matrix by concatenation
    
  bols  <- lm(Y ~ X - 1)$coef
  s2ols <- mean((Y - X %*% bols)^2)
  omols <- s2ols * inv(t(X) %*% X)
  seols <- sqrt(diag(omols)) 
 
  cat('\nOLS Estimates and std errors\n')
  print(cbind(bols, s2ols))  
  cat('\nResidual variance = ', s2ols )
   
  # Wald test of beta2 = 1     
  R <- rbind(c(0,1))
  Q <- 1
  W <- (R %*% bols - Q) %*% inv(R %*% omols %*% t(R)) %*% (R %*% bols - Q)

  cat('\n')
  cat('\nWald statistic and p-value -- OLS')
  cat('\n---------------------------------\n')    
  cat(W,   1-pchisq(W,1))
    
  # Estimate the model by ML
  theta0    <- c(bols, s2ols, 3)
  estResults <- optim(theta0, neglog, y=r, x=m, method= "BFGS", hessian=TRUE)
  bhat <- estResults$par
  H    <- estResults$hessian    
  invH <- inv(H)
     
  cat('\n\nParameter Estimates and Std.Errors (Hessian)')
  cat('\n---------------------------------------------\n')
  sterr <- sqrt( diag( invH/t ) )
  print(cbind(bhat, sterr))


  # Wald test that beta2 = 1  using ML results  
  R <- rbind(c(0,  1,  0,  0))                
  Q <- 1
  W <- t*(R %*% bhat - Q) %*% inv(R %*% H %*% t(R)) %*% (R %*% bhat - Q)

  cat('\n\nWald statistic and p-value -- MLE')
  cat('\n---------------------------------\n')
  cat(W,   1-pchisq(W,1))
}





