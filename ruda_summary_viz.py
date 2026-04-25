import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
from scipy import stats

df = pd.read_csv('/mnt/user-data/uploads/clean_data.csv')
CROP_COLORS = {'Maize': '#E8A838', 'Rice': '#4CA96B', 'Wheat': '#5B8FD4', 'Soybean': '#D4675B'}
REG_COLORS = {
    'Asia': '#E8A838', 'Africa': '#E05C3A', 'North America': '#4C7FD4',
    'Central and South America': '#4CA96B', 'Europe': '#9B59B6', 'Australasia': '#1ABC9C'
}

fig = plt.figure(figsize=(18, 12))
fig.patch.set_facecolor('#F8F9FA')
gs = gridspec.GridSpec(2, 3, figure=fig, hspace=0.45, wspace=0.35)
fig.suptitle('Climate Change & Food Security  —  Summary Dashboard\n4,364 Simulations  |  83 Countries  |  4 Crops  |  6 Regions',
             fontsize=15, fontweight='bold', y=0.98)

ax1 = fig.add_subplot(gs[0, 0])
crops = ['Soybean', 'Maize', 'Wheat', 'Rice']
means = [df[df['crop']==c]['climate_impacts'].mean() for c in crops]
colors = [CROP_COLORS[c] for c in crops]
bars = ax1.barh(crops, means, color=colors, alpha=0.85, edgecolor='white')
ax1.axvline(0, color='black', linewidth=0.8)
for bar, val in zip(bars, means):
    ax1.text(val - 0.5, bar.get_y() + bar.get_height()/2, f'{val:.1f}%',
             va='center', ha='right', fontsize=9, fontweight='bold', color='white')
ax1.set_title('Mean Yield Impact by Crop', fontsize=11, fontweight='bold')
ax1.set_xlabel('Mean Yield Impact (%)', fontsize=9)
ax1.grid(True, alpha=0.3, axis='x'); ax1.set_facecolor('#FAFAFA')

ax2 = fig.add_subplot(gs[0, 1])
reg_means = df.groupby('region')['climate_impacts'].mean().sort_values()
bar_colors = [REG_COLORS.get(r, '#888') for r in reg_means.index]
bars2 = ax2.barh(reg_means.index, reg_means.values, color=bar_colors, alpha=0.85, edgecolor='white')
ax2.axvline(0, color='black', linewidth=0.8)
for bar, val in zip(bars2, reg_means.values):
    ax2.text(val - 0.5, bar.get_y() + bar.get_height()/2, f'{val:.1f}%',
             va='center', ha='right', fontsize=8.5, fontweight='bold', color='white')
ax2.set_title('Mean Yield Impact by Region', fontsize=11, fontweight='bold')
ax2.set_xlabel('Mean Yield Impact (%)', fontsize=9)
ax2.grid(True, alpha=0.3, axis='x'); ax2.set_facecolor('#FAFAFA')
plt.setp(ax2.get_yticklabels(), fontsize=8)

ax3 = fig.add_subplot(gs[0, 2])
gwl_centers = np.arange(0.75, 5.5, 0.5)
for crop, color in CROP_COLORS.items():
    sub = df[df['crop'] == crop]
    means_gwl = []
    for gwl in gwl_centers:
        bucket = sub[(sub['global_delta_t_from_pre_industrial_period'] >= gwl - 0.5) &
                     (sub['global_delta_t_from_pre_industrial_period'] < gwl + 0.5)]['climate_impacts']
        means_gwl.append(bucket.mean() if len(bucket) >= 5 else np.nan)
    means_gwl = np.array(means_gwl)
    valid = ~np.isnan(means_gwl)
    ax3.plot(gwl_centers[valid], means_gwl[valid], color=color, linewidth=2.5, label=crop, marker='o', markersize=3)
ax3.axhline(0, color='black', linewidth=0.8, linestyle='--')
ax3.axhline(-20, color='red', linewidth=0.8, linestyle=':', alpha=0.7)
ax3.axvline(1.5, color='grey', linewidth=1, linestyle=':', alpha=0.6)
ax3.text(1.55, -38, '1.5C', fontsize=8, color='grey')
ax3.set_xlabel('Global Warming Level (C)', fontsize=9)
ax3.set_ylabel('Mean Yield Impact (%)', fontsize=9)
ax3.set_title('Crop Response Curves', fontsize=11, fontweight='bold')
ax3.legend(fontsize=8); ax3.grid(True, alpha=0.3); ax3.set_facecolor('#FAFAFA')

