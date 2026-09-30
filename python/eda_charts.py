"""
INDIAN E-COMMERCE PRICING & REVENUE GROWTH - PYTHON EDA
Dataset: 30,600 orders | 36 months (Jan 2023 - Dec 2025) | 14 states | 8 categories
Author : Raushan

Each chart below is picked to answer ONE specific business question,
not just "show a chart because data exists". That reasoning is written
above each block so it doubles as documentation for the portfolio.
"""

import pandas as pd
from pathlib import Path
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import seaborn as sns

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------
sns.set_style("whitegrid")
plt.rcParams.update({
    "figure.dpi": 150,
    "font.size": 10,
    "axes.titlesize": 13,
    "axes.titleweight": "bold",
    "axes.edgecolor": "#333333",
})
NAVY, GREEN, RED, GREY, TEAL = "#1f3a5f", "#2e7d32", "#c62828", "#7f8c8d", "#00838f"

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATA_FILE = list((PROJECT_ROOT / "data").glob("*.csv"))[0]
df = pd.read_csv(DATA_FILE)
df["order_date"] = pd.to_datetime(df["order_date"])
df["year"] = df["order_date"].dt.year
OUT = str(PROJECT_ROOT / "charts") + "/"

def crore(x, pos):
    return f"{x/1e7:.1f}Cr"

# ---------------------------------------------------------------------------
# Chart 1 - Monthly revenue trend (line)
# ---------------------------------------------------------------------------
monthly = df.groupby("order_date")["revenue"].sum().reset_index()
monthly["rolling_3m"] = monthly["revenue"].rolling(3).mean()

fig, ax = plt.subplots(figsize=(10, 4.5))
ax.plot(monthly["order_date"], monthly["revenue"], color=GREY, alpha=0.5, linewidth=1.2, label="Monthly revenue")
ax.plot(monthly["order_date"], monthly["rolling_3m"], color=NAVY, linewidth=2.4, label="3-month rolling avg")
ax.set_title("Monthly Revenue Trend (Jan 2023 - Dec 2025)\nRolling average confirms growth is essentially flat")
ax.set_ylabel("Revenue (Rs)")
ax.yaxis.set_major_formatter(mticker.FuncFormatter(crore))
ax.legend(frameon=False)
plt.tight_layout()
plt.savefig(OUT + "chart1_monthly_trend.png")
plt.close()

# ---------------------------------------------------------------------------
# Chart 2 - State-wise growth 2023 vs 2025 (diverging horizontal bar)
# ---------------------------------------------------------------------------
piv = df[df.year.isin([2023, 2025])].pivot_table(index="state", columns="year", values="revenue", aggfunc="sum")
piv["growth_pct"] = (piv[2025] - piv[2023]) / piv[2023] * 100
piv = piv.sort_values("growth_pct")
colors = [RED if v < 0 else GREEN for v in piv["growth_pct"]]

fig, ax = plt.subplots(figsize=(9, 6))
ax.barh(piv.index, piv["growth_pct"], color=colors)
ax.axvline(0, color="#333333", linewidth=0.8)
ax.set_title("State-wise Revenue Growth: 2023 vs 2025\nFlat national growth hides a 23-point swing between best and worst state",
             fontsize=12)
ax.set_xlabel("Growth % (2023 -> 2025)")
ax.set_xlim(piv["growth_pct"].min() - 4, piv["growth_pct"].max() + 4)
for i, v in enumerate(piv["growth_pct"]):
    ax.text(v + (0.4 if v >= 0 else -0.4), i, f"{v:.1f}%", va="center",
            ha="left" if v >= 0 else "right", fontsize=8.5)
plt.tight_layout()
plt.savefig(OUT + "chart2_state_growth.png")
plt.close()

# ---------------------------------------------------------------------------
# Chart 3 - Category revenue share (ranked horizontal bar)
# ---------------------------------------------------------------------------
cat = df.groupby("category")["revenue"].sum().sort_values()
pct = cat / cat.sum() * 100

