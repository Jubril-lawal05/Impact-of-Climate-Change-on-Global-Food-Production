# Analysis 1: Temperature Increase vs Yield Decline
# Author: Ruda
# Date: 2026-04-24
# Dataset: clean_data_v2.csv
# Description: Examines the relationship between temperature increase and crop yield impact

# Analysis 1: Temperature Increase vs Yield Decline

library(dplyr)
library(ggplot2)

# 1. Load cleaned dataset
clean_data_v2 <- read.csv("data/clean_data_v2.csv")

# 2. Check column names
names(clean_data_v2)

# 3. Create Analysis 1 dataset
analysis1 <- clean_data_v2 %>%
  filter(!is.na(local_delta_t),
         !is.na(climate_impacts))

# 4. Check the data
summary(analysis1$local_delta_t)
summary(analysis1$climate_impacts)
nrow(analysis1)

# 5. Correlation: temperature increase vs yield impact
cor_temp_yield <- cor(
  analysis1$local_delta_t,
  analysis1$climate_impacts,
  use = "complete.obs"
)

cor_temp_yield

# 6. Linear regression model
model_temp_yield <- lm(climate_impacts ~ local_delta_t, data = analysis1)

summary(model_temp_yield)

# 7. Scatter plot with trendline
ggplot(analysis1, aes(x = local_delta_t, y = climate_impacts)) +
  geom_point(alpha = 0.4) +
  geom_smooth(method = "lm", se = TRUE) +
  labs(
    title = "Temperature Increase vs Crop Yield Change",
    subtitle = "Relationship between local temperature increase and projected yield impact",
    x = "Local Temperature Increase (°C)",
    y = "Climate Impact on Yield (%)"
  ) +
  theme_minimal()

# 8. Scatter plot by crop
ggplot(analysis1, aes(x = local_delta_t, y = climate_impacts, color = crop)) +
  geom_point(alpha = 0.5) +
  geom_smooth(method = "lm", se = FALSE) +
  labs(
    title = "Temperature Increase vs Yield Change by Crop",
    subtitle = "Comparing crop sensitivity to local temperature increases",
    x = "Local Temperature Increase (°C)",
    y = "Climate Impact on Yield (%)",
    color = "Crop"
  ) +
  theme_minimal()

# 9. Average yield impact by temperature group
analysis1_bins <- analysis1 %>%
  mutate(temp_group = cut(
    local_delta_t,
    breaks = c(-Inf, 1, 2, 3, 4, Inf),
    labels = c("Less than 1°C", "1–2°C", "2–3°C", "3–4°C", "More than 4°C")
  )) %>%
  group_by(temp_group) %>%
  summarise(
    average_yield_impact = mean(climate_impacts, na.rm = TRUE),
    number_of_records = n()
  )

analysis1_bins

# 10. Bar chart of average yield impact by temperature group
ggplot(analysis1_bins, aes(x = temp_group, y = average_yield_impact)) +
  geom_col() +
  labs(
    title = "Average Yield Impact by Temperature Increase Group",
    x = "Temperature Increase Group",
    y = "Average Climate Impact on Yield (%)"
  ) +
  theme_minimal()