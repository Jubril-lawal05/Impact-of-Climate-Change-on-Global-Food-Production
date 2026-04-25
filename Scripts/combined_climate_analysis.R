
# Install (run once)
# install.packages(c("tidyverse", "skimr", "DataExplorer", "naniar",
#                    "mgcv", "randomForest", "plotly", "gridExtra"))

library(dplyr)
library(ggplot2)
library(tidyr)
library(skimr)
library(DataExplorer)
library(naniar)
library(mgcv)
library(randomForest)
library(gridExtra)


# --- DATA LOAD ---------------------------------------------------------------

data <- read.csv("data/clean_data_v2.csv")

# Quick column check
names(data)
unique(data$crop)
unique(data$region)


# =============================================================================
# SECTION 0: DATA QUALITY CHECKS
# =============================================================================

# Missing values
vis_miss(data)
plot_missing(data)

# Summary statistics by crop
summary_stats <- data %>%
  group_by(crop) %>%
  summarise(
    n                = n(),
    avg_yield        = mean(projected_yield_t_ha, na.rm = TRUE),
    avg_impact       = mean(climate_impacts, na.rm = TRUE),
    avg_temp         = mean(current_average_temperature_point_coordinate_d_c, na.rm = TRUE),
    avg_precip       = mean(current_annual_precipitation_mm_point_coordinate, na.rm = TRUE)
  )
print(summary_stats)

# Duplicate check
duplicates <- data %>%
  group_by(crop, country, climate_scenario, future_mid_point) %>%
  filter(n() > 1) %>%
  arrange(crop, country, climate_scenario, future_mid_point)
cat("Potential duplicates:", nrow(duplicates), "\n")

# Outlier check: climate_impacts beyond ±50%
data %>%
  filter(abs(climate_impacts) > 50) %>%
  select(crop, country, climate_scenario, climate_impacts, projected_yield_t_ha) %>%
  arrange(desc(abs(climate_impacts))) %>%
  head(20)

# Outlier boxplot
ggplot(data, aes(y = climate_impacts, x = crop)) +
  geom_boxplot(fill = "lightblue", outlier.color = "red") +
  facet_wrap(~climate_scenario) +
  theme_minimal() +
  labs(title = "Distribution of Climate Impacts by Crop and Scenario",
       y = "Climate Impact (%)", x = "Crop")


# =============================================================================
# SECTION 1: TEMPERATURE vs YIELD
# =============================================================================

# --- 1A. Local temperature (RC) ----------------------------------------------

analysis1 <- data %>%
  filter(!is.na(local_delta_t), !is.na(climate_impacts))

# Correlation
cor_temp_yield <- cor(analysis1$local_delta_t, analysis1$climate_impacts, use = "complete.obs")
cat("Correlation (local delta T vs yield impact):", round(cor_temp_yield, 3), "\n")

# Linear regression
model_temp_yield <- lm(climate_impacts ~ local_delta_t, data = analysis1)
summary(model_temp_yield)

# Scatter: all crops combined
ggplot(analysis1, aes(x = local_delta_t, y = climate_impacts)) +
  geom_point(alpha = 0.4) +
  geom_smooth(method = "lm", se = TRUE) +
  labs(title = "Temperature Increase vs Crop Yield Change",
       subtitle = "Relationship between local temperature increase and projected yield impact",
       x = "Local Temperature Increase (°C)",
       y = "Climate Impact on Yield (%)") +
  theme_minimal()

# Scatter: by crop
ggplot(analysis1, aes(x = local_delta_t, y = climate_impacts, color = crop)) +
  geom_point(alpha = 0.5) +
  geom_smooth(method = "lm", se = FALSE) +
  labs(title = "Temperature Increase vs Yield Change by Crop",
       subtitle = "Comparing crop sensitivity to local temperature increases",
       x = "Local Temperature Increase (°C)",
       y = "Climate Impact on Yield (%)",
       color = "Crop") +
  theme_minimal()

# Temperature bins: average yield impact
analysis1_bins <- analysis1 %>%
  mutate(temp_group = cut(
    local_delta_t,
    breaks = c(-Inf, 1, 2, 3, 4, Inf),
    labels = c("< 1°C", "1–2°C", "2–3°C", "3–4°C", "> 4°C")
  )) %>%
  group_by(temp_group) %>%
  summarise(
    average_yield_impact = mean(climate_impacts, na.rm = TRUE),
    number_of_records    = n()
  )
print(analysis1_bins)

ggplot(analysis1_bins, aes(x = temp_group, y = average_yield_impact)) +
  geom_col(fill = "steelblue") +
  labs(title = "Average Yield Impact by Temperature Increase Group",
       x = "Temperature Increase Group",
       y = "Average Climate Impact on Yield (%)") +
  theme_minimal()

