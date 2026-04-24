# --------------------------------------------------
# Analysis 5: Drought Impact on Crop Yield
# Author: RC
# Dataset: clean_data_v2.csv
# Purpose: Examine relationship between drought conditions and crop yield impact
# --------------------------------------------------

library(dplyr)
library(ggplot2)

# 1. Load data
clean_data_v2 <- read.csv("data/clean_data_v2.csv")

# 2. Create analysis dataset
analysis5 <- clean_data_v2 %>%
  filter(!is.na(drought_index),
         !is.na(climate_impacts))

# 3. Check drought values
unique(analysis5$drought_index)

# 4. Summary by drought index
drought_summary <- analysis5 %>%
  group_by(drought_index) %>%
  summarise(
    avg_impact = mean(climate_impacts, na.rm = TRUE),
    median_impact = median(climate_impacts, na.rm = TRUE),
    n = n()
  )

drought_summary
#5 Create drought categories
analysis5_bins <- analysis5 %>%
  mutate(drought_group = cut(
    drought_index,
    breaks = c(-Inf, -4, -3, -2, -1, 0, Inf),
    labels = c("Extreme Drought", "Severe Drought", "Moderate Drought",
               "Mild Drought", "Near Normal", "Wet Conditions")
  )) %>%
  group_by(drought_group) %>%
  summarise(
    avg_impact = mean(climate_impacts, na.rm = TRUE),
    median_impact = median(climate_impacts, na.rm = TRUE),
    n = n()
  )

analysis5_bins
ggplot(analysis5_bins, aes(x = drought_group, y = avg_impact)) +
  geom_col() +
  labs(
    title = "Average Yield Impact by Drought Category",
    x = "Drought Category",
    y = "Average Climate Impact on Yield (%)"
  ) +
  theme_minimal()
#6 Scatterplot
ggplot(analysis5, aes(x = drought_index, y = climate_impacts)) +
  geom_point(alpha = 0.4) +
  geom_smooth(method = "lm", se = TRUE) +
  labs(
    title = "Drought Index vs Crop Yield Impact",
    x = "Drought Index",
    y = "Climate Impact on Yield (%)"
  ) +
  theme_minimal()
#7 Box Plot
ggplot(analysis5, aes(x = drought_index, y = climate_impacts)) +
  geom_boxplot() +
  labs(
    title = "Distribution of Yield Impacts by Drought Index",
    x = "Drought Index",
    y = "Climate Impact on Yield (%)"
  ) +
  theme_minimal()
