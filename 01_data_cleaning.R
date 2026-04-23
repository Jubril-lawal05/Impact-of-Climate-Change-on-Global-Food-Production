clean_data <- raw_data %>%
  select(
    crop,
    country,
    region,
    latitude,
    longitude,
    current_average_temperature_point_coordinate_d_c,
    current_annual_precipitation_mm_point_coordinate,
    local_delta_t,
    annual_precipitation_change_each_study_mm,
    global_delta_t_from_pre_industrial_period,
    climate_scenario,
    future_mid_point,
    projected_yield_t_ha,
    climate_impacts
  ) %>%
  drop_na()

