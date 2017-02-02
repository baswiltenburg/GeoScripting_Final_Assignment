## GENERAL INTRODUCTION AND EXPLAINATION OF THIS SCRIPT

# This script creates an interactive map of the following spatial data:
#   - All monitoringsstations used for the interpolation of particulate matter (SpatialPointDataFrame)
#   - A time series analysis of 82 interpolations for the period 21th of july until 12th of october 2016
#   - The location of all wildfires during this period, when they started and when they extinguished

# CALL INTERPOLATION FUNCTION

# After preprocessing in R, we have all the data we need to make an interpolation of the
# particulate matter concentration in the atmosphere. This calculation is done in the function below.
# Open the R-script in the folder 'R/air_pollution.R' to see details and explainations. 
# The line below rusn the R script which interpolate air pollution during the whole wildfire period. 
source("R/air_pollution.R")
result <- Interpolate_pollution()
spdf_crop  <- result[[2]]
rasters <- result[[1]]

## MAP THE LOCATION AND DURATION OF WILDFIRES

# We created an own dataset manually of all the wildfires in californa (the dates, names, duration and location)
# This dataset is saved in the folder: 'Python/data/california_wildfires.csv'
# This function is called in the interactive map server !!
fires_cal <- function(the_input_days){
  
  # Read the data and save it to a variable
  fire_locations <- read.csv("Python/data/california_wildfires.csv")
  
  # Create a SpatialPointDataFrame of all the firelocations
  fire_loc_coords <- cbind(fire_locations$lon, fire_locations$lat)
  spdf_fire_loc <- SpatialPointsDataFrame(fire_loc_coords, fire_locations, proj4string = CRS("+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0"))
  #spdf_fire_loc$index <- 1:18 # add an extra column to the dataframe with an indexnumber
  
  # For each fire in 'fire_lijst', create a new list with all the days (counting from the 21th of july), the fire appears
  fire_lijst <- list()
  for (i in spdf_fire_loc$index){ # the indexnumber is unique for each fire
    duration <- list((spdf_fire_loc$start_day[i] : spdf_fire_loc$end_day[i])) # To create a list of all the days a specific fire should occur in the map, the startdate (daynumber) and enddate (daynumber) are used
    fire_lijst <- append(fire_lijst, duration) # append all the days a fire occurs, to the fire_lijst
  }                                            # fire_lijst is a list of lists with for each list (a specific fire), all the daynumbers the fire shoudl appear
  
  # Create a list of lists of SpatialPointDataFrames for each wildfire
  d <- list()
  sum <- 0
  for (i in fire_lijst){
    sum <- sum+1
    if (the_input_days %in% i){ # 'the_input_days' is a variable of the slicy-slider in the interactive map
      d <- append(d,(spdf_fire_loc[sum,])) # d is a list of lists with for each list, a spatial point data frame of a specific wildfire
    }
  }

  if (length(d)==0){ # if on a specific day ('the_input_days') no wildfires are present, return an empty list
    return(d)
  }
  
  e <- d[[1]] # if there are one or more wildfires at a specific day, merge the SpatialPointDataframes to one SpatialPointDataFrame with a layer for each wildfire
  for (j in 2:length(d)){
  
    e <- e + d[[j]]
  }
  return(e) # 'e' is a SpatialPointDataframe, used for plotting the wildfires in the interactive map
}



## COLOR CONTROL FOR INTERACTIVE MAP

# mapcolor is the colorpallete used for plotting the interpolations rasters
mapcolor <- colorBin(palette = c('#dafec8', '#daf29a', '#effb79','#f9fc00', '#fcb800', '#ff6c00', '#ff3600'), domain = c(0:35), bins = 50, pretty = FALSE, na.color = NA)
# Legendcolor is a vector of colors which will be shown in the legend
legendcolor <- (c('#dafec8','#daf29a','#effb79','#f9fc00','#fcb800','#ff6c00', '#ff3600', '#910d0d'))
# The maxcolor is used for plotting the interpolation rasters for values higher than 35 ug/m³ particulate matter
maxcolor <- colorBin(palette = c('#910d0d'), domain = c(35:120),  bins =50, pretty = FALSE, na.color = NA)

## ICON CONTROL

# Load an own icon for presenting the fires
FireIcon <- makeIcon(
  iconUrl = "fire_icon.png",
  iconWidth = 32, iconHeight = 37,
  iconAnchorX = 16, iconAnchorY = 37
)

# Load an own icon for presenting the monitoring stations used for the interpolation
marker <- makeIcon(
  iconUrl = "marker.png",
  iconWidth = 3, iconHeight = 3,
  iconAnchorX = 1.5, iconAnchorY = 3
)

