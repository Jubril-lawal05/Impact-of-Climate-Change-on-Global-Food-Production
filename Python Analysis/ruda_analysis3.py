"""
Analysis 3: Compare Maize, Wheat, Rice, Soybean
Author: Ruda
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy import stats

df = pd.read_csv('/mnt/user-data/uploads/clean_data.csv')
CROPS = ['Maize', 'Wheat', 'Rice', 'Soybean']
CROP_COLORS = {'Maize': '#E8A838', 'Rice': '#4CA96B', 'Wheat': '#5B8FD4', 'Soybean': '#D4675B'}

print("=" * 60)
print("ANALYSIS 3: CROP-BY-CROP COMPARISON")
print("=" * 60)

# Core stats per crop
summary = df.groupby('crop')['climate_impacts'].agg(
    n='count',
    mean='mean',
    median='median',
    std='std',
    q25=lambda x: x.quantile(0.25),
    q75=lambda x: x.quantile(0.75),
    pct_negative=lambda x: (x < 0).mean() * 100,
    pct_severe=lambda x: (x < -25).mean() * 100
).reset_index().sort_values('mean')

print("\nCore statistics per crop:")
print(summary.to_string(index=False))

# Yield under different warming scenarios
print("\nMean yield impact under different global warming scenarios:")
print(f"{'Crop':<12}", end='')
for gwl in [1.5, 2.0, 3.0, 4.0]:
    print(f"  ≤{gwl}°C", end='')
print()
for crop in CROPS:
    sub = df[df['crop'] == crop]
    print(f"{crop:<12}", end='')
    for gwl in [1.5, 2.0, 3.0, 4.0]:
        imp = sub[sub['global_delta_t_from_pre_industrial_period'] <= gwl]['climate_impacts'].mean()
        print(f"  {imp:+5.1f}%", end='')
    print()

# ANOVA to test if crop differences are significant
groups = [df[df['crop'] == c]['climate_impacts'].values for c in CROPS]
F, p_anova = stats.f_oneway(*groups)
print(f"\nOne-way ANOVA: F={F:.2f}, p={p_anova:.2e}")
print("Conclusion:", "Crop type SIGNIFICANTLY affects yield impact." if p_anova < 0.05
      else "No significant difference between crops.")

# Pairwise Mann-Whitney U tests
print("\nPairwise Mann-Whitney U (p-values):")
for i, c1 in enumerate(CROPS):
    for c2 in CROPS[i+1:]:
        u, p = stats.mannwhitneyu(df[df['crop']==c1]['climate_impacts'],
                                   df[df['crop']==c2]['climate_impacts'], alternative='two-sided')
        sig = '***' if p < 0.001 else '**' if p < 0.01 else '*' if p < 0.05 else 'ns'
        print(f"  {c1} vs {c2}: p={p:.4f} {sig}")

# ── Visualisation ──────────────────────────────────────────────────────────
fig, axes = plt.subplots(2, 2, figsize=(14, 11))
fig.suptitle('Analysis 3 — Crop Comparison: Climate Impact on Yield', fontsize=14, fontweight='bold')

# Panel A: violin plot
ax = axes[0, 0]
positions = range(len(CROPS))
for i, crop in enumerate(CROPS):
    data = df[df['crop'] == crop]['climate_impacts'].values
    parts = ax.violinplot([data], positions=[i], showmedians=True, showextrema=True)
    for pc in parts['bodies']:
        pc.set_facecolor(CROP_COLORS[crop]); pc.set_alpha(0.7)
    for part in ['cmedians', 'cmaxes', 'cmins', 'cbars']:
        parts[part].set_color('black')
ax.set_xticks(list(positions)); ax.set_xticklabels(CROPS, fontsize=11)
ax.axhline(0, color='red', linewidth=1, linestyle='--')
ax.set_ylabel('Yield Impact (%)', fontsize=10)
ax.set_title('Distribution by Crop (Violin)', fontsize=11)
ax.grid(True, alpha=0.3, axis='y')

# Panel B: mean impact per crop per warming level
ax2 = axes[0, 1]
gwl_vals = [1.5, 2.0, 3.0, 4.0]
x = np.arange(len(gwl_vals))
width = 0.2
for i, (crop, color) in enumerate(CROP_COLORS.items()):
    means = []
    for gwl in gwl_vals:
        sub = df[(df['crop'] == crop) & (df['global_delta_t_from_pre_industrial_period'] <= gwl)]
        means.append(sub['climate_impacts'].mean() if len(sub) > 0 else np.nan)
    ax2.bar(x + i * width, means, width, label=crop, color=color, alpha=0.85)
ax2.set_xticks(x + width * 1.5); ax2.set_xticklabels([f'≤{g}°C' for g in gwl_vals], fontsize=10)
ax2.axhline(0, color='black', linewidth=0.8)
ax2.set_ylabel('Mean Yield Impact (%)', fontsize=10)
ax2.set_title('Mean Impact by Global Warming Level', fontsize=11)
ax2.legend(fontsize=9); ax2.grid(True, alpha=0.3, axis='y')

# Panel C: % of simulations with negative impact
ax3 = axes[1, 0]
pct_neg = [df[df['crop'] == c]['climate_impacts'].lt(0).mean() * 100 for c in CROPS]
pct_severe = [df[df['crop'] == c]['climate_impacts'].lt(-25).mean() * 100 for c in CROPS]
x = np.arange(len(CROPS))
ax3.bar(x - 0.2, pct_neg, 0.4, label='Any decline (<0%)', color=[CROP_COLORS[c] for c in CROPS], alpha=0.85)
ax3.bar(x + 0.2, pct_severe, 0.4, label='Severe decline (<-25%)', color=[CROP_COLORS[c] for c in CROPS], alpha=0.4)
ax3.set_xticks(x); ax3.set_xticklabels(CROPS, fontsize=11)
ax3.set_ylabel('% of Simulations', fontsize=10)
ax3.set_title('Risk of Yield Decline', fontsize=11)
ax3.legend(fontsize=9); ax3.grid(True, alpha=0.3, axis='y')
for xi, (n, s) in enumerate(zip(pct_neg, pct_severe)):
    ax3.text(xi - 0.2, n + 1, f'{n:.0f}%', ha='center', fontsize=8, fontweight='bold')
    ax3.text(xi + 0.2, s + 1, f'{s:.0f}%', ha='center', fontsize=8)

# Panel D: scatter of local vs global temp colored by crop
ax4 = axes[1, 1]
for crop, color in CROP_COLORS.items():
    sub = df[df['crop'] == crop]
    ax4.scatter(sub['local_delta_t'], sub['global_delta_t_from_pre_industrial_period'],
                alpha=0.2, s=10, color=color, label=crop)
ax4.set_xlabel('Local ΔT (°C)', fontsize=10)
ax4.set_ylabel('Global ΔT from pre-industrial (°C)', fontsize=10)
ax4.set_title('Local vs Global Temperature per Crop', fontsize=11)
ax4.legend(fontsize=9); ax4.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig('/home/claude/ruda_analysis/ruda_viz3_crop_comparison.png', dpi=150, bbox_inches='tight')
plt.close()
print("\n✓ Visualisation saved: ruda_viz3_crop_comparison.png")
