# scripts for generating current and future Species Distribution Models

#### Start Current SDM ######
# 0. Load packages
source("src/packages.R")

# 1. Get occurrence Data 

# start with our data

#get occurance data just Lat and Long
occurrenceCoords<-read_csv("data/cleanedData.csv") %>%
  dplyr::select( decimalLongitude, decimalLatitude)


occurrenceSpatialPts <- SpatialPoints(occurrenceCoords, 
                                      proj4string = CRS("+proj=longlat"))


# now get the climate data
# make sure RAM is bumped up

#This downloads 19 raster files, one for each climate variable
worldclim_global(var="bio", res=2.5, path="data/", version="2.1") 

# update .gitignore to prevent huge files getting pushed to github

#Here are the meanings of the bioclimatic variables (bio1 to bio19) provided by WorldClim:
#bio1: Mean annual temperature
#bio2: Mean diurnal range (mean of monthly (max temp - min temp))
#bio3: Isothermality (bio2/bio7) (* 100)
#bio4: Temperature seasonality (standard deviation *100)
#bio5: Max temperature of warmest month
#bio6: Min temperature of coldest month
#bio7: Temperature annual range (bio5-bio6)
#bio8: Mean temperature of wettest quarter
#bio9: Mean temperature of driest quarter
#bio10: Mean temperature of warmest quarter
#bio11: Mean temperature of coldest quarter
#bio12: Annual precipitation
#bio13: Precipitation of wettest month
#bio14: Precipitation of driest month
#bio15: Precipitation seasonality (coefficient of variation)
#bio16: Precipitation of wettest quarter
#bio17: Precipitation of driest quarter
#bio18: Precipitation of warmest quarter
#bio19: Precipitation of coldest quarter





#Create a "raster stack" (stack of layers/variables)

climList <- list.files(path = "data/wc2.1_2.5m/", 
                       pattern = ".tif$", 
                       full.names = T)



#create stack from file list
currentClimRasterStack <- raster::stack(climList)

#plot annual temperature (see list of bioclimatic variables above)
plot(currentClimRasterStack[[1]]) 

#plots occurance points on top of climate plot
plot(occurrenceSpatialPts, add = TRUE) 




#2. Create pseudo-absence points (looks at where occurance points are and predicts where absence points are likely)

#mask determines the area we are interested in
mask <- raster(climList[[1]]) 



#zooms in focus from world to area we are interested in
geographicExtent <- extent(x = occurrenceSpatialPts)


#standerdizes random points for reproducability
set.seed(45) 

#creates psedo absence points
backgroundPoints <- randomPoints(mask = mask, 
                                 n = nrow(occurrenceCoords), #same n 
                                 ext = geographicExtent, 
                                 extf = 1.25, # draw a slightly larger area 
                                 warn = 0) 


#change column names
colnames(backgroundPoints) <- c("longitude", "latitude")


# 3. Convert occurrence and environmental data into format for model

# Data for observation sites (presence and background), with climate data

#create a grid of climate measurements, per occurance point 
occEnv <- na.omit(raster::extract(x = currentClimRasterStack, y = occurrenceCoords))

#create a grid of measurements for the psedo absence points
absenceEnv<- na.omit(raster::extract(x = currentClimRasterStack, y = backgroundPoints))


#create a vector of precence/absence
presenceAbsenceV <- c(rep(1, nrow(occEnv)), rep(0, nrow(absenceEnv))) 

#create a signel frame of p/a data by climate variable
presenceAbsenceEnvDf <- as.data.frame(rbind(occEnv, absenceEnv))


# 4. Create Current SDM with maxent


# If you get a Java error, restart R, and reload the packages
habronattusCurrentSDM <- dismo::maxent(x = presenceAbsenceEnvDf, ## env conditions
                                       p = presenceAbsenceV,   ## 1:presence or 0:absence
                                       path=paste("maxent_outputs"), #maxent output dir 
)                              


