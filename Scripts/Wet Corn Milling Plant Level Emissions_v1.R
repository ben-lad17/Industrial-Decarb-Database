##################################################################
#                               
# Project 2035: Industrial Decarb
# 
# Version: 1
# March 10, 2024               
# Ben Ladabaum                  
#                               
# Description:  Add process emissions from subpart II to facility emissions data for 
#               wet corn milling industry.
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

# load functions 
source(here("Functions", "export_facility_unit_data.R"))

# load data
ghgrp_facilities = read_excel(here("Data", "rlps_ghg_emitter_facilities.xlsx")) |>
  rename(reporting_year = year)

subpart_ii_emissions = read_excel(here("Data/Subpart II", "ii_subpart_level_information.xlsx")) |>
  clean_names()  |>
  rename(methane_subpart_ii = ghg_quantity) |>
  select(-ghg_name, facility_name)

subpart_c_emissions = read_excel(here("Output", "subpart_c_emissions_by_facility_v2.xlsx"))


# merge subpart c and subpart ii
wet_corn_milling_emissions_by_facility = left_join(x = subpart_c_emissions, y = subpart_ii_emissions, 
                                  by = c("facility_id", "reporting_year")) |>
  left_join(y = ghgrp_facilities, by = c("facility_id", "reporting_year", "primary_naics")) |>
  filter(primary_naics %in% c("311221")) |>
  mutate(secondary_naics_325193 = secondary_naics=="325193") |>
  select(facility_id, reporting_year, primary_naics, carbon_dioxide_subpart_c, biogenic_co2_subpart_c, 
         methane_subpart_c, nitrous_oxide_subpart_c, 
         methane_subpart_ii, byproducts, other_pollutants, declared_combustion_units, 
         pct_co2e_declared_cu, product_outputs, employment, annual_production_qty, plant_size, 
         secondary_naics_325193) 

wet_corn_milling_emissions_by_facility_2023 = wet_corn_milling_emissions_by_facility |>
  filter(reporting_year==2023)
  
### export ###
export_facility_unit_data(
  industry = "wet_corn_milling",
  version = "v1",
  file_type = "facility",
  datasets = list(
    "facility_emissions" = wet_corn_milling_emissions_by_facility,
    "facility_emissions_2023" = wet_corn_milling_emissions_by_facility_2023
  )
)


