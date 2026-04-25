# Ruda's Climate Change × Food Production Analysis
**Dataset:** clean_data.csv | 4,364 simulations | 83 countries | 6 regions | 4 crops  
**Variables:** crop, country, region, local_delta_t, global_delta_t_from_pre_industrial_period, projected_yield_t_ha, climate_impacts (%)

---

## Introduction — Why Climate Change Matters for Food Production

Climate change is the defining food security challenge of the 21st century. Rising temperatures, shifting precipitation patterns, and more frequent extreme weather events are disrupting agricultural systems worldwide. The crops that feed the vast majority of humanity — maize, wheat, rice, and soybean — are all temperature-sensitive at critical growth stages, yet the magnitude of risk varies enormously across regions and warming scenarios. This analysis quantifies those risks using 4,364 climate-crop simulation runs spanning 83 countries, providing actionable insight into which crops and regions face the greatest danger, and what difference early adaptation could make.

---

## Data Overview

| Field | Detail |
|---|---|
| Simulations | 4,364 (after cleaning) |
| Countries | 83 |
| Regions | Asia, Africa, Europe, North America, Central & South America, Australasia |
| Crops | Maize, Rice, Wheat, Soybean |
| Local ΔT range | 0.18 — 6.60 °C |
| Global ΔT range | 0.59 — 5.55 °C above pre-industrial |
| Yield impact range | −100% to +114% |
| Missing yield values | 1,502 (projected_yield_t_ha); climate_impacts column is complete |

---

## Analysis 1: Temperature Increase vs Yield Decline
**Script:** ruda_analysis1.py | **Visual:** ruda_viz1_temperature_vs_yield.png

### Key Findings
- The linear relationship between local warming and yield impact is statistically significant (r = 0.054, p < 0.001) but explains very little variance alone (R² = 0.003), indicating that temperature is one of several drivers.
- Across all temperature brackets, the majority of simulations show negative yield impact. Even in the coolest bracket (0–1°C local warming), **72.7%** of simulations produce yield declines, with a mean impact of **−19.2%**.
- The yield impact curve is non-linear: moderate warming (2–4°C) appears slightly less damaging on average than either very low or very high warming, likely because the dataset captures a mix of crop types, some of which benefit from modest warming.
- At 5°C+ local warming, the mean impact rebounds to **−15.3%** and 72.7% of simulations are negative.

### Summary
Temperature increase alone is a poor single predictor of yield loss (high variance, low R²). The risk is already widespread at low warming levels, confirming that even the 1.5°C Paris target does not eliminate food security risks — it merely reduces their severity.

---

## Analysis 2: Global Warming Level vs Yield Impact
**Script:** ruda_analysis2.py | **Visual:** ruda_viz2_globalwarming_vs_yield.png

### Key Findings
- Using the IPCC-standard global warming metric, the pattern is stark: at ≤1.5°C global warming, mean yield impact is **+3.6%** and only 44% of simulations are negative. At 1.5–2°C, mean impact plunges to **−14.6%** with 72% of outcomes negative.
- Beyond 2°C, impacts remain persistently negative. At >4°C global warming, mean impact reaches **−29.9%** with 80% of simulations negative.
- **Per-crop global warming sensitivity:** Maize is the most sensitive (−8.0%/°C), followed by Soybean (−6.9%/°C) and Rice (−4.3%/°C). Wheat is least sensitive (−1.6%/°C) at the global scale.
- The 1.5°C threshold is a genuine inflection point in this dataset: below it, crops can thrive; above it, the system shifts to predominantly negative outcomes.

### Summary
The 1.5°C Paris target is not just symbolically important — the data shows it is the boundary between a world where food production can adapt and one where systemic decline becomes the norm.

---

## Analysis 3: Crop Comparison — Maize, Wheat, Rice, Soybean
**Script:** ruda_analysis3.py | **Visual:** ruda_viz3_crop_comparison.png

### Key Findings
| Crop | Mean Impact | % Negative | % Severe (<−25%) |
|---|---|---|---|
| Soybean | −22.2% | 75.5% | 42.6% |
| Maize | −21.8% | 78.1% | 38.2% |
| Wheat | −9.6% | 67.2% | 20.8% |
| Rice | −2.9% | 54.0% | 10.3% |

- **Maize and Soybean** are the most vulnerable crops. Maize has the highest probability of any yield decline (78%); Soybean has the most severe mean losses.
- **Rice** is the most climate-resilient crop in this dataset: mean impact just −2.9%, and only 10% of simulations show severe declines.
- **Wheat** sits in the middle: meaningfully negative on average, but with less extreme tail risk than maize or soybean.
- Pairwise statistical tests confirm that all crop pairs are significantly different (p < 0.001), except Maize vs Soybean (p = 0.277) — they share a similar vulnerability profile.
- At ≤1.5°C global warming, all crops show slight positive mean impacts, reinforcing Analysis 2's findings.

### Summary
Maize and Soybean are the highest-risk staples. Diversifying toward more rice cultivation in vulnerable regions could buffer against the worst climate impacts, though rice is also more water-intensive.

