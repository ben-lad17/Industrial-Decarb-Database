##################################################################
#                               
# Project 2035: Industrial Decarb
# 
# Version: 1
# June 7, 2025               
# Ben Ladabaum                  
#                               
# Description:  Create dataset with additional data for pulp & paper facility boilers
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

setwd("/Users/Ben L/Library/CloudStorage/Box-Box/Industrial Plant Raw Data/Industrial-Decarb-Database")

### Functions ###
source(here("Functions", "is_unique_id.R"))
source(here("Functions", "convert_to_numeric.R"))
source(here("Functions", "export_facility_unit_data.R"))

# load data
facility_data = read_excel("Data/rlps_ghg_emitter_facilities.xlsx") |>
  select(city, state, facility_name, facility_id) |>
  distinct() |>
  rename(ghgrp_id = facility_id)

eip_t20_food_bev = read_excel("Data/2025.04.17 Food & Beverage Top 20 Unit-Level Data- EIP.xlsx") |>
  clean_names() |>
  rename( total_ghg_co2e_metric_tons_eip_2023 = x2023_ghg_emissions_including_biogenic_co2_co2e_metric_tons,
         pm_2_5_tons_eip_2023 = x2023_pm2_5_emissions_tons,
         nox_tons_eip_2023 = x2023_n_ox_emissions_tons,
         voc_tons_eip_2023 = x2023_voc_emissions_tons,
         so2_tons_eip_2023 = x2023_so2_emissions_tons,
         co_tons_eip_2023 = x2023_co_emissions_tons,
         hap_lbs_eip_2023 = x2023_hap_emissions_lbs) |>
  mutate(total_ghg_notes = ifelse(grepl("Emissions", total_ghg_co2e_metric_tons_eip_2023), # create separate
                total_ghg_co2e_metric_tons_eip_2023, NA)) |>                  # variables for notes
  mutate(pm_2_5_notes = ifelse(grepl("Emissions", pm_2_5_tons_eip_2023), 
                               pm_2_5_tons_eip_2023, NA)) |>
  mutate(nox_notes = ifelse(grepl("Emissions", nox_tons_eip_2023), 
                               nox_tons_eip_2023, NA)) |>
  mutate(voc_notes = ifelse(grepl("Emissions", voc_tons_eip_2023), 
                            voc_tons_eip_2023, NA)) |>
  mutate(so2_notes = ifelse(grepl("Emissions", so2_tons_eip_2023), 
                            so2_tons_eip_2023, NA)) |>
  mutate(co_notes = ifelse(grepl("Emissions", co_tons_eip_2023),  
                            co_tons_eip_2023, NA)) |>
  mutate(hap_notes = ifelse(grepl("Emissions", hap_lbs_eip_2023), 
                           hap_lbs_eip_2023, NA)) |>
  mutate(total_ghg_co2e_metric_tons_eip_2023 = as.numeric(total_ghg_co2e_metric_tons_eip_2023)) |>
  mutate(pm_2_5_tons_eip_2023 = as.numeric(pm_2_5_tons_eip_2023)) |>
  mutate(nox_tons_eip_2023 = as.numeric(nox_tons_eip_2023)) |>
  mutate(voc_tons_eip_2023 = as.numeric(voc_tons_eip_2023)) |>
  mutate(so2_tons_eip_2023 = as.numeric(so2_tons_eip_2023)) |>
  mutate(co_tons_eip_2023 = as.numeric(co_tons_eip_2023)) |>
  mutate(hap_lbs_eip_2023 = as.numeric(hap_lbs_eip_2023)) |>
  left_join(y = facility_data, by = c("facility_name", "city", "state"))
  
  




