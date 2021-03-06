library(readxl)
library(tidyverse)
library(stringr)
library(ggmap)
library(scales)
library(ggalt)
library(extrafont)
library(albersusa)


#library(sf)
#library(sp)
#library(rgeos)
#library(maptools)
#library(ggplot2)
#library(ggalt)
#library(ggthemes)
#library(viridis)
#library(scales)

# Importing the Kaiser Family Foundation data
hc <- read_excel("data/KFF map 2020 tax credits ACA vs AHCA.xlsx")

# Selecting specific differences columns
hc_id <- hc[,2:6]
hc_diff <- hc[,27:59]

hc_diff <- cbind(hc_id, hc_diff)

# Turning the wide data frame long

hc_diff <- gather(hc_diff, "category", "difference", 6:38)

# Keeping only the rows with "Dollar" difference mentions
hc_diff <- filter(hc_diff, grepl("Dollar", category))

# Adding some columns for age and income
hc_diff$age <- gsub(".*-", "", hc_diff$category)
hc_diff$age <- str_trim(hc_diff$age)
hc_diff$age <- gsub(" .*", "", hc_diff$age)
hc_diff$age <- gsub("yo", "", hc_diff$age)
hc_diff$age <- paste0("At age ", hc_diff$age)
hc_diff$income <- gsub(".*with", "", hc_diff$category)
hc_diff$income <- str_trim(hc_diff$income)
hc_diff$income <- gsub(" .*", "", hc_diff$income)
hc_diff$income <- gsub("k", ",000", hc_diff$income)
hc_diff$income <- paste0("$", hc_diff$income)

# Converting the difference column to numeric
hc_diff$difference <- as.numeric(hc_diff$difference)


## MAPPING

library(tigris)
library(scales)

# Bringing in the counties map
hc_c <- counties(cb=T)

# Turning the shapefile into a dataframe
hc_cf <- fortify(hc_c, region="GEOID")

# Converting the FIPS code column numeric
hc_cf$id <- as.numeric(hc_cf$id)

## Loop to rebuild shapes and factors as a long dataframe for faceting later on

uni <- unique(hc_diff$category)

names(hc_diff)[names(hc_diff) == 'County FIPS code'] <- 'id'

for (i in 1:length(uni)) {
  cat <- uni[i]
  subbed <- filter(hc_diff, category==cat)
  subbed1 <- left_join(hc_cf, subbed)
  subbed1 <- filter(subbed1, !is.na(difference))
  if (i == 1) {
    subbed_all <- subbed1
  } else {
    subbed_all <- rbind(subbed_all, subbed1)
  }
  
}

# Setting levels for income so it's not alphabetical

subbed_all$income <- factor(subbed_all$income, levels = c("$20,000", "$30,000", "$40,000", "$50,000", "$75,000", "$100,000"))

## State map
## CHANGE THE STATE ABBREVIATION TO WHATEVER STATE YOU WANT

state_subbed <- filter(subbed_all, ST=="CT")

# Wide version of the map (6x3)

state_m <- ggplot() 
state_m <- state_m +  geom_polygon(data = state_subbed, aes(x=long, y=lat, group=group, fill=difference), color = "black", size=0.2)
state_m <- state_m +  coord_map()
state_m <- state_m + facet_wrap(age~income, ncol=6)
# The breaks should be custom to the max and min 'difference' values in your state
state_m <- state_m + scale_fill_gradient2(low=muted("purple"), high=muted("green"), label=dollar, name=NULL, breaks=c(-9000,0,3000))
state_m <- state_m + theme_nothing(legend=TRUE) 
state_m <- state_m + theme(panel.border = element_blank(), panel.grid.major = element_blank(),
                           panel.grid.minor = element_blank())
state_m <- state_m + theme(strip.background = element_blank(),
                           strip.text.y = element_blank())
state_m <- state_m + theme(strip.text.x = element_text(size=12, face="bold"))
state_m <- state_m + labs(x=NULL, y=NULL, title="AHCA plan tax credits versus ACA", caption="Source: Kaiser Family Foundation")
state_m <- state_m + theme(text = element_text(size=15))
state_m <- state_m + theme(plot.title=element_text(face="bold", hjust=0))
state_m <- state_m + theme(plot.subtitle=element_text(face="italic", size=9, margin=margin(l=20)))
state_m <- state_m + theme(plot.caption=element_text(size=12, margin=margin(t=12), color="#7a7d7e", hjust=0))
state_m <- state_m + theme(legend.key.size = unit(1, "cm"))
state_m <- state_m + theme(legend.position="top")
state_m <- state_m + theme(plot.title=element_text(face="bold", family="Lato Black", size=22))
state_m <- state_m + theme(plot.caption=element_text(face="bold", family="Lato", size=9, color="gray", margin=margin(t=10, r=80)))

# To save file, uncomment line below
# ggsave("state_multiples.png", device="png", height=12, width=6, dpi=300)
print(state_m)

# Tall version of the map (6x3)

state_m <- ggplot() 
state_m <- state_m +  geom_polygon(data = state_subbed, aes(x=long, y=lat, group=group, fill=difference), color = "black", size=0.2)
state_m <- state_m +  coord_map()
state_m <- state_m + facet_wrap(income~age, ncol=3)
# The breaks should be custom to the max and min 'difference' values in your state
state_m <- state_m + scale_fill_gradient2(low=muted("purple"), high=muted("green"), label=dollar, name=NULL, breaks=c(-9000,0,3000))
state_m <- state_m + theme_nothing(legend=TRUE) 
state_m <- state_m + theme(panel.border = element_blank(), panel.grid.major = element_blank(),
                 panel.grid.minor = element_blank())
