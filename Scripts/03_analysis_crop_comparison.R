# --------------------------------------------------
# Analysis 3: Crop Comparison
# Author: RC
# Dataset: clean_data_v2.csv
# Purpose: Compare climate impact on different crops
# --------------------------------------------------

library(dplyr)
library(ggplot2)

# 1. Load data
clean_data_v2 <- read.csv("data/clean_data_v2.csv")

# 2. Check crop names
unique(clean_data_v2$crop)

# 3. Keep key crops only
analysis3 <- clean_data_v2 %>%
  filter(crop %in% c("maize", "wheat", "rice", "soybean"),
         !is.na(climate_impacts))

# 4. Summary by crop
crop_summary <- analysis3 %>%
  group_by(crop) %>%
  summarise(
    avg_impact = mean(climate_impacts, na.rm = TRUE),
    median_impact = median(climate_impacts, na.rm = TRUE),
    min_impact = min(climate_impacts, na.rm = TRUE),
    max_impact = max(climate_impacts, na.rm = TRUE),
    n = n()
  )

crop_summary
#Bar Chart was empty so check actual crop values
unique(clean_data_v2$crop)
# they are all capitalized names so updating the filter
analysis3 <- clean_data_v2 %>%
  filter(crop %in% c("Maize", "Wheat", "Rice", "Soybean"),
         !is.na(climate_impacts)) 
#re run everything
crop_summary
analysis3
crop_summary <- analysis3 %>%
  group_by(crop) %>%
  summarise(
    avg_impact = mean(climate_impacts, na.rm = TRUE),
    median_impact = median(climate_impacts, na.rm = TRUE),
    min_impact = min(climate_impacts, na.rm = TRUE),
    max_impact = max(climate_impacts, na.rm = TRUE),
    n = n()
  )
crop_summary
ggplot(crop_summary, aes(x = crop, y = avg_impact)) +
  geom_col() +
  labs(
    title = "Average Yield Impact by Crop",
    x = "Crop Type",
    y = "Average Climate Impact on Yield (%)"
  ) +
  theme_minimal()


