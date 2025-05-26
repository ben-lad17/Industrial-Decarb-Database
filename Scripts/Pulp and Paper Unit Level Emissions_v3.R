##################################################################
#                               
# Project 2035: Industrial Decarb
# 
# Version: 4
# February 24, 2024               
# Ben Ladabaum                  
#                               
# Description:  Create datast with unit-level process emissions for pulp and paper
#
# Notes:  _v2: append subpart AA emissions instead of merging. Subpart C and subpart AA 
#              have different unit names.
#         _v3: use v3 of combustion emissions dataset, which updated method for calculating 
#              biogenic emissions.
#         _v4: update pulp and paper naics codes to 322110 <=(NAICS code)<= 322139
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
  select(facility_id, reporting_year, primary_naics, secondary_naics)
is_unique_id(facilities_data, c("facility_id", "reporting_year"))

#spent liquor
spent_liquor = read_excel(here("Data/Subpart AA", "aa_spent_liquor_information.xlsx")) |>
  convert_to_numeric(c("biomass_ch4_emissions_factor", "biomass_n2o_emissions_factor"))
is_unique_id(spent_liquor, c("facility_id", "reporting_year", "unit_name"))

# fuel data
fossil_fuel_data = read_excel(here("Data/Subpart AA", "aa_fossil_fuel_information.xlsx")) 
is_unique_id(fossil_fuel_data, c("facility_id", "reporting_year", "unit_name", "fuel_type"))


### Process Emissions ###
spent_liquor_emissions = spent_liquor |>
  rename(biogenic_spent_liquor_co2_emissions = spent_liquor_co2_emissions) |>
  select(facility_id, reporting_year, starts_with("spent_liquor"), biogenic_spent_liquor_co2_emissions, 
         unit_name, unit_type)

emissions_by_unit = left_join(x = fossil_fuel_data, 
                                     facilities_data, by=c("facility_id", "reporting_year"))|>
  mutate(primary_naics_num = as.numeric(primary_naics)) |>
  filter(primary_naics_num >=  322110 & primary_naics_num <= 322139) |>
  left_join(y = spent_liquor_emissions, by = c("facility_id", "reporting_year", "unit_name")) |>
  mutate(fossil_fuel_co2_emissions = rowSums(cbind(tier_1_co2_emissions, tier_2_co2_emissions, 
                                                   tier_3_co2_emissions), na.rm = TRUE)) |>
  mutate(fossil_fuel_ch4_emissions = rowSums(cbind(tier_1_ch4_emissions, tier_2_ch4_emissions, 
                                                   tier_3_ch4_emissions), na.rm = TRUE)) |>
  mutate(fossil_fuel_ch4_emissions_co2e = rowSums(cbind(tier_1_ch4_emissions_co2e, tier_2_ch4_emissions_co2e, 
                                                        tier_3_ch4_emissions_co2e), na.rm = TRUE)) |>
  mutate(fossil_fuel_n2o_emissions = rowSums(cbind(tier_1_n2o_emissions, tier_2_n2o_emissions, 
                                                   tier_3_n2o_emissions), na.rm = TRUE)) |>
  mutate(fossil_fuel_n2o_emissions_co2e = rowSums(cbind(tier_1_n2o_emissions_co2e, tier_2_n2o_emissions_co2e, 
                                                        tier_3_n2o_emissions_co2e), na.rm = TRUE)) |>
  select(primary_naics, facility_id, reporting_year, unit_name, unit_type, fuel_type, 
         fossil_fuel_ch4_emissions, fossil_fuel_ch4_emissions_co2e, 
         fossil_fuel_co2_emissions, biogenic_spent_liquor_co2_emissions, 
         fossil_fuel_n2o_emissions, fossil_fuel_n2o_emissions_co2e, starts_with("spent_liquor")) |>
  pivot_longer(cols = c("fossil_fuel_ch4_emissions", "fossil_fuel_ch4_emissions_co2e", 
                        "fossil_fuel_co2_emissions", "biogenic_spent_liquor_co2_emissions", 
                        "fossil_fuel_n2o_emissions", "fossil_fuel_n2o_emissions_co2e",
                        "spent_liquor_ch4_emissions", "spent_liquor_n2o_emissions"), 
               names_to = "ghg_gas_name",
               values_to = "ghg_quantity")|>
  mutate(
    ghg_gas_name = case_when(
      ghg_gas_name == "fossil_fuel_co2_emissions" ~ "Carbon Dioxide Non-Biogenic",
      ghg_gas_name == "fossil_fuel_ch4_emissions" ~ "Methane",
      ghg_gas_name == "fossil_fuel_ch4_emissions_co2e" ~ "Methane (Co2 eq)",
      ghg_gas_name == "fossil_fuel_n2o_emissions" ~ "Nitrous Oxide",
      ghg_gas_name == "fossil_fuel_n2o_emissions_co2e" ~ "Nitrous Oxide (Co2 eq)",
      ghg_gas_name == "biogenic_spent_liquor_co2_emissions" ~ "Carbon Dioxide Biogenic (Spent Liquor)",
      ghg_gas_name == "spent_liquor_ch4_emissions" ~ "Methane Spent Liquor",
      ghg_gas_name == "spent_liquor_n2o_emissions" ~ "Nitrous Oxide Spent Liquor"
    )
  ) |>
  mutate(subpart = "AA") |>
  group_by(primary_naics, facility_id, reporting_year, unit_name, unit_type, ghg_gas_name, subpart) |>
  summarise(
    ghg_quantity = sum(ghg_quantity, na.rm = TRUE)
  ) |>
  ungroup() |>
  filter(!(ghg_gas_name %in% c("Nitrous Oxide (Co2 eq)", "Methane (Co2 eq)"))) # remove this line 
                                                          # once emissions factor issue is resolved



### Combine with combustion emissions ###

# load subpart c emissions dataset
subpart_c = read_csv(here("Output", "subpart_c_emissions_and_fuel_by_unit_v3.csv")) |>
  mutate(primary_naics = as.character(primary_naics))|>
  mutate(primary_naics_num = as.numeric(primary_naics)) |>
  filter(primary_naics_num >=  322110 & primary_naics_num <= 322139) |>
  select(-primary_naics_num) |>
  filter(!(ghg_gas_name %in% c("Nitrous Oxide (Co2 eq)", "Methane (Co2 eq)"))) # remove this line 
# once emissions factor issue is resolved

is_unique_id(subpart_c, c("facility_id", "reporting_year", "unit_name", 
                          "fuel_type", "ghg_gas_name"))


# Append subpart c and subpart aa
pulp_paper_emissions_by_unit = subpart_c |>
  bind_rows(emissions_by_unit) |>
  arrange(facility_id, reporting_year, unit_name, 
            fuel_type, ghg_gas_name)

pulp_paper_emissions_by_unit_2023 = pulp_paper_emissions_by_unit |>
  filter(reporting_year==2023)


### export ###
export_facility_unit_data(
  industry = "pulp_paper",
  version = "v4",
  file_type = "unit",
  datasets = list(
    "unit_emissions" = pulp_paper_emissions_by_unit,
    "unit_emissions_2023" = pulp_paper_emissions_by_unit_2023
  )
)

