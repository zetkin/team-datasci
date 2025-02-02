*** Analysera EU-valet 2024

clear all
cd "D:\Dropbox\eu election"

use "munip_valkod.dta"

destring valdistriktskod, replace
save "munip_valkod.dta", replace

import delimited using "n_calls.demographic_data.valdistrikt.csv", clear

merge 1:1 valdistriktskod using "munip_valkod.dta"

destring prop_of_valid_votes_v_2024, force replace
replace n_calls = "0" if n_calls == "NA"
destring n_calls, replace

replace prop_of_valid_votes_v_2019 = "0" if prop_of_valid_votes_v_2019 == "NA"
destring prop_of_valid_votes_v_2019, replace

replace prop_of_valid_votes_mp_2019 = "0" if prop_of_valid_votes_mp_2019 == "NA"
destring prop_of_valid_votes_mp_2019, replace

gen turnout = prop_voting_s_2024
gen turnout_19 = prop_voting_s_2019
replace turnout_19 = "0" if turnout_19 == "NA"
destring turnout_19, replace

encode Kommun, generate(kommun_id)

replace prop_of_valid_votes_v_2024 = prop_of_valid_votes_v_2024*100
replace turnout = turnout*100


gen log_calls = ln(1+n_calls)

binscatter prop_of_valid_votes_v_2024 n_calls, n(100) control(c.prop_of_valid_votes_mp_2019  prop_of_valid_votes_v_2019 turnout_19 i.kommun_id)

twoway (scatter prop_of_valid_votes_v_2024 log_calls) (lfit prop_of_valid_votes_v_2024 log_calls)
* Main regression
reg prop_of_valid_votes_v_2024 c.n_calls c.prop_of_valid_votes_mp_2019  prop_of_valid_votes_v_2019 turnout_19 i.kommun_id, robust
outreg2 using "C:\Users\wilsk523\Dropbox\eu election/regressions.doc", keep(n_calls) replace

* Turnout as outcome
reg turnout c.n_calls c.prop_of_valid_votes_mp_2019  prop_of_valid_votes_v_2019 turnout_19 i.kommun_id, robust

outreg2 using "C:\Users\wilsk523\Dropbox\eu election/regressions.doc", keep(n_calls) append

merge 1:1 valdistriktskod using "C:\Users\wilsk523\Dropbox\eu election/deso_joined.dta", nogen

** 
reg prop_of_valid_votes_v_2024 c.n_calls c.prop_of_valid_votes_mp_2019  prop_of_valid_votes_v_2019 turnout_19 i.kommun_id uned_share, robust

* Low-ed interaction
reg prop_of_valid_votes_v_2024 c.n_calls##c.uned_share c.prop_of_valid_votes_mp_2019  prop_of_valid_votes_v_2019 turnout_19 i.kommun_id , robust
outreg2 using "C:\Users\wilsk523\Dropbox\eu election/regressions.doc", keep(n_calls uned_share c.n_calls##c.uned_share) append

margins, dydx(n_calls) at(c.uned_share = (0.03(0.02)0.2))
marginsplot
* Low-ed turnout interaction
reg turnout c.n_calls##c.uned_share c.prop_of_valid_votes_mp_2019  prop_of_valid_votes_v_2019 turnout_19 i.kommun_id , robust
outreg2 using "C:\Users\wilsk523\Dropbox\eu election/regressions.doc", keep(n_calls uned_share c.n_calls##c.uned_share) append



reg prop_of_valid_votes_v_2024 c.n_calls##c.highed_share c.prop_of_valid_votes_mp_2019  prop_of_valid_votes_v_2019 turnout_19 i.kommun_id , robust

reg prop_of_valid_votes_v_2024 c.n_calls##c.prop_of_valid_votes_v_2019 c.uned_share c.prop_of_valid_votes_mp_2019   turnout_19 i.kommun_id , robust


reg turnout log_calls turnout_19

