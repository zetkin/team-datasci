library(tidyverse)
library(sf)
library(units)

election_districts <- dir_ls('data/election-districts/eu24', glob = '*.json') %>%
  map(\(x) read_sf(x) %>%st_cast('MULTIPOLYGON')) %>%
  list_rbind() %>%
  st_as_sf() %>%
  st_set_crs(3006) %>%
  mutate(election_district_area=st_area(geometry))

deso <- st_read('data/deso/DeSO_2018_v2.gpkg') %>%
  mutate(deso_area=st_area(geom))

deso_intersections <- election_districts %>%
  st_intersection(
    deso
  ) %>%
  mutate(intersection_area=st_area(geometry))

# QC visualization
deso_intersections %>%
  filter(intersection_area==max(intersection_area), .by=Lkfv) %>%
  mutate(
    deso_area_prop = intersection_area / deso_area,
    election_district_area_prop = intersection_area / election_district_area
  ) %>%
  as_tibble() %>%
  select(Lkfv, deso_area_prop, election_district_area_prop) %>%
  pivot_longer(-Lkfv) %>%
  ggplot() +
  geom_histogram(aes(value)) +
  facet_wrap(~ name)

deso_intersections %>%
  as_tibble() %>%
  filter(intersection_area==max(intersection_area), .by=Lkfv) %>%
  select(
    Valdistriktskod=Lkfv,
    Valdistriktnamn=Vdnamn,
    Kommun=kommunnamn,
    Län=lannamn,
    deso
    ) %>%
  write_tsv('deso-electoral-district-translation.tsv')

