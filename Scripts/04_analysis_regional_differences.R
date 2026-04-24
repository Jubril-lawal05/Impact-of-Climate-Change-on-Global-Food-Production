# --------------------------------------------------
# Analysis 4: Regional Differences
# Author: RC
# Dataset: clean_data_v2.csv
# Purpose: Compare climate impact on crop yields across regions
# --------------------------------------------------

library(dplyr)
library(ggplot2)

# 1. Load data
clean_data_v2 <- read.csv("data/clean_data_v2.csv")

# 2. Check region values
unique(clean_data_v2$region)

# 3. Filter valid data
analysis4 <- clean_data_v2 %>%
  filter(!is.na(region),
         !is.na(climate_impacts))

# 4. Summary by region
region_summary <- analysis4 %>%
  group_by(region) %>%
  summarise(
    avg_impact = mean(climate_impacts, na.rm = TRUE),
    median_impact = median(climate_impacts, na.rm = TRUE),
    min_impact = min(climate_impacts, na.rm = TRUE),
    max_impact = max(climate_impacts, na.rm = TRUE),
    n = n()
  ) %>%
  arrange(avg_impact)

region_summary
# 5. Bar chart (average impact by region)
ggplot(region_summary, aes(x = reorder(region, avg_impact), y = avg_impact)) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Average Yield Impact by Region",
    subtitle = "Regions most affected by climate change",
    x = "Region",
    y = "Average Climate Impact on Yield (%)"
  ) +
  theme_minimal()
# 6. Boxplot (distribution by region)
ggplot(analysis4, aes(x = region, y = climate_impacts)) +
  geom_boxplot() +
  coord_flip() +
  labs(
    title = "Distribution of Yield Impacts by Region",
    x = "Region",
    y = "Climate Impact on Yield (%)"
  ) +
  theme_minimal()
# 7. Optional: highlight top 5 worst regions
top_regions <- region_summary %>%
  slice_min(avg_impact, n = 5)

top_regions

