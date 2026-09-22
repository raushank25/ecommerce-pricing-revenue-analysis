E-Commerce Revenue & Pricing Analytics
📌 Project Overview

An end-to-end data analytics project investigating why an Indian e-commerce business's revenue growth stalled at ~1% a year despite an average 38% discount across all orders. Built using SQL, Python, and Power BI on 30,600 orders spanning 36 months, 14 states, and 8 product categories.

🎯 Objective

Find the root cause of stagnant year-over-year revenue growth
Test whether the existing discounting strategy is actually driving revenue or just volume
Identify specific states and categories responsible for growth and decline
Turn the findings into concrete, actionable business recommendations

🛠️ Technologies Used
SQL (SQLite / MySQL) — CTEs, window functions, business-question queries
Python — Pandas, Matplotlib, Seaborn for EDA and correlation analysis
Power BI — star-schema data model, DAX measures, interactive multi-page dashboard
Git / GitHub — version control and portfolio hosting

📊 Dataset
30,600 order records | 36 months (Jan 2023 – Dec 2025) | 14 states | 8 categories
16 fields: order_id, order_date, state, zone, category, brand_type, customer_gender, customer_age, base_price, discount_percent, final_price, units_sold, revenue, sales_event, competition_intensity, inventory_pressure
No missing values, no duplicate order IDs

🔍 Key Features
10 business-question SQL queries, each with a commented rationale
6 Python EDA visuals: revenue trend, state-wise growth, category share, discount-band analysis, festival lift, correlation heatmap
Interactive Power BI dashboard: KPI cards, cross-filtered slicers, MoM/YoY DAX measures, drill-down by state and category
A full business report — executive summary, key findings, and recommendations

⚙️ Methodology / Workflow
Data cleaning & validation — checked for nulls, duplicates, correct date parsing
SQL exploration — answered 10 core business questions directly against the data
Python EDA — trend, growth, and correlation analysis with visual storytelling
Power BI dashboard — star-schema model (fact + date/geography/product dimensions) with custom DAX measures
Business report — synthesized every finding into prioritized, actionable recommendations

📈 Key Insights & Results
The core finding: average discount was 38%, but discount % had almost no correlation with revenue (≈0), while it did drive unit volume (+0.39) — discounting was buying volume, not revenue
Sweet spot: the 20-40% discount band produced the highest revenue per order; 60%+ discounting produced the lowest, despite the most units sold
Flat growth was an illusion: national revenue grew ~1% a year, but that hid a 23-point swing — some states grew 8-12%, others declined 6-12%
Panic discounting doesn't pay off: in high-competition and high-inventory-pressure conditions, deeper discounts still resulted in lower average revenue per order than calmer conditions
Category concentration risk: just 2 of 8 categories drove 53.7% of all revenue
Festival timing works, unevenly: festival orders earned 60% more on average, ranging from +65% (Beauty & Personal Care) to +46% (Fashion)
5 specific state × category combinations were pinpointed as the sharpest decliners for direct intervention

🖼️ Dashboard / Screenshots

(Add dashboard screenshots here, e.g. ![Overview](screenshots/overview.png))

Overview page — KPI cards, revenue trend, category & state breakdown
MoM Revenue Growth — month-over-month trend across all 36 months

📂 Project Structure
ecommerce-pricing-revenue-analysis/
├── README.md
├── data/
│   └── ecommerce_pricing_revenue_36months.csv
├── sql/
│   └── business_questions.sql
├── python/
│   └── eda_charts.py
├── charts/
│   └── chart1-6...png
├── power-bi/
│   ├── dashboard.pbix
│   └── powerbi_dashboard_design.md
├── screenshots/
│   └── overview.png
└── report/
    └── business_report.md

🚀 How to Run
SQL: load data/ecommerce_pricing_revenue_36months.csv into a table named orders, then run any query in sql/business_questions.sql
Python: cd python && python eda_charts.py — regenerates all 6 charts into /charts
Power BI: open power-bi/dashboard.pbix directly, or follow powerbi_dashboard_design.md to rebuild from scratch

🔮 Future Scope
Add time-series forecasting (ARIMA/Prophet) for proactive revenue planning
Build a per-segment discount optimization model instead of one blanket recommendation
Validate the discount-revenue finding with a real A/B test (correlation → causation)
Bring in cost/COGS data to measure actual profit impact, not just revenue impact
Add customer-level tracking for RFM-style segmentation
Automate anomaly alerts for underperforming state/category combinations

👨‍💻 Author

Raushan — MCA (Artificial Intelligence & Data Science), Graphic Era Hill University, Dehradun Pursuing Data Analyst / AI-ML roles Connect on LinkedIn · GitHub
https://www.linkedin.com/in/raushan-kumar-2632a9259/