fig, ax = plt.subplots(figsize=(8, 5))
bars = ax.barh(cat.index, cat.values, color=TEAL)
ax.set_title("Revenue Contribution by Category\nTop 2 categories = 53.7% of all revenue - concentration risk")
ax.xaxis.set_major_formatter(mticker.FuncFormatter(crore))
for bar, p in zip(bars, pct.values):
    ax.text(bar.get_width() * 1.01, bar.get_y() + bar.get_height()/2, f"{p:.1f}%", va="center", fontsize=8.5)
plt.tight_layout()
plt.savefig(OUT + "chart3_category_share.png")
plt.close()

# ---------------------------------------------------------------------------
# Chart 4 - Discount sweet spot (combo: bar = avg revenue, line = avg units)
# ---------------------------------------------------------------------------
df["discount_band"] = pd.cut(df["discount_percent"], [0, 20, 40, 60, 100],
                              labels=["0-20%", "20-40%", "40-60%", "60%+"], include_lowest=True)
band = df.groupby("discount_band", observed=True).agg(avg_revenue=("revenue", "mean"), avg_units=("units_sold", "mean"))

fig, ax1 = plt.subplots(figsize=(8, 5))
ax1.bar(band.index.astype(str), band["avg_revenue"], color=NAVY, alpha=0.85, label="Avg revenue/order")
ax1.set_ylabel("Avg Revenue per Order (Rs)", color=NAVY)
ax1.set_title("Discount Sweet Spot: 20-40% Band Wins on Revenue\nDespite 60%+ band selling the most units")
ax2 = ax1.twinx()
ax2.plot(band.index.astype(str), band["avg_units"], color=RED, marker="o", linewidth=2.4, label="Avg units/order")
ax2.set_ylabel("Avg Units per Order", color=RED)
ax2.grid(False)
lines1, labels1 = ax1.get_legend_handles_labels()
lines2, labels2 = ax2.get_legend_handles_labels()
ax1.legend(lines1 + lines2, labels1 + labels2, loc="upper center", frameon=False)
plt.tight_layout()
plt.savefig(OUT + "chart4_discount_sweetspot.png")
plt.close()

# ---------------------------------------------------------------------------
# Chart 5 - Festival lift by category (grouped bar)
# ---------------------------------------------------------------------------
fest = df.groupby(["category", "sales_event"])["revenue"].mean().unstack()
fest["lift_pct"] = (fest["Festival"] - fest["Normal"]) / fest["Normal"] * 100
fest = fest.sort_values("lift_pct")

fig, ax = plt.subplots(figsize=(9, 5.5))
fest[["Festival", "Normal"]].plot(kind="barh", ax=ax, color=[GREY, NAVY])
ax.set_title("Festival Lift by Category\nBeauty & Personal Care responds most (+65%); Fashion least (+46%)", fontsize=12)
ax.set_ylabel("")
ax.xaxis.set_major_formatter(mticker.FuncFormatter(lambda x, pos: f"{x/1000:.0f}K"))
ax.set_xlabel("Avg Revenue per Order (Rs)")
ax.legend(title="", frameon=False)
plt.tight_layout()
plt.savefig(OUT + "chart5_festival_lift.png")
plt.close()

# ---------------------------------------------------------------------------
# Chart 6 - Correlation heatmap of numeric features
# ---------------------------------------------------------------------------
num_cols = ["customer_age", "base_price", "discount_percent", "final_price", "units_sold", "revenue"]
corr = df[num_cols].corr()

fig, ax = plt.subplots(figsize=(9, 6))
sns.heatmap(corr, annot=True, fmt=".2f", cmap="RdBu_r", center=0, ax=ax,
            cbar_kws={"label": "Correlation"}, linewidths=0.5)
ax.set_title("Correlation Heatmap\nDiscount% barely correlates with revenue (-0.01) despite driving units (+0.39)",
              fontsize=12)
plt.tight_layout()
plt.savefig(OUT + "chart6_correlation_heatmap.png")
plt.close()

print("All 6 charts saved to", OUT)