state_m <- state_m + theme(strip.background = element_blank(),
                       strip.text.y = element_blank())
state_m <- state_m + theme(strip.text.x = element_text(size=12, face="bold"))
state_m <- state_m + labs(x=NULL, y=NULL, title="AHCA plan tax credits versus ACA", caption="Source: Kaiser Family Foundation")
state_m <- state_m + theme(text = element_text(size=15))
state_m <- state_m + theme(plot.title=element_text(face="bold", hjust=0))
state_m <- state_m + theme(plot.subtitle=element_text(face="italic", size=9, margin=margin(l=20)))
state_m <- state_m + theme(plot.caption=element_text(size=12, margin=margin(t=12), color="#7a7d7e", hjust=0))
state_m <- state_m + theme(legend.key.size = unit(1, "cm"))
state_m <- state_m + theme(legend.position="top")
state_m <- state_m + theme(plot.title=element_text(face="bold", family="Lato Black", size=22))
state_m <- state_m + theme(plot.caption=element_text(face="bold", family="Lato", size=9, color="gray", margin=margin(t=10, r=80)))

# To save file, uncomment line below
# ggsave("state_multiples_tall.png", device="png", height=6, width=12, dpi=300)
print(state_m)

# US map now

subbed_all_filtered <- filter(subbed_all, ST!="HI" & ST!="AK")

# Wide version of the map (6x3)

us_m <- ggplot() 
us_m <- us_m +  geom_polygon(data = subbed_all_filtered, aes(x=long, y=lat, group=group, fill=difference), color = "gray", size=0.02)
us_m <- us_m +  coord_proj(us_laea_proj)
us_m <- us_m + facet_wrap(age~income, ncol=6)
us_m <- us_m + scale_fill_gradient2(low="purple", high="green", label=dollar, name=NULL, breaks=c(-15000,3000))
us_m <- us_m + theme_nothing(legend=TRUE) 
us_m <- us_m + theme(panel.border = element_blank(), panel.grid.major = element_blank(),
                     panel.grid.minor = element_blank())
us_m <- us_m + theme(strip.background = element_blank(),
                     strip.text.y = element_blank())
us_m <- us_m + theme(strip.text.x = element_text(size=12, face="bold"))
us_m <- us_m + labs(x=NULL, y=NULL, title="AHCA plan tax credits versus ACA", caption="Source: Kaiser Family Foundation")
us_m <- us_m + theme(text = element_text(size=15))
us_m <- us_m + theme(plot.title=element_text(face="bold", hjust=0))
us_m <- us_m + theme(plot.subtitle=element_text(face="italic", size=9, margin=margin(l=20)))
us_m <- us_m + theme(plot.caption=element_text(size=12, margin=margin(t=12), color="#7a7d7e", hjust=0))
us_m <- us_m + theme(legend.key.size = unit(.5, "cm"))
us_m <- us_m + theme(legend.position="top")
us_m <- us_m + theme(plot.title=element_text(face="bold", family="Lato Black", size=22))
us_m <- us_m + theme(plot.caption=element_text(face="bold", family="Lato", size=7, color="gray", margin=margin(t=10, r=80)))

# To save file, uncomment line below
# ggsave("us_multiples.png", device="png", height=6, width=12, dpi=300)
print(us_m)

# Tall version of the map (3x6)

us_m <- ggplot() 
us_m <- us_m +  geom_polygon(data = subbed_all_filtered, aes(x=long, y=lat, group=group, fill=difference), color = "gray", size=0.02)
us_m <- us_m +  coord_proj(us_laea_proj)
us_m <- us_m + facet_wrap(income~age, ncol=3)
us_m <- us_m + scale_fill_gradient2(low="purple", high="green", label=dollar, name=NULL, breaks=c(-15000,3000))
us_m <- us_m + theme_nothing(legend=TRUE) 
us_m <- us_m + theme(panel.border = element_blank(), panel.grid.major = element_blank(),
                     panel.grid.minor = element_blank())
us_m <- us_m + theme(strip.background = element_blank(),
                     strip.text.y = element_blank())
us_m <- us_m + theme(strip.text.x = element_text(size=12, face="bold"))
us_m <- us_m + labs(x=NULL, y=NULL, title="AHCA plan tax credits versus ACA", caption="Source: Kaiser Family Foundation")
us_m <- us_m + theme(text = element_text(size=15))
us_m <- us_m + theme(plot.title=element_text(face="bold", hjust=0))
us_m <- us_m + theme(plot.subtitle=element_text(face="italic", size=9, margin=margin(l=20)))
us_m <- us_m + theme(plot.caption=element_text(size=12, margin=margin(t=12), color="#7a7d7e", hjust=0))
us_m <- us_m + theme(legend.key.size = unit(.5, "cm"))
us_m <- us_m + theme(legend.position="top")
us_m <- us_m + theme(plot.title=element_text(face="bold", family="Lato Black", size=22))
us_m <- us_m + theme(plot.caption=element_text(face="bold", family="Lato", size=7, color="gray", margin=margin(t=10, r=80)))

# To save file, uncomment line below
# ggsave("us_multiples_tall.png", device="png", height=12, width=6, dpi=300)
print(us_m)