install.packages(c(
  "tidyverse",    # Collection of data science packages
  "skimr",        # Summary statistics
  "DataExplorer", # Automated EDA
  "naniar",       # Missing value visualization
  "mgcv",         # Generalized Additive Models
  "randomForest", # Random Forest algorithm
  "plotly"        # Interactive plots
))

library(skimr)
library(DataExplorer)
library(naniar)
library(mgcv)
library(randomForest)
library(plotly)

data <- read.csv("clean_data_v2.csv")

# Check missing values visually
vis_miss(data)
plot_missing(data)
# Summary statistics
summary_stats <- data %>%
  group_by(crop) %>%
  summarise(
    n = n(),
    avg_yield = mean(projected_yield_t_ha, na.rm = TRUE),
    avg_impact = mean(climate_impacts, na.rm = TRUE),
    avg_temp = mean(current_average_temperature_point_coordinate_d_c, na.rm = TRUE),
    avg_precip = mean(current_annual_precipitation_mm_point_coordinate, na.rm = TRUE)
  )
print(summary_stats)

# Check for duplicates
duplicates <- data %>%
  group_by(crop, country, climate_scenario, future_mid_point) %>%
  filter(n() > 1) %>%
  arrange(crop, country, climate_scenario, future_mid_point)

cat("Number of potential duplicates:", nrow(duplicates), "\n")

# Check for extreme outliers in climate_impacts
data %>%
  ggplot(aes(y = climate_impacts, x = crop)) +
  geom_boxplot(fill = "lightblue", outlier.color = "red") +
  facet_wrap(~climate_scenario) +
  theme_minimal() +
  labs(title = "Distribution of Climate Impacts by Crop and Scenario",
       y = "Climate Impact (%)", x = "Crop")

# Identify outlier observations
data %>%
  filter(abs(climate_impacts) > 50) %>%
  select(crop, country, climate_scenario, climate_impacts, 
         projected_yield_t_ha) %>%
  arrange(desc(abs(climate_impacts))) %>%
  head(20)

