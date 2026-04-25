"""
Analysis 1: Temperature Increase vs Yield Decline
Author: Ruda
Dataset: Climate Change Impact on Food Production (4,364 simulations, 83 countries)
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from scipy import stats

# ── Load data ──────────────────────────────────────────────────────────────
df = pd.read_csv('/mnt/user-data/uploads/clean_data.csv')

# ── Analysis ───────────────────────────────────────────────────────────────
print("=" * 60)
print("ANALYSIS 1: TEMPERATURE INCREASE VS YIELD DECLINE")
print("=" * 60)

print(f"\nTotal simulations: {len(df):,}")
print(f"Temperature range: {df['local_delta_t'].min():.2f}°C — {df['local_delta_t'].max():.2f}°C")
print(f"Mean temperature increase: {df['local_delta_t'].mean():.2f}°C")

# Bin temperatures into brackets
bins = [0, 1, 2, 3, 4, 5, 7]
labels = ['0-1°C', '1-2°C', '2-3°C', '3-4°C', '4-5°C', '5+°C']
df['temp_bin'] = pd.cut(df['local_delta_t'], bins=bins, labels=labels)

bin_summary = df.groupby('temp_bin', observed=True)['climate_impacts'].agg(
    count='count',
    mean_impact='mean',
    median_impact='median',
    pct_negative=lambda x: (x < 0).mean() * 100
).reset_index()

print("\nYield impact by temperature bracket:")
print(bin_summary.to_string(index=False))

# Correlation
r, p = stats.pearsonr(df['local_delta_t'], df['climate_impacts'])
print(f"\nPearson correlation (local ΔT vs yield impact): r={r:.3f}, p={p:.2e}")

# Linear regression
slope, intercept, r2, p_val, se = stats.linregress(df['local_delta_t'], df['climate_impacts'])
print(f"Linear regression: yield_impact = {slope:.2f}×ΔT + {intercept:.2f}")
print(f"R² = {r2**2:.3f}")
print(f"\nInterpretation: Each additional 1°C of local warming is associated with")
print(f"a {abs(slope):.1f}% change in crop yield (negative = decline).")

# ── Visualisation ──────────────────────────────────────────────────────────
CROP_COLORS = {'Maize': '#E8A838', 'Rice': '#4CA96B', 'Wheat': '#5B8FD4', 'Soybean': '#D4675B'}

fig, axes = plt.subplots(1, 2, figsize=(14, 6))
fig.suptitle('Analysis 1 — Temperature Increase vs Crop Yield Decline', fontsize=14, fontweight='bold', y=1.01)

# Panel A: scatter with regression
ax = axes[0]
for crop, color in CROP_COLORS.items():
    subset = df[df['crop'] == crop]
    ax.scatter(subset['local_delta_t'], subset['climate_impacts'],
               alpha=0.25, s=12, color=color, label=crop)

x_range = np.linspace(df['local_delta_t'].min(), df['local_delta_t'].max(), 200)
ax.plot(x_range, slope * x_range + intercept, color='black', linewidth=2, linestyle='--', label=f'Trend (r={r:.2f})')
ax.axhline(0, color='red', linewidth=0.8, linestyle=':')
ax.set_xlabel('Local Temperature Increase (°C)', fontsize=11)
ax.set_ylabel('Climate Impact on Yield (%)', fontsize=11)
ax.set_title('Scatter: All Crops', fontsize=11)
ax.legend(fontsize=9)
ax.grid(True, alpha=0.3)

# Panel B: bar chart of mean impact per bin
ax2 = axes[1]
colors = ['#2ecc71' if v >= 0 else '#e74c3c' for v in bin_summary['mean_impact']]
bars = ax2.bar(bin_summary['temp_bin'], bin_summary['mean_impact'], color=colors, edgecolor='white', linewidth=0.5)
ax2.axhline(0, color='black', linewidth=0.8)
ax2.set_xlabel('Local Temperature Bracket (°C)', fontsize=11)
ax2.set_ylabel('Mean Yield Impact (%)', fontsize=11)
ax2.set_title('Mean Yield Impact per Temperature Bracket', fontsize=11)
for bar, val in zip(bars, bin_summary['mean_impact']):
    ax2.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.5 if val >= 0 else bar.get_height() - 2,
             f'{val:.1f}%', ha='center', va='bottom', fontsize=9, fontweight='bold')
ax2.grid(True, alpha=0.3, axis='y')

plt.tight_layout()
plt.savefig('/home/claude/ruda_analysis/ruda_viz1_temperature_vs_yield.png', dpi=150, bbox_inches='tight')
plt.close()
print("\n✓ Visualisation saved: ruda_viz1_temperature_vs_yield.png")
