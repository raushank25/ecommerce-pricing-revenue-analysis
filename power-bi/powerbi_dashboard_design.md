# Power BI Dashboard Design
### Indian E-Commerce Pricing & Revenue Growth Analysis
30,600 orders | 36 months (Jan 2023 - Dec 2025) | 14 states | 8 categories

> Note: I don't have Power BI Desktop in this environment, so this is a
> complete build blueprint - data model, DAX, page-by-page layout, and the
> reasoning behind each choice. Follow it in Power BI Desktop and you'll
> have a portfolio-ready .pbix in under an hour.

---

## 1. Data Model (Star Schema)

Don't load the flat CSV as one giant table - a star schema is what
interviewers actually look for. Split it into one fact table and three
dimension tables using Power Query:

```
dim_date        dim_geography       dim_product
----------      -------------       -----------
date (PK)       state (PK)          category (PK)
year                 zone            brand_type
month_no
month_name           |                    |
quarter              |                    |
is_festival_month     \                  /
     |                 \                /
     |                  \              /
     +---------------  fact_orders  ---
                    -------------------
                    order_id
                    date        (FK -> dim_date)
                    state       (FK -> dim_geography)
                    category    (FK -> dim_product)
                    customer_gender, customer_age
                    base_price, discount_percent, final_price
                    units_sold, revenue
                    sales_event, competition_intensity, inventory_pressure
```

**Why split it up:** `state` always maps to exactly one `zone` and
`category` doesn't change attributes — that's a textbook dimension, not
fact data. Splitting it shows you understand normalization, not just
"drag CSV into Power BI."

**Build steps in Power Query:**
1. Load the CSV once as `orders_raw`.
2. Reference it three times → `dim_geography` (keep `state`, `zone`,
   remove duplicates), `dim_product` (keep `category`, `brand_type`,
   remove duplicates), `dim_date` (see DAX date table below).
3. In `orders_raw` itself (now `fact_orders`), keep all columns — the
   relationships handle the rest.
4. Model view → drag relationships: `fact_orders[state]` → `dim_geography[state]`,
   `fact_orders[category]` → `dim_product[category]`, `fact_orders[order_date]`
   → `dim_date[date]`. All should be **one-to-many, single direction**.

**Date table (DAX):**
```DAX
dim_date =
ADDCOLUMNS(
    CALENDAR(DATE(2023,1,1), DATE(2025,12,31)),
    "Year", YEAR([Date]),
    "MonthNo", MONTH([Date]),
    "MonthName", FORMAT([Date], "MMM"),
    "Quarter", "Q" & FORMAT([Date], "Q"),
    "YearMonth", FORMAT([Date], "MMM YYYY")
)
```
Mark this table as the official **Date Table** (Table tools → Mark as
Date Table) so time-intelligence functions work.

---

## 2. Core DAX Measures

```DAX
Total Revenue = SUM(fact_orders[revenue])

Total Units = SUM(fact_orders[units_sold])

Total Orders = COUNTROWS(fact_orders)

Avg Order Value = DIVIDE([Total Revenue], [Total Orders])

Avg Discount % = AVERAGE(fact_orders[discount_percent])

-- Year-over-year growth, needs the marked date table
Revenue LY =
CALCULATE([Total Revenue], SAMEPERIODLASTYEAR(dim_date[Date]))

Revenue YoY % =
DIVIDE([Total Revenue] - [Revenue LY], [Revenue LY])

-- Month-over-month, for the trend page
Revenue MoM % =
VAR PrevMonth = CALCULATE([Total Revenue], DATEADD(dim_date[Date], -1, MONTH))
RETURN DIVIDE([Total Revenue] - PrevMonth, PrevMonth)

-- Festival lift, reused on the Campaign page
Festival Avg Revenue =
CALCULATE([Avg Order Value], fact_orders[sales_event] = "Festival")

Normal Avg Revenue =
CALCULATE([Avg Order Value], fact_orders[sales_event] = "Normal")

Festival Lift % =
DIVIDE([Festival Avg Revenue] - [Normal Avg Revenue], [Normal Avg Revenue])

-- Revenue rank per category, for the Category page
Category Revenue Rank =
RANKX(ALL(dim_product[category]), [Total Revenue],, DESC)
```

