##################################################################
#                               
# Project 2035: Industrial Decarb
# 
# Version: 1
# March 10, 2025               
# Ben Ladabaum                  
#                               
# Description:  Create dataset with unit-level process emissions for wet corn milling
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

# subpart ii data
eq_6 = read_excel(here("Data/Subpart II", "ii_equation_ii6.xlsx"))
eq_3 = read_excel(here("Data/Subpart II", "ii_equation_ii3.xlsx"))

### Wastewater Treatment Emissions
eq_6_clean = eq_6 |>
  select(anaerobic_process_id, annual_mass_methane_emissions, facility_id, reporting_year) |>
  distinct() 

eq_3_clean = eq_3 |>
  select(anaerobic_process_id, annual_mass_methane_emissions, facility_id, reporting_year) |>
  distinct() 

emissions_by_unit = rbind(eq_6_clean, eq_3_clean) |>
  group_by(facility_id, reporting_year, anaerobic_process_id) |>
  summarise(
    ghg_quantity = sum(annual_mass_methane_emissions, na.rm = TRUE)
  ) |>
  ungroup() |>
  mutate(subpart = "II") |>
  mutate(ghg_gas_name = "Methane") |>
  left_join(y = facilities_data, by=c("facility_id", "reporting_year")) |>
  filter(primary_naics=="311221")



### Combine with combustion emissions ###

# load subpart c emissions dataset
subpart_c = read_csv(here("Output", "subpart_c_emissions_and_fuel_by_unit_v3.csv")) |>
  mutate(primary_naics = as.character(primary_naics))|>
  filter(primary_naics %in% c("311221")) |> 
  filter(!(ghg_gas_name %in% c("Nitrous Oxide (Co2 eq)", "Methane (Co2 eq)"))) # remove this line 
# once emissions factor issue is resolved

is_unique_id(subpart_c, c("facility_id", "reporting_year", "unit_name", 
                          "fuel_type", "ghg_gas_name"))


# Append subpart c and subpart ii
wet_corn_milling_emissions_by_unit = bind_rows(subpart_c, emissions_by_unit) |>
  arrange(facility_id, reporting_year, ghg_gas_name) |>
  relocate(anaerobic_process_id, .before = fuel_type)

wet_corn_milling_emissions_by_unit_2023 = wet_corn_milling_emissions_by_unit |>
  filter(reporting_year==2023)

### export ###
export_facility_unit_data(
  industry = "wet_corn_milling",
  version = "v1",
  file_type = "unit",
  datasets = list(
    "unit_emissions" = wet_corn_milling_emissions_by_unit,
    "unit_emissions_2023" = wet_corn_milling_emissions_by_unit_2023
  )
)

