"""
Analysis 5: Adaptation Strategies
We infer adaptation benefit by comparing simulated yields with/without
adaptation indicators embedded in the data (e.g. rows with higher
projected_yield_t_ha at equivalent warming levels = better adaptation).
We proxy adaptation by contrasting the upper vs lower yield quartiles
within matched warming/crop strata.
Author: Ruda
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy import stats

df = pd.read_csv('/mnt/user-data/uploads/clean_data.csv')
CROP_COLORS = {'Maize': '#E8A838', 'Rice': '#4CA96B', 'Wheat': '#5B8FD4', 'Soybean': '#D4675B'}

print("=" * 60)
print("ANALYSIS 5: ADAPTATION STRATEGIES")
print("=" * 60)

# ── Strategy 1: Best-performing vs worst-performing quartile ────────────────
# Within each crop × warming bin, compare Q1 (worst) vs Q4 (best) outcomes
df['gwl_bin_fine'] = pd.cut(df['global_delta_t_from_pre_industrial_period'],
                             bins=[0, 1.5, 2.0, 2.5, 3.0, 4.0, 6.0],
                             labels=['<1.5', '1.5-2', '2-2.5', '2.5-3', '3-4', '>4'])

adaptation_gaps = []
for crop in df['crop'].unique():
    for gwl_bin in df['gwl_bin_fine'].cat.categories:
        sub = df[(df['crop'] == crop) & (df['gwl_bin_fine'] == gwl_bin)]['climate_impacts'].dropna()
        if len(sub) < 20:
            continue
        q25 = sub.quantile(0.25)
        q75 = sub.quantile(0.75)
        adaptation_gaps.append({
            'crop': crop, 'gwl_bin': gwl_bin,
            'worst_q25': q25, 'best_q75': q75,
            'adaptation_gap': q75 - q25, 'n': len(sub)
        })

adapt_df = pd.DataFrame(adaptation_gaps)
print("\nAdaptation gap (Q75 - Q25 of yield impact) within crop × warming level:")
print(adapt_df[['crop', 'gwl_bin', 'worst_q25', 'best_q75', 'adaptation_gap', 'n']].to_string(index=False))

# ── Strategy 2: Yield advantage of better-managed regions ──────────────────
print("\nRegional 'adaptation proxy': difference between observed and expected yield")
print("(regions whose mean impact is above the global mean at similar warming)")

global_slope, global_intercept, *_ = stats.linregress(
    df['global_delta_t_from_pre_industrial_period'], df['climate_impacts'])

df['expected_impact'] = global_slope * df['global_delta_t_from_pre_industrial_period'] + global_intercept
df['residual'] = df['climate_impacts'] - df['expected_impact']

region_residuals = df.groupby('region')['residual'].agg(
    mean_residual='mean', n='count'
).reset_index().sort_values('mean_residual', ascending=False)

print("\nRegions performing better (+) or worse (-) than expected:")
print(region_residuals.to_string(index=False))
print("(Positive = region does better than predicted → suggests local adaptation)")

# ── Strategy 3: What warming level is the 'tipping point' per crop ──────────
print("\nWarming tipping points (global ΔT at which mean impact crosses -20%):")
for crop in df['crop'].unique():
    sub = df[df['crop'] == crop].copy()
    for gwl in np.arange(1.0, 5.5, 0.1):
        mi = sub[sub['global_delta_t_from_pre_industrial_period'] <= gwl]['climate_impacts'].mean()
        if mi < -20:
            print(f"  {crop}: tipping point ~{gwl:.1f}°C (mean impact {mi:.1f}%)")
            break

# ── Strategy 4: Country-level best performers at high warming ──────────────
high_warm = df[df['global_delta_t_from_pre_industrial_period'] >= 3.0]
best_countries = high_warm.groupby(['country', 'region'])['climate_impacts'].mean().reset_index()
best_countries = best_countries[best_countries['climate_impacts'] > -5].sort_values('climate_impacts', ascending=False)
print("\nCountries with mean yield impact > -5% even at ≥3°C warming (resilient):")
print(best_countries.to_string(index=False))

# ── Visualisation ──────────────────────────────────────────────────────────
fig, axes = plt.subplots(2, 2, figsize=(15, 11))
fig.suptitle('Analysis 5 — Adaptation Strategies & Resilience', fontsize=14, fontweight='bold')

# Panel A: adaptation gap by crop
ax = axes[0, 0]
crops = adapt_df['crop'].unique()
gwl_bins_ordered = ['<1.5', '1.5-2', '2-2.5', '2.5-3', '3-4', '>4']
x = np.arange(len(gwl_bins_ordered))
width = 0.22
for i, crop in enumerate(['Maize', 'Rice', 'Wheat', 'Soybean']):
    sub = adapt_df[adapt_df['crop'] == crop].set_index('gwl_bin')
    gaps = [sub.loc[b, 'adaptation_gap'] if b in sub.index else np.nan for b in gwl_bins_ordered]
    ax.bar(x + i * width, gaps, width, label=crop, color=CROP_COLORS[crop], alpha=0.85)
ax.set_xticks(x + width * 1.5); ax.set_xticklabels(gwl_bins_ordered, fontsize=9)
ax.set_xlabel('Global Warming Level (°C)', fontsize=10)
ax.set_ylabel('Adaptation Gap (Q75-Q25, %)', fontsize=10)
ax.set_title('Adaptation Gap by Crop & Warming Level', fontsize=11)
ax.legend(fontsize=9); ax.grid(True, alpha=0.3, axis='y')

# Panel B: regional residuals (above/below expected)
ax2 = axes[0, 1]
colors = ['#2ecc71' if v >= 0 else '#e74c3c' for v in region_residuals['mean_residual']]
bars = ax2.barh(region_residuals['region'], region_residuals['mean_residual'],
                color=colors, alpha=0.8, edgecolor='white')
ax2.axvline(0, color='black', linewidth=1)
for bar, val in zip(bars, region_residuals['mean_residual']):
    ax2.text(val + 0.3 if val >= 0 else val - 0.3, bar.get_y() + bar.get_height()/2,
             f'{val:+.1f}%', va='center', ha='left' if val >= 0 else 'right', fontsize=9)
ax2.set_xlabel('Residual Impact vs Expected (%)', fontsize=10)
ax2.set_title('Regional Adaptation Proxy\n(vs. predicted from global warming)', fontsize=11)
ax2.grid(True, alpha=0.3, axis='x')

# Panel C: Q25 vs Q75 per crop (worst vs best managed)
ax3 = axes[1, 0]
crop_list = ['Maize', 'Rice', 'Wheat', 'Soybean']
q25s = [df[df['crop'] == c]['climate_impacts'].quantile(0.25) for c in crop_list]
q75s = [df[df['crop'] == c]['climate_impacts'].quantile(0.75) for c in crop_list]
medians = [df[df['crop'] == c]['climate_impacts'].median() for c in crop_list]
x = np.arange(len(crop_list))
ax3.bar(x - 0.25, q25s, 0.25, label='Q25 (worst outcomes)', color='#e74c3c', alpha=0.8)
ax3.bar(x, medians, 0.25, label='Median', color='#f39c12', alpha=0.8)
ax3.bar(x + 0.25, q75s, 0.25, label='Q75 (best outcomes)', color='#2ecc71', alpha=0.8)
ax3.set_xticks(x); ax3.set_xticklabels(crop_list, fontsize=11)
ax3.axhline(0, color='black', linewidth=0.8)
ax3.set_ylabel('Yield Impact (%)', fontsize=10)
ax3.set_title('Worst vs Median vs Best Outcomes\n(adaptation headroom)', fontsize=11)
ax3.legend(fontsize=9); ax3.grid(True, alpha=0.3, axis='y')

# Panel D: crop mean impact vs warming with confidence intervals
ax4 = axes[1, 1]
gwl_centers = np.arange(0.5, 5.5, 0.5)
for crop, color in CROP_COLORS.items():
    sub = df[df['crop'] == crop]
    means, lowers, uppers = [], [], []
    for gwl in gwl_centers:
        bucket = sub[(sub['global_delta_t_from_pre_industrial_period'] >= gwl - 0.5) &
                     (sub['global_delta_t_from_pre_industrial_period'] < gwl + 0.5)]['climate_impacts']
        if len(bucket) < 5:
            means.append(np.nan); lowers.append(np.nan); uppers.append(np.nan)
        else:
            m = bucket.mean(); se = bucket.sem()
            means.append(m); lowers.append(m - 1.96*se); uppers.append(m + 1.96*se)
    means, lowers, uppers = np.array(means), np.array(lowers), np.array(uppers)
    valid = ~np.isnan(means)
    ax4.plot(gwl_centers[valid], means[valid], color=color, linewidth=2.5, label=crop, marker='o', markersize=4)
    ax4.fill_between(gwl_centers[valid], lowers[valid], uppers[valid], color=color, alpha=0.15)
ax4.axhline(0, color='black', linewidth=0.8, linestyle='--')
ax4.axhline(-20, color='red', linewidth=0.8, linestyle=':', label='-20% threshold')
ax4.set_xlabel('Global Warming Level (°C)', fontsize=10)
ax4.set_ylabel('Mean Yield Impact (%)', fontsize=10)
ax4.set_title('Crop Response Curves with 95% CI', fontsize=11)
ax4.legend(fontsize=9); ax4.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig('/home/claude/ruda_analysis/ruda_viz5_adaptation.png', dpi=150, bbox_inches='tight')
plt.close()
print("\n✓ Visualisation saved: ruda_viz5_adaptation.png")
