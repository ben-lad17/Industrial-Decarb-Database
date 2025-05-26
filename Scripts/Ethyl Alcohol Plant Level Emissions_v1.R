##################################################################
#                               
# Project 2035: Industrial Decarb
# 
# Version: 1
# April 4, 2024               
# Ben Ladabaum                  
#                               
# Description:  Facility emissions data for ethyl alcohol
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

# load functions 
source(here("Functions", "export_facility_unit_data.R"))

# load data
ghgrp_facilities = read_excel(here("Data", "rlps_ghg_emitter_facilities.xlsx")) |>
  rename(reporting_year = year)

# update this if any subparts are needed for ethyl alcohol manufacturing
# subpart_ii_emissions = read_excel(here("Data/Subpart II", "ii_subpart_level_information.xlsx")) |>
#   clean_names()  |>
#   rename(methane_subpart_ii = ghg_quantity) |>
#   select(-ghg_name, facility_name)

subpart_c_emissions = read_excel(here("Output", "subpart_c_emissions_by_facility_v2.xlsx"))


# prepare for export
# if another subpart is relevant, merge subpart on (potentially HH or II)
ethyl_alcohol_emissions_by_facility = left_join(x = subpart_c_emissions, y = ghgrp_facilities, 
                                             by = c("facility_id", "reporting_year", "primary_naics")) |>
  filter(primary_naics %in% c("325193")) |>
  select(facility_id, reporting_year, primary_naics, carbon_dioxide_subpart_c, biogenic_co2_subpart_c, 
         methane_subpart_c, nitrous_oxide_subpart_c, byproducts, other_pollutants, declared_combustion_units, 
         pct_co2e_declared_cu, product_outputs, employment, annual_production_qty, plant_size) 

ethyl_alcohol_emissions_by_facility_2023 = ethyl_alcohol_emissions_by_facility |>
  filter(reporting_year==2023)

### export ###
export_facility_unit_data(
  industry = "ethyl_alcohol",
  version = "v1",
  file_type = "facility",
  datasets = list(
    "facility_emissions" = ethyl_alcohol_emissions_by_facility,
    "facility_emissions_2023" = ethyl_alcohol_emissions_by_facility_2023
  )
)