---

## Analysis 4: Regional Differences
**Script:** ruda_analysis4.py | **Visual:** ruda_viz4_regional_differences.png

### Key Findings
| Region | Mean Impact | % Negative |
|---|---|---|
| Central & South America | −32.7% | 87.5% |
| Africa | −22.4% | 76.0% |
| Europe | −9.8% | 71.9% |
| Asia | −9.7% | 62.4% |
| Australasia | −8.4% | 69.9% |
| North America | −2.0% | 57.0% |

- **Central & South America** faces the most severe climate impacts — 87% of simulations show decline, with a mean loss of −32.7%. The hardest-hit individual countries include Venezuela (−74.9%), Paraguay (−57.1%), and Uganda (−58.3%).
- **Africa** is the second most vulnerable region, with countries like Uganda, Malawi, Egypt, Algeria, and Ethiopia in the global top 10 for yield losses.
- **North America** is the most resilient region (mean −2.0%), but 57% of simulations still show some yield decline.
- The Crop × Region heatmap reveals that **Maize in Central & South America** suffers the worst combined impact (−43.4%), while **Rice in Europe** and **Rice in Central & South America** actually show slight positive mean impacts.
- North America's apparent resilience is partly due to its higher mean local warming exposure (2.65°C) — suggesting it is modelling high-latitude warming gains for wheat in particular.

### Summary
The global south — and particularly tropical/sub-tropical regions in Latin America and Africa — will bear a disproportionate burden of climate-driven food losses, despite contributing least to historical emissions.

---

## Analysis 5: Adaptation Strategies
**Script:** ruda_analysis5.py | **Visual:** ruda_viz5_adaptation.png

### Key Findings
- **Adaptation gap analysis** (comparing Q75 vs Q25 outcomes within identical warming/crop strata) shows that the range between the best and worst managed systems is enormous — often 30–45 percentage points at moderate warming levels. This gap represents the maximum benefit achievable through better crop varieties, irrigation, timing, and agronomic practices.
- **Maize tipping point: ~1.8°C global warming** — beyond which mean impacts consistently exceed −20%. Soybean shares this threshold. Wheat and Rice do not cross the −20% threshold in this dataset.
- **Regional resilience proxy:** North America (+10.8%) and Australasia (+5.0%) consistently outperform what their warming exposure would predict, suggesting advanced agronomic adaptation. Central & South America (−20.6%) and Africa (−9.6%) underperform — indicating an adaptation deficit.
- **Resilient countries at ≥3°C warming:** Temperate and high-latitude countries (UK, Germany, Finland, Austria, Romania, Japan, Korea) maintain positive or near-zero yield impacts even at high warming, benefiting from longer growing seasons. Some lower-income countries (Syria, Afghanistan under specific scenarios) also appear resilient due to model-specific conditions.
- The 95% CI crop response curves confirm that **Rice has the flattest (most stable) response** across all warming levels, while Maize shows the steepest decline slope.

### Summary
Adaptation is not optional — it is already the difference between agricultural viability and collapse in many scenarios. The data implies a 30–45% yield gap between adapted and unadapted farming under the same climate, making investment in heat-tolerant varieties, irrigation, and precision agriculture among the most cost-effective climate interventions available.

---

## Conclusion — Which Crops/Regions Are Most at Risk, and What Reduces the Damage?

### Most at Risk

**Crops:**
1. **Maize** — highest probability of yield decline (78%), tipping point already reached at 1.8°C global warming
2. **Soybean** — highest severity of losses (mean −22%), similar vulnerability profile to Maize
3. **Wheat** — moderately at risk (mean −9.6%), with significant regional variation
4. **Rice** — most resilient (mean −2.9%), lowest rate of severe losses

**Regions:**
1. **Central & South America** — most vulnerable globally (mean −32.7%, 87% negative)
2. **Africa** — second most exposed (mean −22.4%), with severe country-level hotspots
3. **Europe and Asia** — moderate but widespread impacts
4. **North America and Australasia** — most resilient, but still majority-negative outcomes

**Countries with highest risk:** Venezuela, Uganda, Paraguay, Pakistan, Turkey, Malawi, Egypt, Algeria, Ethiopia

### What Reduces the Damage?

1. **Stay below 1.5°C global warming** — the dataset shows this is the critical threshold before systemic yield losses become the norm across all crops
2. **Invest in adaptation** — the Q75–Q25 adaptation gap (30–45%) shows that better-adapted farming systems can dramatically outperform poorly adapted ones under identical climate conditions
3. **Shift crop mix toward rice** where water resources allow — rice is markedly more climate-resilient
4. **Prioritise tropical and sub-tropical regions** for adaptation support — North America and Europe show natural resilience buffers that Africa and Latin America lack
5. **Focus maize and soybean adaptation urgently** — they are already past their mean-impact tipping points at current global warming trajectories

---

*Analysis by Ruda | Data cleaned by Ayomide*