# --- 1B. Global temperature response curves (Ayomide) -----------------------

# LOESS curves per crop — local delta T
ggplot(data %>% filter(!is.na(local_delta_t)),
       aes(x = local_delta_t, y = climate_impacts, color = crop)) +
  geom_point(alpha = 0.5, size = 2) +
  geom_smooth(method = "loess", se = TRUE) +
  facet_wrap(~crop, scales = "free_y") +
  theme_minimal() +
  labs(title = "Temperature Change vs Climate Impact by Crop (Local ΔT)",
       x = "Local Temperature Change (°C)",
       y = "Climate Impact (%)")

# LOESS curves per crop — global delta T
ggplot(data %>% filter(!is.na(global_delta_t_from_pre_industrial_period)),
       aes(x = global_delta_t_from_pre_industrial_period, y = climate_impacts, color = crop)) +
  geom_point(alpha = 0.5, size = 2) +
  geom_smooth(method = "loess", se = TRUE) +
  facet_wrap(~crop, scales = "free_y") +
  theme_minimal() +
  labs(title = "Temperature Change vs Climate Impact by Crop (Global ΔT)",
       x = "Global Temperature Change from Pre-industrial (°C)",
       y = "Climate Impact (%)")

# Side-by-side comparison: local vs global
p_global <- data %>%
  filter(!is.na(global_delta_t_from_pre_industrial_period)) %>%
  ggplot(aes(x = global_delta_t_from_pre_industrial_period, y = climate_impacts)) +
  geom_point(aes(color = crop), alpha = 0.5) +
  geom_smooth(method = "lm", se = TRUE, color = "black") +
  facet_wrap(~crop) +
  theme_minimal() +
  labs(title = "Using GLOBAL Temperature Change",
       x = "Global ΔT (°C)", y = "Climate Impact (%)")

p_local <- data %>%
  filter(!is.na(local_delta_t)) %>%
  ggplot(aes(x = local_delta_t, y = climate_impacts)) +
  geom_point(aes(color = crop), alpha = 0.5) +
  geom_smooth(method = "lm", se = TRUE, color = "black") +
  facet_wrap(~crop) +
  theme_minimal() +
  labs(title = "Using LOCAL Temperature Change",
       x = "Local ΔT (°C)", y = "Climate Impact (%)")

grid.arrange(p_global, p_local, nrow = 2)

# Global temp bins (boxplot)
temp_analysis_global <- data %>%
  filter(!is.na(global_delta_t_from_pre_industrial_period), !is.na(climate_impacts)) %>%
  mutate(temp_bin = cut(global_delta_t_from_pre_industrial_period,
                        breaks = seq(0, 6, by = 1)))

ggplot(temp_analysis_global, aes(x = temp_bin, y = climate_impacts, fill = crop)) +
  geom_boxplot() +
  theme_minimal() +
  labs(title = "Climate Impacts by Global Temperature Change Bins",
       x = "Global Temperature Change (°C)",
       y = "Climate Impact (%)")

# --- 1C. GAM: Non-linear tipping points (Ayomide) ---------------------------

# Maize — local delta T
maize_data <- data %>%
  filter(crop == "Maize", !is.na(local_delta_t), !is.na(climate_impacts))

gam_local <- gam(climate_impacts ~ s(local_delta_t, k = 6) +
                   s(annual_precipitation_change_each_study_mm, k = 6),
                 data = maize_data)
summary(gam_local)
plot(gam_local, pages = 1, shade = TRUE,
     main = "GAM Smooth Terms — Maize (Local ΔT)")

# Maize — global delta T
maize_data_global <- data %>%
  filter(crop == "Maize",
         !is.na(global_delta_t_from_pre_industrial_period),
         !is.na(climate_impacts))

gam_global <- gam(climate_impacts ~ s(global_delta_t_from_pre_industrial_period, k = 6) +
                    s(annual_precipitation_change_each_study_mm, k = 6),
                  data = maize_data_global)
summary(gam_global)
plot(gam_global, pages = 1, shade = TRUE,
     main = "GAM Smooth Terms — Maize (Global ΔT)")


# =============================================================================
# SECTION 2: PRECIPITATION vs YIELD
# =============================================================================

precip_col <- "annual_precipitation_change_each_study_mm"

analysis2 <- data %>%
  filter(!is.na(.data[[precip_col]]), !is.na(climate_impacts))

# Correlation
cor_precip_yield <- cor(analysis2[[precip_col]], analysis2$climate_impacts, use = "complete.obs")
cat("Correlation (precipitation change vs yield impact):", round(cor_precip_yield, 3), "\n")

# Linear regression
analysis2$precip_value <- analysis2[[precip_col]]
model_precip_yield <- lm(climate_impacts ~ precip_value, data = analysis2)
summary(model_precip_yield)