---

## 3. Dashboard Pages

### Page 1 — Executive Overview
*What a stakeholder sees in the first 10 seconds.*

| Visual | Placement | Why this visual |
|---|---|---|
| 4 KPI cards: Total Revenue, YoY Growth %, Total Orders, Avg Discount % | Top strip | Cards force the headline numbers front and center |
| Line chart: monthly revenue with trend line | Center, large | Same story as your Chart 1 — shows the "flat growth" narrative immediately |
| Filled map of India: revenue by state | Right side | Geography reads faster as a map than a table for a country-scale dataset |
| Slicers: Year, Sales Event, Category | Top bar | Lets a stakeholder self-serve without a new page |

### Page 2 — Regional Performance
| Visual | Why |
|---|---|
| Diverging bar: state growth 2023 vs 2025 | Same as your Chart 2 — signed % needs a diverging bar, not a plain bar |
| Matrix: State (rows) x Category (columns), revenue, conditional formatting | Heatmap-in-a-table pinpoints exact weak combinations (e.g. Telangana x Grocery) without a scatter of tiny charts |
| Donut: revenue by zone | Only 5 zones — a donut is fine at this cardinality (avoid it for 8+ categories) |

### Page 3 — Category & Pricing Strategy
| Visual | Why |
|---|---|
| Bar: revenue share by category, sorted | Ranking is easiest to read sorted, not alphabetical |
| Combo chart: discount band (x-axis) → avg revenue (bars) + avg units (line) | Directly reproduces your "discount sweet spot" finding — this is your strongest visual, give it the biggest tile |
| Scatter: discount % vs revenue, colored by category, small multiples optional | Shows the near-zero correlation visually, category by category |

### Page 4 — Campaign & Competitive Pressure
| Visual | Why |
|---|---|
| Clustered bar: Festival vs Normal avg revenue, by category | Direct comparison, matches your Chart 5 |
| Bar: avg discount % and avg revenue by competition_intensity | Tests whether discounting harder against competition pays off (it doesn't, per your SQL) |
| Bar: same for inventory_pressure | Same test, different driver |

**Drill-through (optional, but interview-impressive):** right-click any
state bar → drill through to a "State Detail" page filtered to that
state, showing its own trend line and category mix. Small effort, shows
you understand drill-through vs slicers.

---

## 4. Filters & Slicers (apply on every page)
`Year` · `State` · `Category` · `Sales Event` · `Brand Type`
Put these in a **top slicer bar synced across all pages** (Format →
Edit interactions, or use a bookmark-based filter panel) — recruiters
notice when a dashboard *feels* like one product, not four disconnected
pages.

## 5. Color Theme
Stay consistent with the chart colors you already used in the Python
EDA, so the portfolio looks like one project:
- Primary (revenue): `#1F3A5F` (navy)
- Secondary (units/volume): `#C62828` (red) — used only on the discount
  sweet-spot chart to mirror the Python version
- Positive growth: `#2E7D32` (green) — negative growth: `#C62828` (red)
- Neutral/background bars: `#7F8C8D` (grey)
- Accent: `#00838F` (teal), for category charts

Import as a custom theme: View → Themes → Browse for themes → paste a
theme JSON with these hex codes so every page inherits it automatically.

---

## 6. What This Demonstrates (for your resume bullet)
*"Designed a 4-page Power BI dashboard on a star-schema data model
(30.6K rows) with 10+ DAX measures including YoY/MoM time intelligence,
synced cross-page filtering, and drill-through — surfaced a pricing
insight (20-40% discount band maximizes revenue) that a flat-table
report would have missed."*
