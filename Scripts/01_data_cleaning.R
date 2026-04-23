clean_data_v2 <- raw_data %>%
  select(
    crop,
    country,
    region,
    latitude,
    longitude,
    current_average_temperature_point_coordinate_d_c,
    current_annual_precipitation_mm_point_coordinate,
    global_delta_t_from_pre_industrial_period,
    annual_precipitation_change_each_study_mm,
    climate_scenario,
    future_mid_point,
    projected_yield_t_ha,
    climate_impacts,
    local_delta_t
  ) %>%
  mutate(
    drought_index = annual_precipitation_change_each_study_mm /
      current_annual_precipitation_mm_point_coordinate
  )
write.csv(clean_data_v2, "data/clean_data_v2.csv", row.names = FALSE)