# 5. Plot the current SDM with ggplot


predictExtent <- 1.25 * geographicExtent 

geographicArea <- crop(currentClimRasterStack, predictExtent, snap = "in")


#merge into one raster layer
habronattusPredictPlot <- raster::predict(habronattusCurrentSDM, geographicArea) 


#create spatial pixles data frame
raster.spdf <- as(habronattusPredictPlot, "SpatialPixelsDataFrame")

#create data frame
habronattusPredictDf <- as.data.frame(raster.spdf)
#the layers closer to 1 are better conditions for the species

#get world boundries
wrld <- ggplot2::map_data("world")


#create bounding box (the box in which all the coordinates fall)
xmax <- max(habronattusPredictDf$x)
xmin <- min(habronattusPredictDf$x)
ymax <- max(habronattusPredictDf$y)
ymin <- min(habronattusPredictDf$y)

#final plot of current data
ggplot() +
  geom_polygon(data = wrld, mapping = aes(x = long, y = lat, group = group),
               fill = "grey75") +
  geom_raster(data = habronattusPredictDf, aes(x = x, y = y, fill = layer)) + 
  scale_fill_gradientn(colors = terrain.colors(10, rev = T)) +
  coord_fixed(xlim = c(xmin, xmax), ylim = c(ymin, ymax), expand = F) +#expand=F fixes margin
  scale_size_area() +
  borders("state") +
  borders("world", colour = "black", fill = NA) + 
  labs(title = "SDM of Habronattus americanus Under Current Climate Conditions",
       x = "longitude",
       y = "latitude",
       fill = "Environmental Suitability")+ 
  theme(legend.box.background=element_rect(),legend.box.margin=margin(5,5,5,5)) 

#save map to file
ggsave("output/habronattusCurrentSdm.jpg",  width = 8, height = 6)

#### End Current SDM #########


#### Start Future SDM ########


# 6. Get Future Climate Projections

# CMIP6 is the most current and accurate modeling data
# More info: https://pcmdi.llnl.gov/CMIP6/
#downloading future climate data
futureClimateRaster <- cmip6_world("CNRM-CM6-1", "585", "2061-2080", var = "bioc", res=2.5, path="data/cmip6")

# 7. Prep for the model

#syncronize the variable names
names(futureClimateRaster)=names(currentClimRasterStack)

#zoom in to data set box (instead of the whole world)
geographicAreaFutureC6 <- crop(futureClimateRaster, predictExtent)


# 8. Run the future SDM

habronattusFutureSDM <- raster::predict(habronattusCurrentSDM, geographicAreaFutureC6)


# 9. Plot the future SDM

#turn variable into data frame
habronattusFutureSDMDf <- as.data.frame(habronattusFutureSDM, xy=TRUE)

#bounding box
xmax <- max(habronattusFutureSDMDf$x)
xmin <- min(habronattusFutureSDMDf$x)
ymax <- max(habronattusFutureSDMDf$y)
ymin <- min(habronattusFutureSDMDf$y)

#Final Plot
ggplot() +
  geom_polygon(data = wrld, mapping = aes(x = long, y = lat, group = group),
               fill = "grey75") +
  geom_raster(data = habronattusFutureSDMDf, aes(x = x, y = y, fill = maxent)) + 
  scale_fill_gradientn(colors = terrain.colors(10, rev = T)) +
  coord_fixed(xlim = c(xmin, xmax), ylim = c(ymin, ymax), expand = F) +
  scale_size_area() +
  borders("state") +
  borders("world", colour = "black", fill = NA) + 
  labs(title = "Future SDM of Habronattus americanus Under CMIP6 Climate Conditions",
       x = "longitude",
       y = "latitude",
       fill = "Env Suitability") +
  theme(legend.box.background=element_rect(),legend.box.margin=margin(5,5,5,5)) 

ggsave("output/habronattusFutureSdm.jpg",  width = 8, height = 6)



##### END FUTURE SDM ######
