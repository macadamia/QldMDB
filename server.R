
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(oz)
source('helpers.R')

shinyServer(function(input, output) {

  res <- readRDS('extraInfo.rds')

  results <- reactive({
    searchForLocation(input$Location)
  })

  output$stnList <- renderTable({
    results()
  }, include.rownames=FALSE)

  output$QldMap <- renderPlot({
    stnList <- results()
    if(!is.null((stnList))){
      oz(sections=c(3,11,12,13))
      if(dim(stnList)[1] > 0){

        points(stnList$Lng,stnList$Lat,pch=19)
        text(stnList$Lng+1.9,stnList$Lat,stnList$Num,cex=1.2)
      }
    }
  })


  output$downloadData <- downloadHandler(
    filename = function() {
      paste(input$StnNum, '.csv', sep='')
    },
    content = function(file) {
      write.csv(getData(input$StnNum,res[1],res[2]), file,row.names=F)
    }
  )

  output$calcChill <- downloadHandler(
    filename = function() {
      if(input$BelowZero){
        paste(input$StnNum,'ChillBelowZero_HeatHours', '.csv', sep='')
      } else {
        paste(input$StnNum,'Chill_HeatHours', '.csv', sep='')
      }
    },
    content = function(file) {
      write.csv(getChillHours(input$StnNum,res[1],res[2],input$BelowZero,input$hThresh), file,row.names=F)
    }
  )


})
