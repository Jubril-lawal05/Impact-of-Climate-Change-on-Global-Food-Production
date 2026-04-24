# --------------------------------------------------
# Analysis 2: Precipitation Change vs Yield Decline
# Author: RC
# Dataset: clean_data_v2.csv
# Purpose: Examine relationship between precipitation change and crop yield impact
# --------------------------------------------------

library(dplyr)
library(ggplot2)

# 1. Load data
clean_data_v2 <- read.csv("data/clean_data_v2.csv")

# 2. Inspect columns (run once if unsure)
names(clean_data_v2)

# 3. Identify precipitation column
# Try these common names from your dataset:
# - annual_precipitation_change_each_study_mm
# - annual_precipitation_change_from_2005_mm

# 👉 Replace with the correct one if needed
precip_col <- "annual_precipitation_change_each_study_mm"

# 4. Create analysis dataset
analysis2 <- clean_data_v2 %>%
  filter(!is.na(.data[[precip_col]]),
         !is.na(climate_impacts))

# 5. Basic checks
summary(analysis2[[precip_col]])
summary(analysis2$climate_impacts)
nrow(analysis2)

# 6. Correlation
cor_precip_yield <- cor(
  analysis2[[precip_col]],
  analysis2$climate_impacts,
  use = "complete.obs"
)

cor_precip_yield
# 7. Linear regression
analysis2$precip_value <- analysis2[[precip_col]]

model_precip_yield <- lm(climate_impacts ~ precip_value, data = analysis2)
# 8. Scatter plot
ggplot(analysis2, aes(x = .data[[precip_col]], y = climate_impacts)) +
  geom_point(alpha = 0.4) +
  geom_smooth(method = "lm", se = TRUE) +
  labs(
    title = "Precipitation Change vs Crop Yield Impact",
    subtitle = "Relationship between precipitation change and yield decline",
    x = "Precipitation Change (mm)",
    y = "Climate Impact on Yield (%)"
  ) +
  theme_minimal()
# 9. Group precipitation into bins
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
    number_of_records = n()
  )

analysis2_bins
# 10. Bar chart
ggplot(analysis2_bins, aes(x = precip_group, y = average_yield_impact)) +
  geom_col() +
  labs(
    title = "Average Yield Impact by Precipitation Change Group",
    x = "Precipitation Change Category",
    y = "Average Climate Impact on Yield (%)"
  ) +
  theme_minimal()
