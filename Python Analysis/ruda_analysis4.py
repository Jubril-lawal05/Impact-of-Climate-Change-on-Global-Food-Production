"""
Analysis 4: Regional Differences
Author: Ruda
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy import stats

df = pd.read_csv('/mnt/user-data/uploads/clean_data.csv')
REGIONS = df['region'].unique().tolist()
REG_COLORS = {
    'Asia': '#E8A838', 'Africa': '#E05C3A', 'North America': '#4C7FD4',
    'Central and South America': '#4CA96B', 'Europe': '#9B59B6', 'Australasia': '#1ABC9C'
}

print("=" * 60)
print("ANALYSIS 4: REGIONAL DIFFERENCES")
print("=" * 60)

reg_summary = df.groupby('region')['climate_impacts'].agg(
    n='count', mean='mean', median='median', std='std',
    pct_negative=lambda x: (x < 0).mean() * 100,
    pct_severe=lambda x: (x < -25).mean() * 100
).reset_index().sort_values('mean')

print("\nRegional yield impact summary:")
print(reg_summary.to_string(index=False))

# Most affected countries
print("\nTop 10 most negatively impacted countries (mean yield impact):")
country_mean = df.groupby(['country', 'region'])['climate_impacts'].mean().reset_index()
country_mean = country_mean.sort_values('climate_impacts').head(10)
print(country_mean.to_string(index=False))

# Crop × Region heatmap data
print("\nMean yield impact by Crop × Region:")
pivot = df.groupby(['region', 'crop'])['climate_impacts'].mean().unstack('crop')
print(pivot.round(1).to_string())

# Regional warming exposure
print("\nRegional warming exposure (mean local ΔT):")
reg_temp = df.groupby('region')['local_delta_t'].mean().sort_values(ascending=False)
print(reg_temp.round(2).to_string())

# ANOVA across regions
groups = [df[df['region'] == r]['climate_impacts'].values for r in REGIONS]
F, p_anova = stats.f_oneway(*groups)
print(f"\nANOVA across regions: F={F:.2f}, p={p_anova:.2e}")

# ── Visualisation ──────────────────────────────────────────────────────────
fig, axes = plt.subplots(2, 2, figsize=(15, 11))
fig.suptitle('Analysis 4 — Regional Differences in Climate Impact on Yield', fontsize=14, fontweight='bold')

# Panel A: bar chart mean impact per region
ax = axes[0, 0]
reg_sorted = reg_summary.sort_values('mean')
colors_sorted = [REG_COLORS.get(r, '#888') for r in reg_sorted['region']]
bars = ax.barh(reg_sorted['region'], reg_sorted['mean'], color=colors_sorted, alpha=0.85, edgecolor='white')
ax.axvline(0, color='black', linewidth=0.8)
for bar, val in zip(bars, reg_sorted['mean']):
    ax.text(val - 0.5 if val < 0 else val + 0.5, bar.get_y() + bar.get_height()/2,
            f'{val:.1f}%', va='center', ha='right' if val < 0 else 'left', fontsize=9, fontweight='bold')
ax.set_xlabel('Mean Yield Impact (%)', fontsize=10)
ax.set_title('Mean Yield Impact by Region', fontsize=11)
ax.grid(True, alpha=0.3, axis='x')

# Panel B: % negative per region
ax2 = axes[0, 1]
ax2.barh(reg_sorted['region'], reg_sorted['pct_negative'],
         color=colors_sorted, alpha=0.7, edgecolor='white')
ax2.axvline(50, color='red', linewidth=1, linestyle='--', label='50% threshold')
ax2.set_xlabel('% of Simulations with Yield Decline', fontsize=10)
ax2.set_title('Probability of Negative Impact', fontsize=11)
ax2.legend(fontsize=9); ax2.grid(True, alpha=0.3, axis='x')

# Panel C: heatmap Crop x Region
ax3 = axes[1, 0]
pivot_vals = pivot.reindex(index=reg_sorted['region'])
im = ax3.imshow(pivot_vals.values, cmap='RdYlGn', aspect='auto',
                vmin=-40, vmax=15)
ax3.set_xticks(range(len(pivot_vals.columns))); ax3.set_xticklabels(pivot_vals.columns, fontsize=10)
ax3.set_yticks(range(len(pivot_vals.index))); ax3.set_yticklabels(pivot_vals.index, fontsize=9)
plt.colorbar(im, ax=ax3, label='Mean Yield Impact (%)')
for i in range(len(pivot_vals.index)):
    for j in range(len(pivot_vals.columns)):
        val = pivot_vals.values[i, j]
        if not np.isnan(val):
            ax3.text(j, i, f'{val:.0f}%', ha='center', va='center', fontsize=9,
                     color='white' if abs(val) > 20 else 'black')
ax3.set_title('Heatmap: Crop × Region Impact (%)', fontsize=11)

# Panel D: box plot per region
ax4 = axes[1, 1]
reg_order = reg_sorted['region'].tolist()
data_by_reg = [df[df['region'] == r]['climate_impacts'].values for r in reg_order]
bp = ax4.boxplot(data_by_reg, tick_labels=[r.replace(' and ', '\n& ').replace('Central\n& South America', 'C&S\nAmerica')
                                           for r in reg_order],
                  patch_artist=True, notch=False, medianprops=dict(color='black', linewidth=2))
for patch, r in zip(bp['boxes'], reg_order):
    patch.set_facecolor(REG_COLORS.get(r, '#888')); patch.set_alpha(0.7)
ax4.axhline(0, color='red', linewidth=1, linestyle='--')
ax4.set_ylabel('Yield Impact (%)', fontsize=10)
ax4.set_title('Distribution by Region', fontsize=11)
ax4.grid(True, alpha=0.3, axis='y')
plt.setp(ax4.get_xticklabels(), fontsize=8)

plt.tight_layout()
plt.savefig('/home/claude/ruda_analysis/ruda_viz4_regional_differences.png', dpi=150, bbox_inches='tight')
plt.close()
print("\n✓ Visualisation saved: ruda_viz4_regional_differences.png")