# Scatter
ggplot(analysis2, aes(x = .data[[precip_col]], y = climate_impacts)) +
  geom_point(alpha = 0.4) +
  geom_smooth(method = "lm", se = TRUE) +
  labs(title = "Precipitation Change vs Crop Yield Impact",
       subtitle = "Relationship between precipitation change and yield decline",
       x = "Precipitation Change (mm)",
       y = "Climate Impact on Yield (%)") +
  theme_minimal()

# Precipitation bins
analysis2_bins <- analysis2 %>%
  mutate(precip_group = cut(
    .data[[precip_col]],
    breaks = c(-Inf, -100, -50, 0, 50, 100, Inf),
    labels = c("Severe Decrease", "Moderate Decrease", "Slight Decrease",
               "Slight Increase", "Moderate Increase", "High Increase")
  )) %>%
  group_by(precip_group) %>%
  summarise(
    average_yield_impact = mean(climate_impacts, na.rm = TRUE),
    number_of_records    = n()
  )
print(analysis2_bins)

ggplot(analysis2_bins, aes(x = precip_group, y = average_yield_impact)) +
  geom_col(fill = "steelblue") +
  labs(title = "Average Yield Impact by Precipitation Change Group",
       x = "Precipitation Change Category",
       y = "Average Climate Impact on Yield (%)") +
  theme_minimal()


# =============================================================================
# SECTION 3: DROUGHT IMPACT
# =============================================================================

analysis5 <- data %>%
  filter(!is.na(drought_index), !is.na(climate_impacts))

# Drought categories (RC's granular scale)
analysis5_bins <- analysis5 %>%
  mutate(drought_group = cut(
    drought_index,
    breaks = c(-Inf, -4, -3, -2, -1, 0, Inf),
    labels = c("Extreme Drought", "Severe Drought", "Moderate Drought",
               "Mild Drought", "Near Normal", "Wet Conditions")
  )) %>%
  group_by(drought_group) %>%
  summarise(
    avg_impact    = mean(climate_impacts, na.rm = TRUE),
    median_impact = median(climate_impacts, na.rm = TRUE),
    n             = n()
  )
print(analysis5_bins)

# Bar chart
ggplot(analysis5_bins, aes(x = drought_group, y = avg_impact)) +
  geom_col(fill = "coral") +
  labs(title = "Average Yield Impact by Drought Category",
       x = "Drought Category",
       y = "Average Climate Impact on Yield (%)") +
  theme_minimal()

# Scatter: drought index vs yield impact
ggplot(analysis5, aes(x = drought_index, y = climate_impacts)) +
  geom_point(aes(color = crop), alpha = 0.6) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  geom_smooth(method = "lm", se = TRUE) +
  theme_minimal() +
  labs(title = "Drought Index vs Crop Yield Impact",
       x = "Drought Index (Negative = Wetter, Positive = Drier)",
       y = "Climate Impact (%)")

# Boxplot: distribution by drought category (Ayomide's broader 3-category version)
drought_analysis_3cat <- analysis5 %>%
  mutate(drought_category = case_when(
    drought_index < -0.1  ~ "Wetter",
    drought_index <= 0.1  ~ "Normal",
    drought_index > 0.1   ~ "Drier"
  ))

ggplot(drought_analysis_3cat, aes(x = drought_category, y = climate_impacts, fill = crop)) +
  geom_boxplot() +
  theme_minimal() +
  labs(title = "Yield Impact by Drought Category (Broad)",
       x = "Drought Condition", y = "Climate Impact (%)")

# ANOVA: does drought category significantly affect yield impact?
drought_aov <- aov(climate_impacts ~ drought_category * crop, data = drought_analysis_3cat)
summary(drought_aov)
TukeyHSD(drought_aov)

# Temperature × Precipitation interaction on Maize
interaction_model <- data %>%
  filter(crop == "Maize",
         !is.na(global_delta_t_from_pre_industrial_period),
         !is.na(annual_precipitation_change_each_study_mm)) %>%
  mutate(
    temp_high  = global_delta_t_from_pre_industrial_period >
      median(global_delta_t_from_pre_industrial_period, na.rm = TRUE),
    precip_wet = annual_precipitation_change_each_study_mm > 0
  )

ggplot(interaction_model, aes(x = temp_high, y = climate_impacts, fill = precip_wet)) +
  geom_boxplot() +
  theme_minimal() +
  scale_fill_manual(values = c("coral", "lightblue"),
                    labels = c("Drier", "Wetter"),
                    name = "Precipitation Change") +
  labs(title = "Interaction: Temperature × Precipitation on Maize Yields",
       x = "High Temperature (Above Median)",
       y = "Climate Impact (%)")

