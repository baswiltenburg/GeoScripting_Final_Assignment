## GENERAL INTRODUCTION AND EXPLAINATION OF THIS SCRIPT

# The function below interpolates the air pollution in the atmosphere for the extent of california. 
# The function returns a rasterstack and a SpatialPointDataFrame. The rasterstack contains 82 layers.
# Each layer in the rasterstack is an interpolation for a specific date (july 21th until october 11th is 82 layers). 
# Note that in the function below, also a python script is executed. This python script creates 82 seperate 
# .csv files from the whole dateset, which is created in the python preprocessing function. These 82 .csv files
# consist of the data of all monitoringsstations for one specific date. These .csv files are used to create
# the final rasterstack. 

Interpolate_pollution <- function(){
  
  ## READING PREPROCESSED DATASET AND DEFINE PROJECT EXTENT
  
  # Read the dataset and create a dataframe of the dates of the wildfire-period only. 
  data <- read.csv("Python/output/preprocessing_results.csv")
  strtrim(data$Date,10)
  data$Date <- as.Date(as.character(data$Date), "%m/%d/%Y")
  firedates <- subset(data, Date > as.Date("2016-07-21") & Date < as.Date("2016-10-13"))
  
  # Define the project extent (square around the state of California)
  project_extent <- extent(-125, -114, 32, 43)
  
  ## CREATE SPATIAL POINT DATAFRAME OF MONITORING STATIONS 
  
  # Create a matrix of the coordinates of all monitoring stations (for SpatialPointDataFrame)
  # Create a SpatialPointDataframe of all the monitoring stations in the project extent 
  coordinates <- cbind(firedates$SITE_LONGITUDE, firedates$SITE_LATITUDE)
  spdf <- SpatialPointsDataFrame(coords = coordinates, data = firedates, proj4string = CRS("+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0"))
  
  ## CROP
  
  # Crop all the data to the defined project extent. The advantage of doing this is that, if you want 
  # to change the result, you only have to change the project extent since everything refers to the extent. 
  spdf_crop <- crop(spdf, project_extent)
  coordinates_crop <- cbind(spdf_crop$SITE_LONGITUDE, spdf_crop$SITE_LATITUDE)
  
  # Save the data of the cropped SpatialPointsDataFrame in a variable and write it to a new .csv file. 
  df <- spdf_crop@data
  write.csv(df, file = "Dataframes/df_fire_period.csv") 
  
  # SPLIT THE BIG DATAFRAME 
  
  # To make a time series analysis, we have to split the big dataframe to 82 single dataframes with in
  # with in each separate dataframe the data of all monitoring stations of one single day. 
  # Moreover, we will write this list of 82 dataframes to single .csv files which consist of the data of only one day.  
  # For this work, again python is more suitable. See the python script for details an explaination.
  system("python Python/create_dataframes.py") #runs all the functions in this script
  
  # MASK
  
  # Create a closed polygon (SpatialPolygonsDataFrame) of the area of all the monitoring-points within the project-extent.
  # We do this step to to prevent extrapolation close the boundaries of the project-extent, where there are
  # not enough monitorings stations. This polygon is used for masking.
  set.seed(1)
  ch <- chull(coordinates_crop)
  coords <- coordinates_crop[c(ch, ch[1]), ]  
  sp_poly <- SpatialPolygons(list(Polygons(list(Polygon(coords)), ID=1)), proj4string = CRS("+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0"))
  sp_poly_df <- SpatialPolygonsDataFrame(sp_poly, data=data.frame(ID=1))
  
  # In the first instance, the polygon created above was used for masking, but later we decided to use the extent
  # of the california state boundaries. These leads to extrapolations at the borders but gives a nicer presentation.
  USA <- getData('GADM', country='USA', level=1)
  california <- USA[USA$NAME_1 == "California",]
  california <- spTransform(california, CRS("+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0"))
  
  # CREATE RASTER FOR THE IDW INTERPOLATION FUNCTION
  
  # Create an empty raster for the interpolation function and define the coordinate reference system 
  raster <- raster(project_extent, nrows=50, ncols= 50)
  grd.pts <- SpatialPixels(SpatialPoints((raster)))
  grd <- as(grd.pts, "SpatialGrid")
  proj4string(grd) <- CRS("+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0")
  
  # EXECUTE THE INTERPOLATIONS (82 in total)
  
  rasters <- stack()
  for(i in 0:82) {
    # Read the .csv files created in the python script (each .csv file has data for one specific day)
    # The command below ensures that in every new loop, the next .csv file will be read
    filename <- paste("Dataframes/day_",i,".csv",sep="") 
    data_per_day <- read.csv(filename)
    
    # Extract the coordinates and create SpatialPointDataFrame for each .csv file
    coordinates_fd <- cbind(data_per_day$SITE_LONGITUDE, data_per_day$SITE_LATITUDE)
    fd_spdf <- SpatialPointsDataFrame(coords = coordinates_fd, data = data_per_day, proj4string = CRS("+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0"))
    
    # The function below is doing the interpolation
    idw_cal <- idw(fd_spdf$Daily.Mean.PM2.5.Concentration ~ 1, fd_spdf, grd, idp=6)
    
    # Convert result (grid) to raster format
    idw_cal_r <- raster(idw_cal)
    values(idw_cal_r)[values(idw_cal_r)<0] = 0
    
    # Mask it to the boundaries of california
    idw_cal_r_m <- mask(idw_cal_r, california, inverse = FALSE)
    
    
    # Stack the rasterlayer, the final result will be a rasterstack with 82 layers
    rasters <- stack(rasters, idw_cal_r_m)
    
    #plot(idw_cal_r_m, axes=TRUE)
    #plot(sp_poly_df, add = TRUE)
    #plot(spdf_crop, pch=19, cex = 0.2, add = TRUE)
    #map("state", lwd=1, add =TRUE)
    #map("county", lwd=0.5, lty=3, add =TRUE)
    #mtext(data_per_day$Date[1], side =3, cex = 1, font = 2, line = 1)
    
    # The rasterstack and de spatial point data frame is used for the interactive map
    result = list(rasters, spdf_crop)
  }
  return(result)
}

