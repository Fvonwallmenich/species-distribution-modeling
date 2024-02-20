#gbif.R 
#query species accuence data from GBIF
#clean up the data
#save it to a csv file
#create a map to display the accurance points

#List of packages
packages<-c("tidyverse", "rgbif", "webshot2", "usethis", "CoordinateCleaner", "leaflet", "mapview")

# install packages not yet installed: prevents errors from R runing a package already installed
installed_packages<-packages %in% rownames(installed.packages())
if(any(installed_packages==FALSE)){
  install.packages(packages[!installed_packages])
}

# Packages loading, with library function
invisible(lapply(packages, library, character.only=TRUE))


usethis::edit_r_environ()

spiderBackbone<-name_backbone(name="Habronattus americanus")
speciesKey<-spiderBackbone$usageKey

occ_download(pred("taxonKey", speciesKey), format="SIMPLE_CSV")


#<<gbif download>>
#Your download is being processed by GBIF:
 # https://www.gbif.org/occurrence/download/0011249-240202131308920
#Most downloads finish within 15 min.
#Check status with
#occ_download_wait('0011249-240202131308920')
#After it finishes, use
#d <- occ_download_get('0011249-240202131308920') %>%
#  occ_download_import()
#to retrieve your download.
#Download Info:
#  Username: jeremy2443
#E-mail: jeremym@lclark.edu
#Format: SIMPLE_CSV
#Download key: 0011249-240202131308920
#Created: 2024-02-12T22:52:08.768+00:00
#Citation Info:  
#  Please always cite the download DOI when using this data.
#https://www.gbif.org/citation-guidelines
#DOI: 10.15468/dl.9wtpm9
#Citation:
#  GBIF Occurrence Download https://doi.org/10.15468/dl.9wtpm9 Accessed from R via rgbif (https://github.com/ropensci/rgbif) on 2024-02-12

#To transfer this information/data to the "data" folder
d <- occ_download_get('0011249-240202131308920') %>%
  occ_download_import()

write_csv(d, "data/rawData.csv")


#Data cleanup
fData<-d%>%
  filter(!is.na(decimalLatitude), !is.na(decimalLongitude))

fData<-fData%>%
  filter(countryCode %in% c("US", "CA", "MX"))
#same as: (countryCode=="US"| countryCode=="CA"| countryCode=="MX")

fData<-fData%>%
  filter(!basisOfRecord %in% c("FOSSIL_SPECIMEN", "LIVING_SPECIMEN"))

fData<-fData%>%
  cc_sea(lon="decimalLongitude", lat="decimalLatitude")

fData<-fData%>%
  distinct(decimalLatitude, decimalLongitude, speciesKey, datasetKey, .keep_all=TRUE)
#got rid of duplicate enteries 


#In one step it might look like...
#fData<-d%>%
  #filter(!is.na(decimalLatitude), !is.na(decimalLongitude))%>%
  #filter(countryCode %in% c("US", "CA", "MX"))%>%
  #filter(!basisOfRecord %in% c("FOSSIL_SPECIMEN", "LIVING_SPECIMEN"))%>%
  #cc_sea(lon="decimalLongitude", lat="decimalLatitude")%>%
  #distinct(decimalLatitude, decimalLongitude, speciesKey, datasetKey, .keep_all=TRUE)

write.csv(fData, "data/cleanedData.csv")