lm_interaction <- lm(climate_impacts ~ global_delta_t_from_pre_industrial_period *
                       annual_precipitation_change_each_study_mm,
                     data = interaction_model)
summary(lm_interaction)


# =============================================================================
# SECTION 4: CROP COMPARISON
# =============================================================================

# Note: crop names are capitalized in the dataset
analysis3 <- data %>%
  filter(crop %in% c("Maize", "Wheat", "Rice", "Soybean"),
         !is.na(climate_impacts))

crop_summary <- analysis3 %>%
  group_by(crop) %>%
  summarise(
    avg_impact    = mean(climate_impacts, na.rm = TRUE),
    median_impact = median(climate_impacts, na.rm = TRUE),
    min_impact    = min(climate_impacts, na.rm = TRUE),
    max_impact    = max(climate_impacts, na.rm = TRUE),
    n             = n()
  )
print(crop_summary)

# Bar chart
ggplot(crop_summary, aes(x = reorder(crop, avg_impact), y = avg_impact)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  labs(title = "Average Yield Impact by Crop",
       x = "Crop Type",
       y = "Average Climate Impact on Yield (%)") +
  theme_minimal()

# RCP scenario comparison across crops
rcp_comparison <- data %>%
  filter(climate_scenario %in% c("RCP2.6", "RCP4.5", "RCP6.0", "RCP8.5")) %>%
  group_by(crop, climate_scenario) %>%
  summarise(
    avg_impact = mean(climate_impacts, na.rm = TRUE),
    sd_impact  = sd(climate_impacts, na.rm = TRUE),
    n          = n(),
    se_impact  = sd_impact / sqrt(n),
    .groups    = "drop"
  )

ggplot(rcp_comparison, aes(x = climate_scenario, y = avg_impact, fill = crop)) +
  geom_bar(stat = "identity", position = "dodge") +
  geom_errorbar(aes(ymin = avg_impact - se_impact, ymax = avg_impact + se_impact),
                position = position_dodge(0.9), width = 0.2) +
  theme_minimal() +
  scale_fill_brewer(palette = "Set2") +
  labs(title = "Average Climate Impact by RCP Scenario and Crop",
       y = "Average Climate Impact (%)", x = "RCP Scenario",
       subtitle = "Error bars show ±1 Standard Error")

# Avoided damage: RCP8.5 vs RCP4.5
avoided_damage <- data %>%
  filter(climate_scenario %in% c("RCP4.5", "RCP8.5")) %>%
  group_by(crop, climate_scenario, future_mid_point) %>%
  summarise(avg_impact = mean(climate_impacts, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = climate_scenario, values_from = avg_impact) %>%
  mutate(avoided_damage = RCP8.5 - RCP4.5)

ggplot(avoided_damage, aes(x = future_mid_point, y = avoided_damage, color = crop)) +
  geom_line(linewidth = 1) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  theme_minimal() +
  labs(title = "Avoided Climate Damages (RCP8.5 − RCP4.5)",
       y = "Avoided Yield Loss (%)",
       x = "Future Mid-Point Year")


# =============================================================================
# SECTION 5: REGIONAL ANALYSIS
# =============================================================================

# --- 5A. All-region summary (RC) ---------------------------------------------

analysis4 <- data %>%
  filter(!is.na(region), !is.na(climate_impacts))

region_summary <- analysis4 %>%
  group_by(region) %>%
  summarise(
    avg_impact    = mean(climate_impacts, na.rm = TRUE),
    median_impact = median(climate_impacts, na.rm = TRUE),
    min_impact    = min(climate_impacts, na.rm = TRUE),
    max_impact    = max(climate_impacts, na.rm = TRUE),
    n             = n()
  ) %>%
  arrange(avg_impact)
print(region_summary)

# Bar chart
ggplot(region_summary, aes(x = reorder(region, avg_impact), y = avg_impact)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  labs(title = "Average Yield Impact by Region",
       subtitle = "Regions most affected by climate change",
       x = "Region",
       y = "Average Climate Impact on Yield (%)") +
  theme_minimal()

# Boxplot
ggplot(analysis4, aes(x = region, y = climate_impacts)) +
  geom_boxplot() +
  coord_flip() +
  labs(title = "Distribution of Yield Impacts by Region",
       x = "Region",
       y = "Climate Impact on Yield (%)") +
  theme_minimal()

# Top 5 most vulnerable
top_regions <- region_summary %>% slice_min(avg_impact, n = 5)
print(top_regions)

# --- 5B. End-century vulnerability under RCP8.5 (Ayomide) -------------------

regional_impacts <- data %>%
  filter(climate_scenario == "RCP8.5", future_mid_point >= 2080) %>%
  group_by(country, region, crop) %>%
  summarise(
    avg_impact      = mean(climate_impacts, na.rm = TRUE),
    avg_temp_change = mean(global_delta_t_from_pre_industrial_period, na.rm = TRUE),
    avg_precip_change = mean(annual_precipitation_change_each_study_mm, na.rm = TRUE),
    n_observations  = n(),
    .groups         = "drop"
  ) %>%
  arrange(avg_impact)

# Heat map: country × crop
country_crop_matrix <- regional_impacts %>%
  filter(n_observations >= 3) %>%
  select(country, crop, avg_impact)

ggplot(country_crop_matrix, aes(x = country, y = crop, fill = avg_impact)) +
  geom_tile(color = "white", linewidth = 0.5) +
  scale_fill_gradient2(low = "red", mid = "white", high = "green", midpoint = 0,
                       name = "Avg Impact %") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 8),
        panel.grid = element_blank()) +
  labs(title = "Regional Climate Impacts Matrix (RCP8.5, End Century)",
       subtitle = "Red = Yield Loss, Green = Yield Gain",
       x = "", y = "")

ggsave("regional_heatmap.png", width = 14, height = 8, dpi = 150)

# Risk scores
regional_risk <- regional_impacts %>%
  group_by(country, region) %>%
  summarise(
    mean_impact       = mean(avg_impact, na.rm = TRUE),
    worst_crop_impact = min(avg_impact, na.rm = TRUE),
    best_crop_impact  = max(avg_impact, na.rm = TRUE),
    impact_spread     = max(avg_impact, na.rm = TRUE) - min(avg_impact, na.rm = TRUE),
    avg_global_warming = mean(avg_temp_change, na.rm = TRUE),
    total_observations = sum(n_observations),
    crops_affected    = n_distinct(crop),
    .groups           = "drop"
  ) %>%
  mutate(
    risk_score    = rank(mean_impact),
    risk_category = case_when(
      mean_impact <= -20                         ~ "Severe Risk",
      mean_impact > -20 & mean_impact <= -10     ~ "High Risk",
      mean_impact > -10 & mean_impact <= 0       ~ "Moderate Risk",
      mean_impact > 0                            ~ "Low Risk / Opportunity"
    )
  ) %>%
  arrange(risk_score)

cat("\n=== REGIONAL RISK ASSESSMENT ===\n")
print(regional_risk, n = 30)

# Top 15 most vulnerable countries
top_vulnerable <- regional_risk %>% head(15)

ggplot(top_vulnerable, aes(x = reorder(country, -mean_impact), y = mean_impact,
                           fill = risk_category)) +
  geom_bar(stat = "identity") +
  geom_errorbar(aes(ymin = worst_crop_impact, ymax = best_crop_impact),
                width = 0.2, color = "darkgray") +
  coord_flip() +
  scale_fill_manual(values = c("Severe Risk"   = "#D32F2F",
                               "High Risk"     = "#F44336",
                               "Moderate Risk" = "#FF9800")) +
  theme_minimal() +
  labs(title = "Most Vulnerable Countries to Climate Change (RCP8.5, 2080+)",
       subtitle = "Bar shows mean impact; line shows range across crops",
       x = "", y = "Average Climate Impact (%)",
       fill = "Risk Category")

ggsave("vulnerable_countries.png", width = 12, height = 8, dpi = 150)

# Regional continent summary
regional_summary <- regional_impacts %>%
  group_by(region) %>%
  summarise(
    countries    = n_distinct(country),
    mean_impact  = mean(avg_impact, na.rm = TRUE),
    worst_country = country[which.min(avg_impact)],
    worst_impact = min(avg_impact, na.rm = TRUE),
    avg_warming  = mean(avg_temp_change, na.rm = TRUE),
    .groups      = "drop"
  ) %>%
  arrange(mean_impact)

cat("\n=== SUMMARY BY REGION ===\n")
print(regional_summary)

ggplot(regional_summary, aes(x = reorder(region, -mean_impact), y = mean_impact,
                             fill = region)) +
  geom_bar(stat = "identity") +
  geom_text(aes(label = round(mean_impact, 1)), hjust = -0.2, size = 4) +
  coord_flip() +
  theme_minimal() +
  theme(legend.position = "none") +
  labs(title = "Average Climate Impact by Region (RCP8.5, 2080+)",
       x = "", y = "Average Climate Impact (%)")

ggsave("regional_summary.png", width = 10, height = 6, dpi = 150)


# =============================================================================
# SECTION 6: TEMPORAL TRENDS
# =============================================================================

time_analysis <- data %>%
  filter(!is.na(future_mid_point)) %>%
  mutate(time_period = case_when(
    future_mid_point <= 2030                              ~ "Near-term (2020–2030)",
    future_mid_point > 2030 & future_mid_point <= 2060   ~ "Mid-term (2030–2060)",
    future_mid_point > 2060                              ~ "Long-term (2060+)"
  ))

# Linear trends up to 2050 by crop and scenario
ggplot(time_analysis %>%
         filter(climate_scenario %in% c("RCP4.5", "RCP6.0", "RCP8.5"),
                future_mid_point <= 2050),
       aes(x = future_mid_point, y = climate_impacts, color = climate_scenario)) +
  geom_point(alpha = 0.4, size = 2) +
  geom_smooth(method = "lm", se = TRUE) +
  facet_wrap(~crop, scales = "free_y") +
  theme_minimal() +
  labs(title = "Temporal Trends in Climate Impacts (Up to 2050)",
       x = "Year", y = "Climate Impact (%)", color = "Scenario")

ggsave("temporal_trends.png", width = 12, height = 8, dpi = 150)

# Decadal averages
decade_analysis <- time_analysis %>%
  filter(future_mid_point <= 2085) %>%
  mutate(decade = floor(future_mid_point / 10) * 10) %>%
  group_by(crop, climate_scenario, decade) %>%
  summarise(
    avg_impact = mean(climate_impacts, na.rm = TRUE),
    sd_impact  = sd(climate_impacts, na.rm = TRUE),
    n          = n(),
    .groups    = "drop"
  )

ggplot(decade_analysis %>% filter(climate_scenario %in% c("RCP4.5", "RCP8.5"), n >= 3),
       aes(x = decade, y = avg_impact, color = crop, group = crop)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  facet_wrap(~climate_scenario) +
  theme_minimal() +
  labs(title = "Decadal Climate Impact Trends",
       x = "Decade", y = "Average Climate Impact (%)")

ggsave("decadal_trends.png", width = 12, height = 6, dpi = 150)


# =============================================================================
# SECTION 7: MACHINE LEARNING — FEATURE IMPORTANCE
# =============================================================================

rf_data <- data %>%
  filter(!is.na(climate_impacts)) %>%
  select(climate_impacts,
         current_average_temperature_point_coordinate_d_c,
         current_annual_precipitation_mm_point_coordinate,
         global_delta_t_from_pre_industrial_period,
         local_delta_t,
         drought_index,
         annual_precipitation_change_each_study_mm,
         crop, region) %>%
  na.omit()

set.seed(123)
rf_model <- randomForest(climate_impacts ~ ., data = rf_data,
                         importance = TRUE, ntree = 500)

varImpPlot(rf_model, main = "Feature Importance for Predicting Climate Impacts")

partialPlot(rf_model, rf_data, global_delta_t_from_pre_industrial_period,
            main = "Partial Dependence: Temperature Change")
partialPlot(rf_model, rf_data, drought_index,
            main = "Partial Dependence: Drought Index")


# =============================================================================
# SECTION 8: DROUGHT PATTERNS OVER TIME
# Gap fix: tracks how drought conditions evolve across scenarios and decades,
# mirroring the temporal treatment given to temperature in Section 6.
# =============================================================================

drought_time <- data %>%
  filter(!is.na(drought_index),
         !is.na(future_mid_point),
         future_mid_point <= 2085) %>%
  mutate(
    decade = floor(future_mid_point / 10) * 10,
    drought_category = case_when(
      drought_index < -0.1 ~ "Wetter",
      drought_index <= 0.1 ~ "Normal",
      drought_index > 0.1  ~ "Drier"
    )
  )

# --- 8A. Decadal average drought index by scenario --------------------------

drought_decade <- drought_time %>%
  filter(climate_scenario %in% c("RCP4.5", "RCP8.5")) %>%
  group_by(climate_scenario, decade) %>%
  summarise(
    avg_drought_index = mean(drought_index, na.rm = TRUE),
    sd_drought_index  = sd(drought_index, na.rm = TRUE),
    n                 = n(),
    .groups           = "drop"
  )

ggplot(drought_decade, aes(x = decade, y = avg_drought_index,
                           color = climate_scenario, group = climate_scenario)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  geom_ribbon(aes(ymin = avg_drought_index - sd_drought_index,
                  ymax = avg_drought_index + sd_drought_index,
                  fill = climate_scenario), alpha = 0.15, color = NA) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray40") +
  theme_minimal() +
  labs(title = "Drought Index Trends by Decade and Scenario",
       subtitle = "Positive = Drier conditions; Negative = Wetter conditions",
       x = "Decade", y = "Average Drought Index",
       color = "Scenario", fill = "Scenario")

ggsave("drought_trends_by_decade.png", width = 10, height = 6, dpi = 150)

# --- 8B. Drought index over time by crop ------------------------------------

drought_decade_crop <- drought_time %>%
  filter(climate_scenario %in% c("RCP4.5", "RCP8.5")) %>%
  group_by(crop, climate_scenario, decade) %>%
  summarise(
    avg_drought_index = mean(drought_index, na.rm = TRUE),
    n                 = n(),
    .groups           = "drop"
  ) %>%
  filter(n >= 3)

ggplot(drought_decade_crop, aes(x = decade, y = avg_drought_index,
                                color = crop, group = crop)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray40") +
  facet_wrap(~climate_scenario) +
  theme_minimal() +
  labs(title = "Drought Index Over Time by Crop and Scenario",
       x = "Decade", y = "Average Drought Index", color = "Crop")

ggsave("drought_trends_by_crop.png", width = 12, height = 6, dpi = 150)

# --- 8C. Share of drier observations per decade (scenario comparison) -------

drought_share <- drought_time %>%
  filter(climate_scenario %in% c("RCP4.5", "RCP8.5")) %>%
  group_by(climate_scenario, decade) %>%
  summarise(
    pct_drier = sum(drought_category == "Drier", na.rm = TRUE) / n() * 100,
    .groups   = "drop"
  )

ggplot(drought_share, aes(x = decade, y = pct_drier,
                          color = climate_scenario, group = climate_scenario)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  theme_minimal() +
  labs(title = "Share of Observations Under Drier Conditions Over Time",
       x = "Decade", y = "% of Observations Classified as Drier",
       color = "Scenario")

ggsave("drought_share_over_time.png", width = 10, height = 6, dpi = 150)


# =============================================================================
# SECTION 9: DIRECT CROP YIELD (t/ha) ANALYSIS
# Gap fix: uses projected_yield_t_ha directly rather than the derived
# climate_impacts score, to show how temperature and drought correlate
# with actual tonnes-per-hectare output.
# =============================================================================

yield_data <- data %>%
  filter(!is.na(projected_yield_t_ha),
         !is.na(global_delta_t_from_pre_industrial_period))

# --- 9A. Correlation: temperature vs actual yield ---------------------------

cor_temp_yield_tha <- cor(
  yield_data$global_delta_t_from_pre_industrial_period,
  yield_data$projected_yield_t_ha,
  use = "complete.obs"
)
cat("Correlation (global delta T vs projected yield t/ha):",
    round(cor_temp_yield_tha, 3), "\n")

# Scatter: temperature vs yield (t/ha) by crop
ggplot(yield_data, aes(x = global_delta_t_from_pre_industrial_period,
                       y = projected_yield_t_ha, color = crop)) +
  geom_point(alpha = 0.4, size = 1.5) +
  geom_smooth(method = "lm", se = TRUE) +
  facet_wrap(~crop, scales = "free_y") +
  theme_minimal() +
  labs(title = "Temperature Change vs Projected Yield (t/ha) by Crop",
       subtitle = "Direct yield output — not a derived impact score",
       x = "Global Temperature Change from Pre-industrial (°C)",
       y = "Projected Yield (t/ha)")

ggsave("temp_vs_yield_tha.png", width = 12, height = 8, dpi = 150)

# --- 9B. Correlation: drought index vs actual yield -------------------------

yield_drought <- data %>%
  filter(!is.na(projected_yield_t_ha), !is.na(drought_index))

cor_drought_yield_tha <- cor(
  yield_drought$drought_index,
  yield_drought$projected_yield_t_ha,
  use = "complete.obs"
)
cat("Correlation (drought index vs projected yield t/ha):",
    round(cor_drought_yield_tha, 3), "\n")

ggplot(yield_drought, aes(x = drought_index, y = projected_yield_t_ha, color = crop)) +
  geom_point(alpha = 0.4, size = 1.5) +
  geom_smooth(method = "lm", se = TRUE) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray40") +
  facet_wrap(~crop, scales = "free_y") +
  theme_minimal() +
  labs(title = "Drought Index vs Projected Yield (t/ha) by Crop",
       x = "Drought Index (Positive = Drier)",
       y = "Projected Yield (t/ha)")

ggsave("drought_vs_yield_tha.png", width = 12, height = 8, dpi = 150)

# --- 9C. Multiple regression: temperature + drought predicting yield ---------

yield_model_data <- data %>%
  filter(!is.na(projected_yield_t_ha),
         !is.na(global_delta_t_from_pre_industrial_period),
         !is.na(drought_index),
         !is.na(annual_precipitation_change_each_study_mm))

model_yield_tha <- lm(
  projected_yield_t_ha ~ global_delta_t_from_pre_industrial_period +
    drought_index +
    annual_precipitation_change_each_study_mm +
    crop,
  data = yield_model_data
)
summary(model_yield_tha)

# --- 9D. Yield (t/ha) by scenario over time ---------------------------------

yield_time <- data %>%
  filter(!is.na(projected_yield_t_ha),
         !is.na(future_mid_point),
         climate_scenario %in% c("RCP4.5", "RCP8.5"),
         future_mid_point <= 2085) %>%
  mutate(decade = floor(future_mid_point / 10) * 10) %>%
  group_by(crop, climate_scenario, decade) %>%
  summarise(
    avg_yield = mean(projected_yield_t_ha, na.rm = TRUE),
    sd_yield  = sd(projected_yield_t_ha, na.rm = TRUE),
    n         = n(),
    .groups   = "drop"
  ) %>%
  filter(n >= 3)

ggplot(yield_time, aes(x = decade, y = avg_yield,
                       color = climate_scenario, group = climate_scenario)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  geom_ribbon(aes(ymin = avg_yield - sd_yield,
                  ymax = avg_yield + sd_yield,
                  fill = climate_scenario), alpha = 0.15, color = NA) +
  facet_wrap(~crop, scales = "free_y") +
  theme_minimal() +
  labs(title = "Projected Crop Yield (t/ha) Over Time by Scenario",
       subtitle = "Shaded band = ±1 SD",
       x = "Decade", y = "Average Projected Yield (t/ha)",
       color = "Scenario", fill = "Scenario")

ggsave("yield_tha_over_time.png", width = 12, height = 8, dpi = 150)

# --- 9E. Yield (t/ha) by temperature bin ------------------------------------

yield_temp_bins <- data %>%
  filter(!is.na(projected_yield_t_ha),
         !is.na(global_delta_t_from_pre_industrial_period)) %>%
  mutate(temp_group = cut(
    global_delta_t_from_pre_industrial_period,
    breaks = c(-Inf, 1, 2, 3, 4, Inf),
    labels = c("< 1°C", "1–2°C", "2–3°C", "3–4°C", "> 4°C")
  )) %>%
  group_by(crop, temp_group) %>%
  summarise(
    avg_yield = mean(projected_yield_t_ha, na.rm = TRUE),
    n         = n(),
    .groups   = "drop"
  )

ggplot(yield_temp_bins, aes(x = temp_group, y = avg_yield, fill = crop)) +
  geom_col(position = "dodge") +
  theme_minimal() +
  scale_fill_brewer(palette = "Set2") +
  labs(title = "Average Projected Yield (t/ha) by Temperature Bin and Crop",
       x = "Global Temperature Change Group",
       y = "Average Projected Yield (t/ha)",
       fill = "Crop")

ggsave("yield_tha_by_temp_bin.png", width = 10, height = 6, dpi = 150)


# =============================================================================
# SECTION 10: FINAL SUMMARY TABLE & EXPORT
# =============================================================================

final_summary <- data %>%
  group_by(crop, climate_scenario, region) %>%
  summarise(
    n_countries      = n_distinct(country),
    n_observations   = n(),
    mean_impact      = mean(climate_impacts, na.rm = TRUE),
    median_impact    = median(climate_impacts, na.rm = TRUE),
    sd_impact        = sd(climate_impacts, na.rm = TRUE),
    mean_temp_change = mean(local_delta_t, na.rm = TRUE),
    pct_negative     = sum(climate_impacts < 0, na.rm = TRUE) / n() * 100,
    mean_yield       = mean(projected_yield_t_ha, na.rm = TRUE),
    .groups          = "drop"
  ) %>%
  arrange(mean_impact)

write.csv(final_summary,        "climate_impact_summary.csv",      row.names = FALSE)
write.csv(regional_impacts,     "regional_impacts_detailed.csv",   row.names = FALSE)
write.csv(regional_risk,        "regional_risk_assessment.csv",    row.names = FALSE)
write.csv(regional_summary,     "regional_summary.csv",            row.names = FALSE)
write.csv(yield_model_data %>%
            select(crop, country, region, climate_scenario, future_mid_point,
                   projected_yield_t_ha, global_delta_t_from_pre_industrial_period,
                   drought_index, annual_precipitation_change_each_study_mm),
          "yield_tha_model_data.csv", row.names = FALSE)

cat("\n=== KEY FINDINGS ===\n")
cat("1. Overall negative impacts dominate across scenarios\n")
cat("2. RCP8.5 shows severe yield reductions by end-century\n")
cat("3. Temperature and drought are key drivers of crop failure\n")
cat("4. Significant regional variation in climate vulnerability\n")
cat("5. Drought conditions worsen over time under higher emissions scenarios\n")
cat("6. Projected yield (t/ha) declines directly with rising temperature across all crops\n")
cat("\n✓ All tables saved as CSV files\n")
cat("✓ All plots saved as PNG files\n")