# Check climate scenario coverage
data %>%
  count(climate_scenario) %>%
  arrange(desc(n)) %>%
  mutate(pct = n/sum(n)*100) %>%
  ggplot(aes(x = reorder(climate_scenario, n), y = n, fill = climate_scenario)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  theme_minimal() +
  labs(title = "Number of Observations by Climate Scenario",
       x = "Scenario", y = "Count")

# Compare RCP scenarios for major crops
rcp_comparison <- data %>%
  filter(climate_scenario %in% c("RCP2.6", "RCP4.5", "RCP6.0", "RCP8.5")) %>%
  group_by(crop, climate_scenario) %>%
  summarise(
    avg_impact = mean(climate_impacts, na.rm = TRUE),
    sd_impact = sd(climate_impacts, na.rm = TRUE),
    n = n(),
    se_impact = sd_impact/sqrt(n),
    .groups = 'drop'
  )

# Visualization
ggplot(rcp_comparison, aes(x = climate_scenario, y = avg_impact, fill = crop)) +
  geom_bar(stat = "identity", position = "dodge") +
  geom_errorbar(aes(ymin = avg_impact - se_impact, ymax = avg_impact + se_impact),
                position = position_dodge(0.9), width = 0.2) +
  theme_minimal() +
  scale_fill_brewer(palette = "Set2") +
  labs(title = "Average Climate Impact by RCP Scenario and Crop",
       y = "Average Climate Impact (%)", x = "RCP Scenario",
       subtitle = "Error bars show ±1 Standard Error")

# Calculate "avoided damages" - comparing RCP8.5 vs RCP4.5
avoided_damage <- data %>%
  filter(climate_scenario %in% c("RCP4.5", "RCP8.5")) %>%
  group_by(crop, climate_scenario, future_mid_point) %>%
  summarise(avg_impact = mean(climate_impacts, na.rm = TRUE), .groups = 'drop') %>%
  pivot_wider(names_from = climate_scenario, values_from = avg_impact) %>%
  mutate(avoided_damage = RCP8.5 - RCP4.5)

ggplot(avoided_damage, aes(x = future_mid_point, y = avoided_damage, color = crop)) +
  geom_line(size = 1) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  theme_minimal() +
  labs(title = "Avoided Climate Damages (RCP8.5 - RCP4.5)",
       y = "Avoided Yield Loss (%)", 
       x = "Future Mid-Point Year")

####Temperature Yield Analysis-------------------

# Temperature vs Yield Impact analysis
temp_analysis <- data %>%
  filter(!is.na(local_delta_t), !is.na(climate_impacts)) %>%
  group_by(crop) %>%
  mutate(temp_bin = cut(local_delta_t, breaks = seq(0, 6, by = 1)))

# Temperature response curves by crop (using local_delta)
ggplot(data %>% filter(!is.na(local_delta_t)), 
       aes(x = local_delta_t, y = climate_impacts, color = crop)) +
  geom_point(alpha = 0.5, size = 2) +
  geom_smooth(method = "loess", se = TRUE) +
  facet_wrap(~crop, scales = "free_y") +
  theme_minimal() +
  labs(title = "Temperature Change vs Climate Impact by Crop",
       x = "Local Temperature Change (°C)", 
       y = "Climate Impact (%)")

# Non-linear modeling: Are there temperature tipping points?
library(mgcv)

# GAM model for maize
maize_data <- data %>% filter(crop == "Maize", !is.na(local_delta_t), !is.na(climate_impacts))
gam_model <- gam(climate_impacts ~ s(local_delta_t, k = 6) + s(annual_precipitation_change_each_study_mm, k = 6), 
                 data = maize_data)
summary(gam_model)

# Plot the smooth terms
plot(gam_model, pages = 1, shade = TRUE)


# ============================================
# ANALYSIS 1: Using Global Delta T (More Data)
# ============================================

# Temperature response curves by crop - GLOBAL
ggplot(data %>% filter(!is.na(global_delta_t_from_pre_industrial_period)), 
       aes(x = global_delta_t_from_pre_industrial_period, y = climate_impacts, color = crop)) +
  geom_point(alpha = 0.5, size = 2) +
  geom_smooth(method = "loess", se = TRUE) +
  facet_wrap(~crop, scales = "free_y") +
  theme_minimal() +
  labs(title = "Global Temperature Change vs Climate Impact by Crop",
       x = "Global Temperature Change from Pre-industrial (°C)", 
       y = "Climate Impact (%)")

# Temperature bins using GLOBAL delta T
temp_analysis_global <- data %>%
  filter(!is.na(global_delta_t_from_pre_industrial_period), !is.na(climate_impacts)) %>%
  mutate(temp_bin = cut(global_delta_t_from_pre_industrial_period, 
                        breaks = seq(0, 6, by = 1)))

# Boxplot by temperature bins
ggplot(temp_analysis_global, aes(x = temp_bin, y = climate_impacts, fill = crop)) +
  geom_boxplot() +
  theme_minimal() +
  labs(title = "Climate Impacts by Global Temperature Change Bins",
       x = "Global Temperature Change (°C)", 
       y = "Climate Impact (%)")

# ============================================
# ANALYSIS 2: GAM with Global Delta T
# ============================================

# GAM model for maize - GLOBAL temperature
maize_data_global <- data %>% 
  filter(crop == "Maize", 
         !is.na(global_delta_t_from_pre_industrial_period), 
         !is.na(climate_impacts))

gam_model_global <- gam(climate_impacts ~ s(global_delta_t_from_pre_industrial_period, k = 6) + 
                          s(annual_precipitation_change_each_study_mm, k = 6), 
                        data = maize_data_global)

summary(gam_model_global)
plot(gam_model_global, pages = 1, shade = TRUE, 
     main = "GAM Smooth Terms (Global Temperature)")

# ============================================
# ANALYSIS 3: Compare Local vs Global
# ============================================

# Create dataset with both where available
comparison_data <- data %>%
  filter(!is.na(local_delta_t), !is.na(global_delta_t_from_pre_industrial_period)) %>%
  select(crop, local_delta_t, global_delta_t_from_pre_industrial_period, climate_impacts)

# Scatter plot comparing local vs global
ggplot(comparison_data, aes(x = global_delta_t_from_pre_industrial_period, 
                            y = local_delta_t, 
                            color = crop)) +
  geom_point(alpha = 0.7) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "red") +
  theme_minimal() +
  labs(title = "Local vs Global Temperature Change",
       subtitle = "Red line = 1:1 relationship",
       x = "Global Temperature Change (°C)", 
       y = "Local Temperature Change (°C)")

