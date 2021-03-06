# # # # #
# setup #
# # # # #

source("set-up.R") # load required packages

# # # # # # # # # # # # #
# Load Leeds data       #
# No need to run this   #
# # # # # # # # # # # # #

# Load public access flow data
# Set file location (will vary - download files from here:
# https://wicid.ukdataservice.ac.uk/cider/wicid/downloads.php)
f <- "/media/robin/data/data-to-add/public-flow-data-msoa/wu03ew_v2.csv"
flowm <- read.csv(f) # load public msoa-level flow data
o_in_leeds <- flowm$Area.of.residence %in% leeds$geo_code
d_in_leeds <- flowm$Area.of.workplace %in% leeds$geo_code

fleeds <- flowm[ o_in_leeds & d_in_leeds , ]

# # # # # # # # # # # #
# Load the test data  #
# (Available online)  #
# # # # # # # # # # # #

# Load the geographical data
leeds <- readRDS("pct-data/leeds/leeds-msoas-simple.Rds")
cents <- gCentroid(leeds, byid = T) # centroids of the zones
head(fleeds)

fleeds$dist <- NA # create distance field
plot(leeds)
# Calculate distance between OD pairs in leeds
for(i in 1:nrow(fleeds)){
  from <- leeds$geo_code %in% fleeds$Area.of.residence[i]
  to <- leeds$geo_code %in% fleeds$Area.of.workplace[i]
  fleeds$dist[i] <- gDistance(cents[from, ], cents[to, ])
  # print % of distances calculated
  if(i %% round(nrow(fleeds) / 10) == 0)
    print(paste0(100 * i/nrow(fleeds), " % out of ", nrow(fleeds)))
}
fleeds$dist <- fleeds$dist / 1000

# Propensity to cycle
fleeds$p_cycle <- iac(fleeds$dist)
fleeds$pc <- fleeds$p_cycle * fleeds$All.categories..Method.of.travel.to.work

# Extra cycling potential
fleeds$ecp <- fleeds$pc - fleeds$Bicycle
head(fleeds)
summary(fleeds$ecp)
summary(fleeds$Bicycle)

leeds <- spTransform(leeds, CRS("+init=epsg:4326"))
sel <- match(fleeds$Area.of.residence, leeds$geo_code)
head(sel)
ocoords <- coordinates(leeds)[sel,] # where distance = 0

sel <- match(fleeds$Area.of.workplace, leeds$geo_code)
head(sel)
dcoords <- coordinates(leeds)[sel,]

fleeds <- cbind(fleeds, ocoords, dcoords)
head(fleeds)
names(fleeds)
names(fleeds)[19:22] <- c("lon_origin", "lat_origin", "lon_dest", "lat_dest")

# write.csv(fleeds, "pct-data/leeds/msoa-flow-leeds-all.csv")

# # Actual rate of cycling
# plot(leeds)
# lwd <- fleeds$Bicycle / mean(fleeds$Bicycle) * 0.1
# for(i in 1:nrow(fleeds)){
# # for(i in 1:1000){
#   from <- leeds$geo_code %in% fleeds$Area.of.residence[i]
#   to <- leeds$geo_code %in% fleeds$Area.of.workplace[i]
#   x <- coordinates(leeds[from, ])
#   y <- coordinates(leeds[to, ])
#   lines(c(x[1], y[1]), c(x[2], y[2]), lwd = lwd, col = "blue" )
#   if(i %% round(nrow(fleeds) / 10) == 0)
#   print(paste0(100 * i/nrow(fleeds), " % out of ", nrow(fleeds)))
# }
#
# head(fleeds)
#
# plot(leeds)
# for(i in 1:nrow(fleeds)){
#   from <- leeds$geo_code %in% fleeds$Area.of.residence[i]
#   to <- leeds$geo_code %in% fleeds$Area.of.workplace[i]
#   x <- coordinates(leeds[from, ])
#   y <- coordinates(leeds[to, ])
# #   lines(c(x[1], y[1]), c(x[2], y[2]), lwd = fleeds$pc[i] / 400 )
# }

# Compare estimated and actual number of cyclists
plot(fleeds$Bicycle, fleeds$pc)
cor(fleeds$Bicycle, fleeds$pc)

# Create lines, convert to wgs84, export as geojson
