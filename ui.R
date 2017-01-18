
# This is the user-interface definition of a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)

shinyUI(fluidPage(

  # Application title
  titlePanel("Queensland Weather Data and Monthly Chill & Heat Hours"),

  # Sidebar with a slider input for number of bins
  sidebarLayout(
    sidebarPanel(
      h5("Enter a partial name (case doesn't matter) for the station you are looking for.\nOnly stations that record temperature and are in Qld will be returned"),
      textInput("Location", label = h3("Search For Station"),value=''),
      hr(),
      h4("Select the station number from the table and paste it in the field below"),
      textInput("StnNum", label = h4("Stn Number"),value='',width='100px'),
      downloadButton('downloadData', 'Download Met. Data Only'),
      hr(),
      h4('Chill Hours'),
      helpText('Check this option if you want to include hours below 0ºC'),
      helpText('Uncheck it if you only want to include hours 0 to 7.2ºC'),
      checkboxInput("BelowZero", "Include below zero", TRUE),
      hr(),
      h4('Heat Hours'),
      textInput("hThresh", label = strong("Threshold"),value='32',width='60px'),
      helpText('Download calculated values as CSV file'),

      downloadButton('calcChill', 'Calculate Monthly Chill & Heat Hours')
    ),
    mainPanel(
      tableOutput("stnList"),
      hr(),
      plotOutput("QldMap"),
      hr(lwd=2),
      helpText('This tool was created by Dr Neil White, DAF Queensland, as part of Activity 1: High-value horticultural production and processing enterprises in the Balonne and Border Rivers irrigation areas project'),
      helpText('Chill Hours are calculated as the number of hours below 7.2ºC with an option to exclude or include hours below 0ºC'),
      helpText('Heat Hours are the number of hours greater than a threshold temperature '),
      helpText('The column - ppnObs - shows the proportion of records that were actual observations. Missing observations are patched using a variety of techniques'),
      helpText('Missing observations are marked with a code other than 0 in the downloaded met. file'),
      hr(),
      helpText('If you have any problems, please contact Neil DOT White AT qld.gov.au'),
      helpText('Based on or contains data provided by the State of Queensland (Department of Science, Information Technology and Innovation) [2016]. In consideration of the State permitting use of this data you acknowledge and agree that the State gives no warranty in relation to the data (including accuracy, reliability, completeness, currency or suitability) and accepts no liability (including without limitation, liability in negligence) for any loss, damage or costs (including consequential damage) relating to any use of the data. Data must not be used in breach of the privacy laws.')

    )
  )
))
