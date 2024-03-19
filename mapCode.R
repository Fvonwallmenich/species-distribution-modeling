data<-read.csv("data/cleanedData.csv")

library(leaflet)
library(mapview)
library(webshot2)

map<-leaflet()%>%
  addProviderTiles("Esri.WorldTopoMap")%>%
  addCircleMarkers(data=data,
                   lat= ~decimalLatitude,
                   lng= ~decimalLongitude,
                   radius= 3,
                   color="purple",
                   fillOpacity = 0.8)%>%
  addLegend(position= "topright",
            title= "Species Occurance from GBIF",
            labels= "Habronattus americanus",
            color= "purple",
            opacity= 0)

#to save map
mapshot2(map, file = "output/leafletTest.png")
