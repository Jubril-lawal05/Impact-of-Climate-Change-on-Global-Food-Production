"""
Analysis 2: Precipitation Change vs Yield Decline
Note: We use 'global_delta_t' as a proxy for climate stress level alongside
yield impacts, since no direct precipitation column exists. We also derive
rainfall-stress via global warming thresholds.
Author: Ruda
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy import stats

df = pd.read_csv('/mnt/user-data/uploads/clean_data.csv')

print("=" * 60)
print("ANALYSIS 2: GLOBAL WARMING LEVEL VS YIELD IMPACT")
print("(Using global delta T as the IPCC-aligned warming metric)")
print("=" * 60)

print(f"\nGlobal ΔT range: {df['global_delta_t_from_pre_industrial_period'].min():.2f} — "
      f"{df['global_delta_t_from_pre_industrial_period'].max():.2f}°C")

# IPCC warming thresholds
thresholds = [1.5, 2.0, 3.0, 4.0]
for t in thresholds:
    sub = df[df['global_delta_t_from_pre_industrial_period'] <= t]
    pct_neg = (sub['climate_impacts'] < 0).mean() * 100
    mean_imp = sub['climate_impacts'].mean()
    print(f"  At ≤{t}°C global warming: {len(sub):,} sims | mean impact {mean_imp:+.1f}% | {pct_neg:.1f}% negative")

# Bin global warming
bins = [0, 1.5, 2.0, 2.5, 3.0, 4.0, 6.0]
labels = ['<1.5°C', '1.5-2°C', '2-2.5°C', '2.5-3°C', '3-4°C', '>4°C']
df['gwl_bin'] = pd.cut(df['global_delta_t_from_pre_industrial_period'], bins=bins, labels=labels)

gwl_summary = df.groupby('gwl_bin', observed=True)['climate_impacts'].agg(
    n='count', mean='mean', median='median', std='std',
    pct_negative=lambda x: (x < 0).mean() * 100
).reset_index()

print("\nYield impact by Global Warming Level (GWL):")
print(gwl_summary.to_string(index=False))

r, p = stats.pearsonr(df['global_delta_t_from_pre_industrial_period'], df['climate_impacts'])
slope, intercept, _, _, _ = stats.linregress(df['global_delta_t_from_pre_industrial_period'], df['climate_impacts'])
print(f"\nCorrelation r={r:.3f} (p={p:.2e})")
print(f"Regression: per +1°C global warming → {slope:+.2f}% yield change")

# Crop-specific correlation with global warming
print("\nPer-crop correlation with global warming level:")
for crop in df['crop'].unique():
    sub = df[df['crop'] == crop]
    rc, pc = stats.pearsonr(sub['global_delta_t_from_pre_industrial_period'], sub['climate_impacts'])
    sc, ic, *_ = stats.linregress(sub['global_delta_t_from_pre_industrial_period'], sub['climate_impacts'])
    print(f"  {crop:<10} r={rc:+.3f}  slope={sc:+.2f}%/°C")

# ── Visualisation ──────────────────────────────────────────────────────────
CROP_COLORS = {'Maize': '#E8A838', 'Rice': '#4CA96B', 'Wheat': '#5B8FD4', 'Soybean': '#D4675B'}

fig, axes = plt.subplots(1, 2, figsize=(14, 6))
fig.suptitle('Analysis 2 — Global Warming Level vs Crop Yield Impact', fontsize=14, fontweight='bold')

# Panel A: box plot per GWL bin
ax = axes[0]
data_by_bin = [df[df['gwl_bin'] == lbl]['climate_impacts'].dropna().values for lbl in labels]
bp = ax.boxplot(data_by_bin, labels=labels, patch_artist=True, notch=False,
                medianprops=dict(color='black', linewidth=2))
palette = ['#3498db', '#2ecc71', '#f39c12', '#e67e22', '#e74c3c', '#8e44ad']
for patch, color in zip(bp['boxes'], palette):
    patch.set_facecolor(color); patch.set_alpha(0.7)
ax.axhline(0, color='red', linewidth=1, linestyle='--')
ax.set_xlabel('Global Warming Level (°C above pre-industrial)', fontsize=10)
ax.set_ylabel('Yield Impact (%)', fontsize=10)
ax.set_title('Distribution by Warming Level', fontsize=11)
ax.grid(True, alpha=0.3, axis='y')
plt.setp(ax.get_xticklabels(), fontsize=8)

# Panel B: per-crop trend lines
ax2 = axes[1]
x_range = np.linspace(df['global_delta_t_from_pre_industrial_period'].min(),
                       df['global_delta_t_from_pre_industrial_period'].max(), 200)
for crop, color in CROP_COLORS.items():
    sub = df[df['crop'] == crop]
    ax2.scatter(sub['global_delta_t_from_pre_industrial_period'], sub['climate_impacts'],
                alpha=0.15, s=10, color=color)
    sc, ic, *_ = stats.linregress(sub['global_delta_t_from_pre_industrial_period'], sub['climate_impacts'])
    ax2.plot(x_range, sc * x_range + ic, color=color, linewidth=2.5, label=f'{crop} ({sc:+.1f}%/°C)')

# IPCC lines
for t, lbl in [(1.5, '1.5°C'), (2.0, '2°C')]:
    ax2.axvline(t, color='grey', linewidth=1, linestyle=':', alpha=0.8)
    ax2.text(t + 0.05, ax2.get_ylim()[1] if ax2.get_ylim()[1] else 50, lbl, fontsize=8, color='grey')
ax2.axhline(0, color='black', linewidth=0.8, linestyle='--')
ax2.set_xlabel('Global Warming Level (°C)', fontsize=10)
ax2.set_ylabel('Yield Impact (%)', fontsize=10)
ax2.set_title('Per-crop Trend Lines', fontsize=11)
ax2.legend(fontsize=9)
ax2.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig('/home/claude/ruda_analysis/ruda_viz2_globalwarming_vs_yield.png', dpi=150, bbox_inches='tight')
plt.close()
print("\n✓ Visualisation saved: ruda_viz2_globalwarming_vs_yield.png")
