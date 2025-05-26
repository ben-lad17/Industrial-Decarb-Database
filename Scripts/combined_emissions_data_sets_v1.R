##################################################################
#                               
# Project 2035: Industrial Decarb
# 
# Version: 1
# April 21, 2025               
# Ben Ladabaum                  
#                               
# Description:  Create combined datasets for: 1) descriptive plant level information
#                                             2) Plant level emissions
#                                             3) Unit level emissions
#
# Notes:  
# 
# Inputs:   
#         
#
# Outputs:   
#
##################################################################

# Load libraries
library(here)
library(janitor) 
library(readxl)
library(writexl)
library(tidyverse)
library(openxlsx)


# Define directory where files are saved
data_dir = here("Output")

# List of specific files to import
descr_files = list.files(path = data_dir, pattern = "descr_info.*\\.xlsx$", full.names = TRUE)
plant_files = list.files(path = data_dir, pattern = "emissions_by_facility.*\\.xlsx$", full.names = TRUE)
plant_files = plant_files[!grepl("subpart_c", plant_files)] # remove subpart_c file from plant files
unit_files = list.files(path = data_dir, pattern = "emissions_by_unit.*\\.xlsx$", full.names = TRUE)
unit_files = unit_files[!grepl("subpart_c", unit_files)] # remove subpart_c file from unit level files

# Read and combine the "descr_info" sheet from each file
descr_info <- descr_files |>
  map_dfr(~ {
    read_excel(path = .x, sheet = "descr_info") |>
      mutate(source_file = basename(.x))
  })|>
  select(-secondary_naics_325193)

descr_info_2023 = descr_files |>
  map_dfr(~ {
    read_excel(path = .x, sheet = "descr_info_2023") |>
      mutate(source_file = basename(.x))
  })|>
  select(-secondary_naics_325193)

# combine plant level emissions
plant_emissions <- plant_files |>
  map_dfr(~ {
    read_excel(path = .x, sheet = "facility_emissions") |>
      mutate(source_file = basename(.x))
  })|>
  select(-c(secondary_naics_325193, facility_name, byproducts, other_pollutants, pct_co2e_declared_cu,
            product_outputs, employment, annual_production_qty, plant_size, source_file),
         byproducts, other_pollutants, pct_co2e_declared_cu,
         product_outputs, employment, annual_production_qty, plant_size, source_file)

plant_emissions_2023 <- plant_files |>
  map_dfr(~ {
    read_excel(path = .x, sheet = "facility_emissions_2023") |>
      mutate(source_file = basename(.x))
  })|>
  select(-c(secondary_naics_325193, facility_name, byproducts, other_pollutants, pct_co2e_declared_cu,
            product_outputs, employment, annual_production_qty, plant_size, source_file),
         byproducts, other_pollutants, pct_co2e_declared_cu,
         product_outputs, employment, annual_production_qty, plant_size, source_file)


# combine unit level emissions
unit_emissions = unit_files |>
  map_dfr(~ {
    read_excel(path = .x, sheet = "unit_emissions") |>
      mutate(source_file = basename(.x))
  })|>
  select(primary_naics, facility_id, reporting_year, unit_type, unit_name, anaerobic_process_id,
         everything())

unit_emissions_2023 = unit_files |>
  map_dfr(~ {
    read_excel(path = .x, sheet = "unit_emissions_2023") |>
      mutate(source_file = basename(.x))
  })|>
  select(primary_naics, facility_id, reporting_year, unit_type, unit_name, anaerobic_process_id,
         everything())




### export ###
to_export_full = createWorkbook()
to_export_2023 = createWorkbook()

# Add worksheets and write data for all years
addWorksheet(to_export_full, "descr_info")
writeData(to_export_full, "descr_info", descr_info)

addWorksheet(to_export_full, "facility_emissions")
writeData(to_export_full, "facility_emissions", plant_emissions)

addWorksheet(to_export_full, "unit_emissions")
writeData(to_export_full, "unit_emissions", unit_emissions)


# Add worksheets and write data for 2023
addWorksheet(to_export_2023, "descr_info_2023")
writeData(to_export_2023, "descr_info_2023", descr_info_2023)

addWorksheet(to_export_2023, "facility_emissions_2023")
writeData(to_export_2023, "facility_emissions_2023", plant_emissions_2023)

addWorksheet(to_export_2023, "unit_emissions_2023")
writeData(to_export_2023, "unit_emissions_2023", unit_emissions_2023)


# Save the workbooks
saveWorkbook(to_export_full, here("Output", "emissions_output_all_naics_codes_v1.xlsx"), overwrite = TRUE)
saveWorkbook(to_export_2023, 
             here("Output", "emissions_output_all_naics_codes_2023_v1.xlsx"), overwrite = TRUE)




### Sanity checks: confirm each file was only appended once
file_counts_descr <- descr_info |>
  count(source_file, name = "n_rows")
print(file_counts_descr)

file_counts_descr_2023 <- descr_info_2023 |>
  count(source_file, name = "n_rows")
print(file_counts_descr_2023)


plant_counts_descr <- plant_emissions |>
  count(source_file, name = "n_rows")
print(plant_counts_descr)

plant_counts_descr_2023 <- plant_emissions_2023 |>
  count(source_file, name = "n_rows")
print(plant_counts_descr_2023)


unit_counts_descr <- unit_emissions |>
  count(source_file, name = "n_rows")
print(unit_counts_descr)

unit_counts_descr_2023 <- unit_emissions_2023 |>
  count(source_file, name = "n_rows")
print(unit_counts_descr_2023)

