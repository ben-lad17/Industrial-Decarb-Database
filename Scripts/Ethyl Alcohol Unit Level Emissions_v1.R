##################################################################
#                               
# Project 2035: Industrial Decarb
# 
# Version: 1
# April 4, 2025               
# Ben Ladabaum                  
#                               
# Description:  Create dataset with unit-level process emissions for ethyl alcohol
#
# Notes:  
# 
# Inputs:   
#         
#
# Outputs:   
#
##################################################################


# Clean the environment
rm(list=ls())

# Load libraries
library(here)
library(janitor) 
library(readxl)
library(writexl)
library(tidyverse)
library(openxlsx)


### Functions ###
source(here("Functions", "is_unique_id.R"))
source(here("Functions", "convert_to_numeric.R"))
source(here("Functions", "export_facility_unit_data.R"))


### Load Data ###

# Facilities data
facilities_data = read_excel(here("Data", "rlps_ghg_emitter_facilities.xlsx")) |>
  rename(reporting_year = year) |>
  select(facility_id, reporting_year, primary_naics)
is_unique_id(facilities_data, c("facility_id", "reporting_year"))

# capacity data
capacity_data = read_excel(here("Data", "ethyl alcohol manufacturers.xlsx"), sheet = "Crosswalk") |>
  filter(!is.na(facility_id)) |>
  clean_names() |>
  select(facility_id, capacity_m_mgy, feedstock)



### Combine with combustion emissions ###

# load subpart c emissions dataset
subpart_c = read_csv(here("Output", "subpart_c_emissions_and_fuel_by_unit_v3.csv")) |>
  mutate(primary_naics = as.character(primary_naics))|>
  filter(primary_naics %in% c("325193")) |> 
  filter(!(ghg_gas_name %in% c("Nitrous Oxide (Co2 eq)", "Methane (Co2 eq)"))) # remove this line 
# once emissions factor issue is resolved

is_unique_id(subpart_c, c("facility_id", "reporting_year", "unit_name", 
                          "fuel_type", "ghg_gas_name"))


# Append subpart c and other relevant subparts (if necessary)
ethyl_alcohol_emissions_by_unit = subpart_c 

# replace subpart_c above with this code if we need subpart ii, s or hh
# bind_rows(subpart_c, emissions_by_unit) |>
#   arrange(facility_id, reporting_year, ghg_gas_name) |>
#   relocate(anaerobic_process_id, .before = fuel_type)

ethyl_alcohol_emissions_by_unit_2023 = ethyl_alcohol_emissions_by_unit |>
  filter(reporting_year==2023)

# combine capacity data with unit level
facility_capacities_2023 = ethyl_alcohol_emissions_by_unit_2023 |>
  group_by(facility_id, fuel_type, ghg_gas_name) |>
  summarise(
    ghg_quantity = sum(ghg_quantity, na.rm = TRUE)
  ) |>
  pivot_wider(names_from = "fuel_type", values_from = ghg_quantity) |>
  clean_names() |>
  left_join(y = capacity_data, by = "facility_id") |>
  filter(ghg_gas_name != "Carbon Dioxide Total")




### export ###
export_facility_unit_data(
  industry = "ethyl_alcohol",
  version = "v1",
  file_type = "unit",
  datasets = list(
    "unit_emissions" = ethyl_alcohol_emissions_by_unit,
    "unit_emissions_2023" = ethyl_alcohol_emissions_by_unit_2023
  )
)

# export additional tab for facility capacities
wb <- loadWorkbook(here("Output", "ethyl_alcohol_emissions_by_unit_v1.xlsx"))
#addWorksheet(wb, "facility_capacities_2023")
writeData(wb, sheet = "facility_capacities_2023", x = facility_capacities_2023)
saveWorkbook(wb, here("Output", "ethyl_alcohol_emissions_by_unit_v1.xlsx"), overwrite = TRUE)