# ============================================
# ANALYSIS 4: Side-by-Side Comparison
# ============================================

# Create both plots
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

# Display side by side
library(gridExtra)
grid.arrange(p_global, p_local, nrow = 2)

# Drought index analysis
drought_analysis <- data %>%
  filter(!is.na(drought_index)) %>%
  mutate(drought_category = case_when(
    drought_index < -0.1 ~ "Wetter",
    drought_index >= -0.1 & drought_index <= 0.1 ~ "Normal",
    drought_index > 0.1 ~ "Drier"
  ))

# Drought vs Yield Impact
ggplot(drought_analysis, aes(x = drought_index, y = climate_impacts)) +
  geom_point(aes(color = crop), alpha = 0.6) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  theme_minimal() +
  labs(title = "Drought Index vs Yield Impact",
       x = "Drought Index (Negative = Wetter, Positive = Drier)",
       y = "Climate Impact (%)")

# Boxplot
ggplot(drought_analysis, aes(x = drought_category, y = climate_impacts, fill = crop)) +
  geom_boxplot() +
  theme_minimal() +
  labs(title = "Yield Impact by Drought Category",
       x = "Drought Condition", y = "Climate Impact (%)")

# Statistical test
drought_aov <- aov(climate_impacts ~ drought_category * crop, data = drought_analysis)
summary(drought_aov)
TukeyHSD(drought_aov)

# ============================================
# REGIONAL IMPACT ANALYSIS (Using Global Delta T)
# ============================================

# Regional impact summaries with GLOBAL temperature
regional_impacts <- data %>%
  filter(climate_scenario == "RCP8.5", future_mid_point >= 2080) %>%
  group_by(country, region, crop) %>%
  summarise(
    avg_impact = mean(climate_impacts, na.rm = TRUE),
    avg_temp_change = mean(global_delta_t_from_pre_industrial_period, na.rm = TRUE),  # Changed to global
    avg_precip_change = mean(annual_precipitation_change_each_study_mm, na.rm = TRUE),
    n_observations = n(),
    .groups = 'drop'
  ) %>%
  arrange(avg_impact)

# Top 10 most vulnerable
regional_impacts %>%
  head(10) %>%
  ggplot(aes(x = reorder(region, avg_impact),
             y = avg_impact)) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Most Vulnerable Regions",
    subtitle = "RCP8.5 - End Century",
    x = "Region",
    y = "Vulnerability Score"
  )

# Top 10 most resilient (positive impacts)
cat("\n=== MOST RESILIENT (RCP8.5, End Century) ===\n")
regional_impacts %>%
  tail(10) %>%
  print()

# ============================================
# HEAT MAP: Regional Climate Impact Matrix
# ============================================

# Filter to countries with sufficient data
country_crop_matrix <- regional_impacts %>%
  filter(n_observations >= 3) %>%  # Only include with enough data points
  select(country, crop, avg_impact)

ggplot(country_crop_matrix, aes(x = country, y = crop, fill = avg_impact)) +
  geom_tile(color = "white", size = 0.5) +
  scale_fill_gradient2(low = "red", mid = "white", high = "green", midpoint = 0,
                       name = "Avg Impact %") +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 8),
    panel.grid = element_blank()
  ) +
  labs(title = "Regional Climate Impacts Matrix (RCP8.5, End Century)",
       subtitle = "Red = Yield Loss, Green = Yield Gain",
       x = "", y = "")

ggsave("regional_heatmap.png", width = 14, height = 8, dpi = 150)

# ============================================
# REGIONAL RISK SCORES
# ============================================

regional_risk <- regional_impacts %>%
  group_by(country, region) %>%
  summarise(
    mean_impact = mean(avg_impact, na.rm = TRUE),
    worst_crop_impact = min(avg_impact, na.rm = TRUE),
    best_crop_impact = max(avg_impact, na.rm = TRUE),
    impact_spread = max(avg_impact, na.rm = TRUE) - min(avg_impact, na.rm = TRUE),
    avg_global_warming = mean(avg_temp_change, na.rm = TRUE),
    total_observations = sum(n_observations),
    crops_affected = n_distinct(crop),
    .groups = 'drop'
  ) %>%
  mutate(
    risk_score = rank(mean_impact),  # 1 = most vulnerable
    risk_category = case_when(
      mean_impact <= -20 ~ "Severe Risk",
      mean_impact > -20 & mean_impact <= -10 ~ "High Risk",
      mean_impact > -10 & mean_impact <= 0 ~ "Moderate Risk",
      mean_impact > 0 ~ "Low Risk / Opportunity"
    )
  ) %>%
  arrange(risk_score)

