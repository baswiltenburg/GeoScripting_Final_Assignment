# Main

# Teamname:   Team BB
# Authors:    Bram Schipper and Bas Wiltenburg
# Date:       1st of february 2017
# Course:     GeoScripting 2016/2017

# Title:      Monitoring of the concentration of particulate matter in the atmosphere caused by wildfires.

# Objective:  We have created an interactive map wich presents the concentration of particulate matter 
#             in the atmosphere of Californa. This is done by making a time-series-analyses of the
#             biggest and most expensive wildfire in the history of Californa (the Sherpa wildfire). 
#             This wildfire began on the 21th of July and was extinguished on the 11th of October. 
#             The interpolation is based on hundreds of monitoringsstations spread over California. 
#             The data is obtained from the Evironmental Protection Agency of the USA (https://www.epa.gov/outdoor-air-quality-data)
#             and saved in the folder 'Python/data/data.csv'. 


# To run the programm, first install the required packages if these are not installed on your Rstudios.
# After installing the packages, you can run the main.r completely. The interactive map will be 
# visible after all calculations are done! The calculation time is around 2,5 minutes!

#install.packages("sp")
#install.packages("raster")
#install.packages("gstat")
#install.packages("shiny")
#install.packages("datasets")
#install.packages("rgdal")
#install.packages("rPython")
#install.packages("maps")
#install.packages("leaflet")

# After installing the packages, load all required libraries. 
library(shiny)
library(datasets)
library(leaflet)
library(rgdal)
library(raster)
library(sp)
library(gstat)
library(rPython)
library(maps)


# The raw pollution-data (wich can be found in 'Python/data/data.csv') has to be pre-processed. 
# The pre-processing work is outsourced to Python. The python script builds a new dataframe with all
# the necessary (spatial) information from the source, which is needed for the project. Open the 
# python-script in the folder below to see details and explainations. 

# The line below runs the python script which do all the pro-processing work. 
system("python Python/preprocessing.py")


# Create and call the interactive map which shows the air-pollution, monitoringstations and wildfires in the state of California. 
# The line below runs the R script of the interactive map, this R script runs the script which interpolate air pollution during the whole wildfire period. 
source("R/app.R")
shinyApp(ui, server)
