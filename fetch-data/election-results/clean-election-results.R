library(tidyverse)

valresultat <- readxl::read_excel(
  'slutligt-valresultat-europaparlamentet-2024-vallokalernas-rostrakning.xlsx',
  sheet='rosterEU'
  ) %>%
  filter(
    Valdistriktnamn!='Uppsamlingsdistrikt',
    !Parti %in% c('blanka röster', 'ej anmält deltagande', 'övriga ogiltiga')
    ) %>%
  mutate(
    sum_valid_votes = sum(Röster),
    prop_of_valid_votes = Röster / sum_valid_votes,
    prop_voting = sum_valid_votes / Röstberättigade,
    .by = 'Valdistriktskod'
  ) %>%
  mutate(
    party = case_match(
      Parti,
      'Arbetarepartiet-Socialdemokraterna' ~ 'S',
      'Centerpartiet' ~ 'C',
      'Kristdemokraterna' ~ 'KD',
      'Liberalerna (tidigare Folkpartiet)' ~ 'L',
      'Miljöpartiet de gröna' ~ 'MP',
      'Moderaterna' ~ 'M',
      'Sverigedemokraterna' ~ 'SD',
      'Vänsterpartiet' ~ 'V',
      'övriga anmälda partier' ~ 'ÖVR',
      .default = Parti
    )
  ) %>%
  select(-Parti)

write_csv(valresultat, 'valresultat-EU-2024.cleaned.csv')

valresultat_2019 <- readxl::read_excel(
  'tab5_eu_valdistr.xlsx',
  skip = 1
) %>%
  pivot_longer(-c(Kommunnamn, Kommunkod, Valdistriktsnamn, Valdistriktskod)) %>%
  mutate(
    name = str_replace_all(name, '\r\n', ' ')
  ) %>%
  pivot_wider(names_from = name, values_from = value) %>%
  pivot_longer(
    -c(Kommunnamn,
       Kommunkod,
       Valdistriktsnamn,
       Valdistriktskod,
       `Antal röstberättigade`,
       `varav utländska EU-medborgare i Sverige`,
       `Antal röstande`,
       `Antal ogiltiga valsedlar`,
       `varav blanka valsedlar`,
       `Andel röstande`,
       `Antal giltiga valsedlar`
       ),
    names_to = 'party',
    values_to = 'votes'
    ) %>%
  rename(
    sum_valid_votes = `Antal giltiga valsedlar`
  ) %>%
  mutate(
    prop_of_valid_votes = votes/sum_valid_votes,
    prop_voting = sum_valid_votes/`Antal röstberättigade`
  )

write_csv(valresultat_2019, 'valresultat-EU-2019.cleaned.csv')