# Build an interface for the interactive map
ui <- shinyUI(navbarPage("Wildfires California", id="nav",
                         tabPanel("Interactive map",
                                  leafletOutput("map", width = "100%", height = 550),
                                  absolutePanel(id = "controls", class = "panel panel-default", fixed = TRUE,
                                                draggable = TRUE, top = 60, left = "auto", right = 10, bottom = "auto",
                                                width = 330, height = "auto",
                                                sliderInput("days", "Period of the 'Sherpa' wildfire", min = 1, max = 82, value = 1, step = 1, pre = 'Day ', animate = TRUE),
                                                textOutput("cellvalue"),
                                                plotOutput("plot", width = 225, height = 200))
                         )))

#Build a server for the interactive map
server <- shinyServer(function(input, output, session){
  
  fires <- reactive ({fires_cal(input$days)}) # calls the function 'fires_cal' which returns a unique spatialpointdataframe 
                                              # dependend on the variable input$days (daynumber in de slider!). This is reactive (changes all the time, so all the time another spatialpointdataframe is returned)
  output$map <- renderLeaflet({
    leaflet() %>%
      addProviderTiles("Stamen.TonerLite") %>% # The basemap used 
      #addTiles() %>%
      addMarkers(data=spdf_crop, icon = marker, group = 'Monitoring-stations')%>% # SpatialPointDataFrame of monitoringstations is added to the map
      setView(lng=-120, lat = 37, zoom = 5) %>%
      addLegend(position = "bottomright", colors = legendcolor, opacity = 0.8, values = c(0:35), title = "Legend",labFormat = labelFormat(suffix = ' ug/m³'), labels = c('0-5   ug/m³', '5-10  ug/m³', '10-15 ug/m³', '15-20 ug/m³', '20-25 ug/m³', '25-30 ug/m³', '30-35 ug/m³', '>35   ug/m³'))
  })
  
  observe({
    
    leafletProxy("map", data = rasters@layers[[input$days]]) %>%
      #clearGroup(group = "Pollution")%>%
      addRasterImage(rasters@layers[[input$days]], colors = mapcolor, opacity = 1, layerId = input$days, group = "Pollution")  %>% # maps all the values in the domain 0 - 35 ug/m³
      addRasterImage(rasters@layers[[input$days]], colors = maxcolor, opacity = 1, group = "Pollution")  %>%                       # maps all the values higher than 35 ug/m³ in red color
      addLayersControl(position = "bottomleft", overlayGroups = c("Pollution", "Monitoring-stations", "fire"), options = layersControlOptions(collapsed = FALSE))
  })
  
  observe({ 
    if (!is.list(fires()))
      leafletProxy("map", data = fires()) %>% # Plot the wildfires
      clearGroup(group = "fire")%>% # Clear the marks when going to a new date. It will recall the function
      addMarkers(popup= paste(fires()$name_fire,"<br>","Start day:",fires()$start_day,"<br>","End day:",fires()$end_day), icon = FireIcon, group = "fire")
    
  })
  
  observe({#Observer to show Popups on click
    click <- input$map_click
    if (!is.null(click)) {
      showpos(x=click$lng, y=click$lat)
    }
  })
  showpos <- function(x=NULL, y=NULL) {#Show popup on clicks
    #Translate Lat-Lon to cell number using the unprojected raster
    #This is because the projected raster is not in degrees, we cannot use it!
    depth <- projectRasterForLeaflet(rasters@layers[[input$days]])
    depth2 <- projectRasterForLeaflet(rasters)
    resol <- res(rasters@layers[[input$days]])
    cell <- cellFromXY(rasters@layers[[input$days]], c(x, y))
    
    if (!is.na(cell)) {#If the click is inside the raster...
      xy <- xyFromCell(rasters@layers[[input$days]], cell) #Get the center of the cell
      x <- xy[1]
      y <- xy[2]

      #Get value of the given cell
      val = depth[cell]
      output$cellvalue <- renderText({
        paste0(paste0("Local PM2.5 concentration = ", round(val, 1), " ug/m³"))
      })
      
      proxy <- leafletProxy("map")
      content <- paste0("PM2.5 = ", round(val, 1), " ug/m³")
      val2 = depth2[cell]
      extract_data <- extract(rasters, cell)
      joe <- extract_data[val2]
      output$plot <- renderPlot({
        p <- plot(joe, type = 'l', col = 'blue', main = 'Time series of air quality', xlab='Days', ylab='Concentration [ug/m³]')
        print(p)
      })
      
      proxy <- leafletProxy("map")

      #add rectangles for testing
      proxy %>% clearShapes() %>% addRectangles(x-resol[1]/2, y-resol[2]/2, x+resol[1]/2, y+resol[2]/2)
    }
  }
})





