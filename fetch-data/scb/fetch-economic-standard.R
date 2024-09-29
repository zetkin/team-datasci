library(pxweb)
# Use the below line to build query
#d <- pxweb_interactive("api.scb.se")

regions <- read_lines('regions.txt')
# PXWEB query 
pxweb_query_list <- 
  list(
    "Region"=regions,
    "Alder"=c("tot"),
    "ContentsCode"=c("000006TA"),
    "Tid"=c("2019","2022"))
       
# Download data 
px_data <- 
  pxweb_get(url = "https://api.scb.se/OV0104/v1/doris/sv/ssd/HE/HE0110/HE0110I/TabVX4InkDesoN1",
            query = pxweb_query_list)

# Convert to data.frame 
px_data_frame <- as.data.frame(px_data, column.name.type = "text", variable.value.type = "text")

px_data_frame %>%
  write_csv('low-economic-standard.all-ages.2019.2022.DeSO.csv')