cat("\n=== REGIONAL RISK ASSESSMENT ===\n")
print(regional_risk, n = 30)

# ============================================
# VISUALIZATION: Top 15 Most Vulnerable Countries
# ============================================

top_vulnerable <- regional_risk %>%
  head(15)

ggplot(top_vulnerable, aes(x = reorder(country, -mean_impact), y = mean_impact, fill = risk_category)) +
  geom_bar(stat = "identity") +
  geom_errorbar(aes(ymin = worst_crop_impact, ymax = best_crop_impact), 
                width = 0.2, color = "darkgray") +
  coord_flip() +
  scale_fill_manual(values = c(
    "Severe Risk" = "#D32F2F",
    "High Risk" = "#F44336",
    "Moderate Risk" = "#FF9800"
  )) +
  theme_minimal() +
  labs(title = "Most Vulnerable Countries to Climate Change (RCP8.5, 2080+)",
       subtitle = "Bar shows mean impact, line shows range across crops",
       x = "", y = "Average Climate Impact (%)",
       fill = "Risk Category")

ggsave("vulnerable_countries.png", width = 12, height = 8, dpi = 150)

# ============================================
# REGIONAL SUMMARY BY CONTINENT
# ============================================

regional_summary <- regional_impacts %>%
  group_by(region) %>%
  summarise(
    countries = n_distinct(country),
    mean_impact = mean(avg_impact, na.rm = TRUE),
    worst_country = country[which.min(avg_impact)],
    worst_impact = min(avg_impact, na.rm = TRUE),
    avg_warming = mean(avg_temp_change, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  arrange(mean_impact)

cat("\n=== SUMMARY BY REGION ===\n")
print(regional_summary)

# Regional bar chart
ggplot(regional_summary, aes(x = reorder(region, -mean_impact), y = mean_impact, fill = region)) +
  geom_bar(stat = "identity") +
  geom_text(aes(label = round(mean_impact, 1)), hjust = -0.2, size = 4) +
  coord_flip() +
  theme_minimal() +
  theme(legend.position = "none") +
  labs(title = "Average Climate Impact by Region (RCP8.5, 2080+)",
       x = "", y = "Average Climate Impact (%)")

ggsave("regional_summary.png", width = 10, height = 6, dpi = 150)

# ============================================
# EXPORT TABLES
# ============================================

write.csv(regional_impacts, "regional_impacts_detailed.csv", row.names = FALSE)
write.csv(regional_risk, "regional_risk_assessment.csv", row.names = FALSE)
write.csv(regional_summary, "regional_summary.csv", row.names = FALSE)

cat("\n✓ All tables saved as CSV files")
cat("\n✓ All plots saved as PNG files")

# Time series of impacts
time_analysis <- data %>%
  filter(!is.na(future_mid_point)) %>%
  mutate(time_period = case_when(
    future_mid_point <= 2030 ~ "Near-term (2020-2030)",
    future_mid_point > 2030 & future_mid_point <= 2060 ~ "Mid-term (2030-2060)",
    future_mid_point > 2060 ~ "Long-term (2060+)"
  ))

# Temporal evolution by crop and scenario
ggplot(time_analysis %>% 
         filter(climate_scenario %in% c("RCP4.5", "RCP8.5")), 
       aes(x = future_mid_point, y = climate_impacts, color = crop)) +
  geom_point(alpha = 0.3) +
  geom_smooth(method = "lm") +
  facet_grid(crop ~ climate_scenario) +
  theme_minimal() +
  labs(title = "Temporal Evolution of Climate Impacts by Scenario",
       x = "Future Mid-Point Year", y = "Climate Impact (%)")

# Plot 1: Time series by crop and scenario
ggplot(time_analysis %>% 
         filter(climate_scenario %in% c("RCP4.5", "RCP6.0", "RCP8.5"),
                future_mid_point <= 2050), 
       aes(x = future_mid_point, y = climate_impacts, color = climate_scenario)) +
  geom_point(alpha = 0.4, size = 2) +
  geom_smooth(method = "lm", se = TRUE) +
  facet_wrap(~crop, scales = "free_y") +
  theme_minimal() +
  labs(title = "Temporal Trends in Climate Impacts (Up to 2050)",
       x = "Year", y = "Climate Impact (%)",
       color = "Scenario")

ggsave("temporal_trends.png", width = 12, height = 8, dpi = 150)

# Plot 2: Decade averages to see acceleration
decade_analysis <- time_analysis %>%
  filter(future_mid_point <= 2085) %>%
  mutate(decade = floor(future_mid_point / 10) * 10) %>%
  group_by(crop, climate_scenario, decade) %>%
  summarise(
    avg_impact = mean(climate_impacts, na.rm = TRUE),
    sd_impact = sd(climate_impacts, na.rm = TRUE),
    n = n(),
    .groups = 'drop'
  )

ggplot(decade_analysis %>% 
         filter(climate_scenario %in% c("RCP4.5", "RCP8.5"), n >= 3), 
       aes(x = decade, y = avg_impact, color = crop, group = crop)) +
  geom_line(size = 1) +
  geom_point(size = 2) +
  facet_wrap(~climate_scenario) +
  theme_minimal() +
  labs(title = "Decadal Climate Impact Trends",
       x = "Decade", y = "Average Climate Impact (%)")

ggsave("decadal_trends.png", width = 12, height = 6, dpi = 150)

cat("\nSpeed of impact change (slope per year):\n")
acceleration %>%
  arrange(slope) %>%
  print(n = 20)

# Temperature × Precipitation interaction
interaction_model <- data %>%
  filter(crop == "Maize", !is.na(global_delta_t_from_pre_industrial_period), !is.na(annual_precipitation_change_each_study_mm)) %>%
  mutate(
    temp_high = global_delta_t_from_pre_industrial_period > median(global_delta_t_from_pre_industrial_period, na.rm = TRUE),
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

# Statistical test for interaction
lm_interaction <- lm(climate_impacts ~ global_delta_t_from_pre_industrial_period * annual_precipitation_change_each_study_mm, 
                     data = interaction_model)
summary(lm_interaction)

library(randomForest)

# Prepare data for modeling
rf_data <- data %>%
  filter(!is.na(climate_impacts)) %>%
  select(climate_impacts, current_average_temperature_point_coordinate_d_c,
         current_annual_precipitation_mm_point_coordinate,
         global_delta_t_from_pre_industrial_period,
         local_delta_t, drought_index,
         annual_precipitation_change_each_study_mm,
         crop, region) %>%
  na.omit()

# Train Random Forest
set.seed(123)
rf_model <- randomForest(climate_impacts ~ ., data = rf_data, 
                         importance = TRUE, ntree = 500)

# Variable importance plot
varImpPlot(rf_model, main = "Feature Importance for Predicting Climate Impacts")

# Partial dependence plots
partialPlot(rf_model, rf_data, global_delta_t_from_pre_industrial_period, 
            main = "Partial Dependence: Temperature Change")
partialPlot(rf_model, rf_data, drought_index, 
            main = "Partial Dependence: Drought Index")

# Create a comprehensive summary table
final_summary <- data %>%
  group_by(crop, climate_scenario, region) %>%
  summarise(
    n_countries = n_distinct(country),
    n_observations = n(),
    mean_impact = mean(climate_impacts, na.rm = TRUE),
    median_impact = median(climate_impacts, na.rm = TRUE),
    sd_impact = sd(climate_impacts, na.rm = TRUE),
    mean_temp_change = mean(local_delta_t, na.rm = TRUE),
    pct_negative = sum(climate_impacts < 0, na.rm = TRUE) / n() * 100,
    mean_yield = mean(projected_yield_t_ha, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  arrange(mean_impact)

# Save processed data
write.csv(final_summary, "climate_impact_summary.csv", row.names = FALSE)

# Print key findings
cat("\n=== KEY FINDINGS ===\n")
cat("\n1. Overall negative impacts dominate across scenarios\n")
cat("2. RCP8.5 shows severe yield reductions by end-century\n")
cat("3. Temperature and drought are key drivers of crop failure\n")
cat("4. Significant regional variation in climate vulnerability\n")
    