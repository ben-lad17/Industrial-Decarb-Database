##################################################################
#                               
# Project 2035: Industrial Decarb
# 
# Version: 1
# April 17, 2024               
# Ben Ladabaum                  
#                               
# Description:  Facility emissions data for soybean and oilseed manufacturing
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

# subpart ii
subpart_ii_emissions = read_excel(here("Data/Subpart II", "ii_subpart_level_information.xlsx")) |>
  clean_names()  |>
  rename(methane_subpart_ii = ghg_quantity) |>
  select(-ghg_name, facility_name)

# subpart hh data
subpart_hh_emissions = read_excel(here("Data/Subpart HH", "hh_subpart_level_information.xlsx")) |>
  pivot_wider(names_from = ghg_name, values_from = ghg_quantity) |>
  clean_names()  |>
  rename(biogenic_co2_subpart_hh = biogenic_carbon_dioxide,
         methane_subpart_hh = methane, nitrous_oxide_subpart_hh = nitrous_oxide) |>
  select(-facility_name)


subpart_c_emissions = read_excel(here("Output", "subpart_c_emissions_by_facility_v2.xlsx"))


# merge subparts c, ii, hh, and s
soybean_oilseed_emissions_by_facility = subpart_c_emissions |>
  #left_join(x = subpart_c_emissions, y = subpart_s_emissions, 
                                            # by = c("facility_id", "reporting_year")) |>
  #left_join(y = subpart_ii_emissions, by = c("facility_id", "reporting_year")) |>
  #left_join(y = subpart_hh_emissions, by = c("facility_id", "reporting_year")) |>
  filter(primary_naics %in% c("311224")) # |>
  #relocate(ends_with("_subpart_hh"), .after = nitrous_oxide_subpart_c) |>
  #relocate(methane_subpart_ii, .after = nitrous_oxide_subpart_c)

soybean_oilseed_emissions_by_facility_2023 = soybean_oilseed_emissions_by_facility |>
  filter(reporting_year==2023)

### export ###
export_facility_unit_data(
  industry = "soybean_oilseed",
  version = "v1",
  file_type = "facility",
  datasets = list(
    "facility_emissions" = soybean_oilseed_emissions_by_facility,
    "facility_emissions_2023" = soybean_oilseed_emissions_by_facility_2023
  )
)