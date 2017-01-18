#helper function

library(RCurl)
library(chillR)
load('QldLocs.RData')


searchForLocation <- function(location){
  #listOfStns
  these <- grep(location,qldLocs$Name,ignore.case=T)
  if(length(these) > 0 & location != ''){
    return( qldLocs[these,])
  } else {
    return(NULL)
  }

}

getData <- function(stn,uname,pword) {
  sDate <- format(as.Date('1957-1-1'),'%Y%m%d')
  eDate <- format(as.Date(Sys.Date() -1 ),'%Y%m%d')
  theurl <- paste('https://www.longpaddock.qld.gov.au/cgi-bin/silo/PatchedPointDataset.php?format=apsim&station=',stn,'&start=',sDate,'&finish=',eDate,'&username=',uname,'&password=',pword,sep='')

  d <- getURL(theurl)

  info <- strsplit(d,'\n')[[1]]
  hdr <- strsplit(info[22],' +')[[1]]
  data <-info[24:length(info)]

  tab.1 <- read.table(textConnection(data))

  stnNum=strsplit(info[2],"=")[[1]][2]
  stnName=strsplit(info[3],"=")[[1]][2]
  year <- tab.1[,1]
  day <- tab.1[ ,2]
  maxt <- tab.1[,4]
  mint <- tab.1[,5]
  code <- tab.1[,9]
  maxtCode <- as.numeric(substr(code,2,2))
  mintCode <- as.numeric(substr(code,3,3))
  dates<-as.Date(paste(year,day,sep='-'),'%Y-%j')
  df.1 <- data.frame(Date=as.character(format(dates,'%d/%m/%Y')),MaxT=maxt,MinT=mint,MaxTCode=maxtCode,MinTCode=mintCode)
  return(df.1)
}


getChillHours <- function(stn,uname,pword,belowZero,hThresh) {
  sDate <- format(as.Date('1957-1-1'),'%Y%m%d')
  lastYear <- as.numeric(format(as.Date(Sys.Date()),'%Y')) - 1
  eDate <- format(as.Date(paste(lastYear,'-12-31',sep='')),'%Y%m%d')
  theurl <- paste('https://www.longpaddock.qld.gov.au/cgi-bin/silo/PatchedPointDataset.php?format=apsim&station=',stn,'&start=',sDate,'&finish=',eDate,'&username=',uname,'&password=',pword,sep='')
  d <- getURL(theurl)
  hThresh <- as.numeric(hThresh)

  info <- strsplit(d,'\n')[[1]]
  hdr <- strsplit(info[22],' +')[[1]]
  data <-info[24:length(info)]

  tab.1 <- read.table(textConnection(data))

  stnNum <- strsplit(info[2],"=")[[1]][2]
  stnName <- strsplit(info[3],"=")[[1]][2]
  lat <- as.numeric(strsplit(info[4],' ')[[1]][3])
  year <- tab.1[,1]
  day <- tab.1[ ,2]
  maxt <- tab.1[,4]
  mint <- tab.1[,5]
  code <- tab.1[,9]
  maxtCode <- as.numeric(substr(code,2,2))
  mintCode <- as.numeric(substr(code,3,3))

  mths<-as.numeric(format(as.Date(paste(year,day,sep='-'),'%Y-%j'),'%m'))

  chillWeather<-data.frame(year,day,maxt,mint)
  colnames(chillWeather)<-c('Year','JDay','Tmax','Tmin')
  THourly<-make_hourly_temps(lat,chillWeather)
  stack<-stack_hourly_temps(hour_file=THourly)
  if(length(grep('hourtemps',names(stack))) > 0){
    #new chillR
    stackYear <- stack$hourtemps$Year
    stackJDay <- stack$hourtemps$JDay
    stackTemp <- stack$hourtemps$Temp
  } else {
    #old chillr
    stackYear <- stack$Year
    stackJDay <- stack$JDay
    stackTemp <- stack$Temp
  }
  stackMths <- as.numeric(format(as.Date(paste(stackYear,stackJDay,sep='-'),'%Y-%j'),'%m'))
  if(belowZero){

    chdiff <- rep(0,length(stackTemp))
    chdiff[which(stackTemp <= 7.2 )] <- 1
    chMth <- tapply(chdiff,list(stackYear,stackMths),sum)
  } else {
    ch<-chilling_hourtable(stack,1)
    chHours <- ch$Chilling_Hours[ch$Hour == 24]
    chdiff <- c(0,diff(chHours))
    chdiff[chdiff < 0] <- 0 # gets around the problem that the data was cumsum originally and last day of previous year was maximum chill hours

    chMth <- tapply(chdiff,list(year,mths),sum)
  }
  annual <- rowSums(chMth)
  #LTMean <- mean(annual)

  #return(list(chMth=chMth,Annual=annual,meanMonthly=meanMonthly,LTMean=LTMean))

  df.m <- data.frame(chMth)
  nY <- dim(chMth)[1]
  df.m <- cbind(seq(1957,lastYear),df.m,annual)
  df.m <- rbind(df.m,colMeans(df.m))
  colnames(df.m) <- c('Year',month.abb,'Annual Chill Hours')
  df.m[nY+1,1] <-'Average'

  #Hours > threshold

  Heat <- rep(0,length(stackTemp))
  Heat[stackTemp > hThresh] <- 1

  HeatHours <- tapply(Heat,list(stackYear,stackMths),sum)
  annual <- rowSums(HeatHours)
  df.h <- data.frame(HeatHours)
  df.h <- cbind(seq(1957,lastYear),df.h,annual)

  df.h <- rbind(df.h,colMeans(df.h))
  colnames(df.h) <- c('Year',month.abb,'Annual Heat Hours')
  df.h[nY+1,1] <-'Average'

  print(hThresh)
  print(df.h[nY+1,])

  df.a <- cbind(df.m,df.h)


  return(df.a)
}
