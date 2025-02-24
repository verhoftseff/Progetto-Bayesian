#@@@@@@@@@@@@@@@@@@@@##
#SEQUENTIAL MONTECARLO#
#@@@@@@@@@@@@@@@@@@@@##
library(ggplot2)
q025=function(x){quantile(x,0.025)}
q975=function(x){quantile(x,0.975)}


#Generate a random walk plus noise
#---------------------------------
#n = sample dim
#v = obs noise
#w = state noise
#x0 = init state

dlm.sim = function(n,sigma,tau,x0){
  x    = rep(0,n)
  y        = rep(0,n)
  x[1] = rnorm(1,x0,tau)
  y[1] = rnorm(1,x[1],sigma)
  for (t in 2:n){
    x[t] = rnorm(1,x[t-1],tau)
    y[t] = rnorm(1,x[t],sigma)
  }
  return(list(x=x,y=y))
}

#Filtering, using data
#---------------------
#y = observed data

DLM = function(y,sigma2,tau2,m0,C0){
  n = length(y)
  m = rep(0,n)
  C = rep(0,n)
  for (t in 1:n){
    if (t==1){
      a = m0
      R = C0 + tau2
    }else{
      a = m[t-1]
      R = C[t-1] + tau2
    }
    A = R/(R+sigma2)
    m[t] = (1-A)*a + A*y[t]
    C[t] = A*sigma2
  }
  return(list(m=m,C=C))
}


########################################################

#Generate a random walk plus noise
#---------------------------------
n=500
tau2=1
sigma2=1
sigma=sqrt(sigma2)
tau=sqrt(tau2)
x0=0

sim<-dlm.sim(n,sigma,tau,x0)
y<-sim$y
x<-sim$x

#Kalman Filter
#-------------
m0=0
C0=100
filtval<-DLM(y,sigma2,tau2,m0,C0)
m<-filtval$m
C<-filtval$C
Low = m + qnorm(0.025)*sqrt(C)
Up = m + qnorm(0.975)*sqrt(C)

#Put everything in a data frate (for ggplot)
timeframe<-c(1:length(y))
DLM.df<-data.frame(timeframe,y,x,m,C,Low,Up)

#Plots (observetions in black and filtered states in red)
ggplot(DLM.df,aes(x=timeframe))+
  geom_line(aes(y=y))+
  geom_line(aes(y=m),col="red")+
  geom_ribbon(aes(ymin = Low, ymax = Up),
              fill="red",alpha=0.16) +
  labs(x="Time",
       y="")+
  ggtitle("Kalman Filter")+
  theme_bw()+
  theme(plot.title = element_text(hjust = 0.5))

#Sequential Importance Sampling
#------------------------------
#This function produce sequential importance samples
#for Space state model that have linear gaussian state process
#y=data
#N=n°sample produced
#m0,c0,tau and sigma specified as above
#It returns xs,ws and ess which are respectively the filtered states
#the relative weight and the effective sample size for any period.

SISfun<-function(data,N,m0,C0,tau,sigma){
xs<-NULL
ws<-NULL
ess<-NULL
x  = rnorm(N,m0,sqrt(C0))
w  = rep(1/N,N)
for(t in 1:length(data)){
  x    = rnorm(N,x,tau)                   #sample from N(x_{0},tau)
  w    = w*dnorm(data[t],x,sigma)         #update weight
  wnorm= w/sum(w)                         #normalized weight
  ESS  = 1/sum(wnorm^2)                   #effective sample size
  draw = sample(x,size=N,replace=T,prob=wnorm)
  xs = rbind(xs,draw)
  ws = rbind(ws,wnorm)
  ess =rbind(ess,ESS)
}
return(list(xs=xs,ws=ws,ess=ess))
}
#Nota: il SIS così costruito (Chopin-Papastiliopoluos) 
#ha problemi con i pesi infatti wnorm dopo un po di iteraioni 
#è un vettore (0,0,...,0,1) dopodichè da errore

#post-estimation command: plot the filtered states
SISplot<-function(data,sisfun){
  require(ggplot2)
  mx = apply(sisfun$xs,1,median)
  lx = apply(sisfun$xs,1,q025)
  ux = apply(sisfun$xs,1,q975)
  
  timeframe<-c(1:length(data))
  SIS.df<-data.frame(timeframe,data,mx,lx,ux)
  
  ggplot(SIS.df,aes(x=timeframe))+
    geom_line(aes(y=data))+
    geom_line(aes(y=mx),col="red")+
    geom_ribbon(aes(ymin = lx, ymax = ux),
                fill="red",alpha=0.16) +
    labs(x="Time",
         y="")+
    ggtitle("SIS filter")+
    theme_bw()+
    theme(plot.title = element_text(hjust = 0.5))
}



#Sequential Importance Sampling with Resampling
#----------------------------------------------
SISRfun<-function(data,N,m0,C0,tau,sigma){
ws  = NULL
xs  = NULL
ess = NULL
x   = rnorm(N,m0,sqrt(C0))
w   = rep(1/N,N)
for (t in 1:n){
  x1  = rnorm(N,x,tau)
  w   = dnorm(data[t],x1,sigma)
  w   = w/sum(w)
  ESS = 1/sum(w^2)
  x   = sample(x1,size=N,replace=T,prob=w)
  xs  = rbind(xs,x)
  ws  = rbind(ws,w/sum(w))
  ess = c(ess,ESS)
}
return(list(xs=xs,ws=ws,ess=ess))
}
<<<<<<< HEAD
#again a post estimation command
SISRplot<-function(data,sisrfun){
  require(ggplot2)
  mx = apply(sisrfun$xs,1,median)
  lx = apply(sisrfun$xs,1,q025)
  ux = apply(sisrfun$xs,1,q975)
=======

SISplot<-function(data,sisfun){
  require(ggplot2)
  mx = apply(sisfun$xs,1,median)
  lx = apply(sisfun$xs,1,q025)
  ux = apply(sisfun$xs,1,q975)
>>>>>>> 4e397b5a7aea53c54e931b655be750af0c60a703
  
  timeframe<-c(1:length(data))
  SIS.df<-data.frame(timeframe,data,mx,lx,ux)
  
  ggplot(SIS.df,aes(x=timeframe))+
    geom_line(aes(y=data))+
    geom_line(aes(y=mx),col="red")+
    geom_ribbon(aes(ymin = lx, ymax = ux),
                fill="red",alpha=0.16) +
    labs(x="Time",
         y="")+
    ggtitle("SIS filter")+
    theme_bw()+
    theme(plot.title = element_text(hjust = 0.5))
}