ax4 = fig.add_subplot(gs[1, 0])
items = list(CROP_COLORS.keys())
pcts = [df[df['crop']==c]['climate_impacts'].lt(0).mean()*100 for c in items]
ax4.bar(items, pcts, color=list(CROP_COLORS.values()), alpha=0.85, edgecolor='white')
ax4.axhline(50, color='red', linewidth=1, linestyle='--')
for i, pct in enumerate(pcts):
    ax4.text(i, pct + 1, f'{pct:.0f}%', ha='center', fontsize=9, fontweight='bold')
ax4.set_ylabel('% of Simulations', fontsize=9)
ax4.set_title('Probability of Yield Decline by Crop', fontsize=11, fontweight='bold')
ax4.set_ylim(0, 100); ax4.grid(True, alpha=0.3, axis='y'); ax4.set_facecolor('#FAFAFA')

ax5 = fig.add_subplot(gs[1, 1])
pivot = df.groupby(['region', 'crop'])['climate_impacts'].mean().unstack('crop')
region_order = df.groupby('region')['climate_impacts'].mean().sort_values().index
pivot = pivot.reindex(index=region_order)
im = ax5.imshow(pivot.values, cmap='RdYlGn', aspect='auto', vmin=-50, vmax=15)
ax5.set_xticks(range(len(pivot.columns))); ax5.set_xticklabels(pivot.columns, fontsize=9)
ax5.set_yticks(range(len(pivot.index)))
ax5.set_yticklabels([r.replace('Central and South America', 'C&S America') for r in pivot.index], fontsize=8)
plt.colorbar(im, ax=ax5, label='Mean Impact (%)', shrink=0.8)
for i in range(len(pivot.index)):
    for j in range(len(pivot.columns)):
        val = pivot.values[i, j]
        if not np.isnan(val):
            ax5.text(j, i, f'{val:.0f}%', ha='center', va='center', fontsize=8,
                     color='white' if abs(val) > 25 else 'black')
ax5.set_title('Heatmap: Crop x Region\nMean Yield Impact', fontsize=11, fontweight='bold')

ax6 = fig.add_subplot(gs[1, 2])
ax6.axis('off')
rect = plt.Rectangle((0, 0), 1, 1, fill=True, color='#EBF5FB', transform=ax6.transAxes, zorder=0)
ax6.add_patch(rect)
lines = [
    ("KEY FINDINGS", 0.95, 12, 'bold', '#2C3E50'),
    ("Critical threshold: 1.5C global warming", 0.84, 10, 'bold', '#E74C3C'),
    ("  Below 1.5C:  +3.6% avg yield", 0.76, 9.5, 'normal', '#27AE60'),
    ("  Above 1.5C:  -14.6% avg yield", 0.69, 9.5, 'normal', '#E74C3C'),
    ("Crop vulnerability ranking:", 0.59, 10, 'bold', '#2C3E50'),
    ("  Maize:    78% prob. of decline", 0.52, 9.5, 'normal', '#E8A838'),
    ("  Soybean: 76% prob. of decline", 0.45, 9.5, 'normal', '#D4675B'),
    ("  Wheat:   67% prob. of decline", 0.38, 9.5, 'normal', '#5B8FD4'),
    ("  Rice:    54% (most resilient)", 0.31, 9.5, 'normal', '#4CA96B'),
    ("Most exposed region:", 0.21, 10, 'bold', '#2C3E50'),
    ("  C&S America:   mean -32.7%", 0.14, 9.5, 'normal', '#E74C3C'),
    ("Adaptation gap:  up to 45 pp", 0.05, 9.5, 'bold', '#8E44AD'),
]
for (text, y, size, weight, color) in lines:
    ax6.text(0.05, y, text, transform=ax6.transAxes, fontsize=size,
             fontweight=weight, color=color, va='top')
ax6.set_title('At-a-Glance', fontsize=11, fontweight='bold')

plt.savefig('/home/claude/ruda_analysis/ruda_viz0_summary_dashboard.png', dpi=150, bbox_inches='tight',
            facecolor='#F8F9FA')
plt.close()
print("Done")
