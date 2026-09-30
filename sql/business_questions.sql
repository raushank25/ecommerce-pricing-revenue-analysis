/* ==========================================================================
   INDIAN E-COMMERCE PRICING & REVENUE GROWTH ANALYSIS
   Dataset: 30,600 orders | 36 months (Jan 2023 - Dec 2025) | 14 states | 8 categories
   Author : Raushan
   Purpose: SQL layer of the portfolio project - each query answers one
            real business question a Pricing/Revenue stakeholder would ask.
   Tested on: SQLite (works on MySQL/PostgreSQL with minor date-function tweaks)
   ========================================================================== */


/* --------------------------------------------------------------------------
   Q1. How is monthly revenue trending over the 36 months?
   Business need: Spot seasonality, spikes, and slow months for planning.
-------------------------------------------------------------------------- */
SELECT
    strftime('%Y-%m', order_date) AS month,
    ROUND(SUM(revenue), 0)        AS total_revenue,
    SUM(units_sold)               AS total_units
FROM orders
GROUP BY month
ORDER BY month;


/* --------------------------------------------------------------------------
   Q2. What is the year-over-year revenue growth rate?
   Business need: Board-level headline metric.
   RESULT: 2023 -> 2024 = +0.20% | 2024 -> 2025 = +1.79%  (near-flat growth)
-------------------------------------------------------------------------- */
WITH yearly AS (
    SELECT strftime('%Y', order_date) AS year, SUM(revenue) AS total_revenue
    FROM orders
    GROUP BY year
)
SELECT
    year,
    ROUND(total_revenue, 0) AS total_revenue,
    ROUND(100.0 * (total_revenue - LAG(total_revenue) OVER (ORDER BY year))
          / LAG(total_revenue) OVER (ORDER BY year), 2) AS yoy_growth_pct
FROM yearly;


/* --------------------------------------------------------------------------
   Q3. Which states are driving growth and which are dragging it down?
   Business need: Flat national growth can hide big regional swings.
   RESULT: Kerala +11.9%, Haryana +11.5%, Gujarat +8.8% growing;
           Tamil Nadu -11.6%, Odisha -6.6%, MP -6.5% declining.
-------------------------------------------------------------------------- */
WITH state_year AS (
    SELECT state, strftime('%Y', order_date) AS year, SUM(revenue) AS revenue
    FROM orders
    WHERE strftime('%Y', order_date) IN ('2023', '2025')
    GROUP BY state, year
)
SELECT
    state,
    ROUND(MAX(CASE WHEN year = '2023' THEN revenue END), 0) AS revenue_2023,
    ROUND(MAX(CASE WHEN year = '2025' THEN revenue END), 0) AS revenue_2025,
    ROUND(100.0 * (MAX(CASE WHEN year = '2025' THEN revenue END)
                  - MAX(CASE WHEN year = '2023' THEN revenue END))
                  / MAX(CASE WHEN year = '2023' THEN revenue END), 2) AS growth_pct
FROM state_year
GROUP BY state
ORDER BY growth_pct DESC;


/* --------------------------------------------------------------------------
   Q4. Which categories contribute most to revenue, and how are they ranked?
   RESULT: Premium Lifestyle (29.8%) and Electronics (23.9%) = >50% of revenue.
           Grocery Essentials is the smallest and weakest category (1.4%).
-------------------------------------------------------------------------- */
SELECT
    category,
    ROUND(SUM(revenue), 0) AS total_revenue,
    ROUND(100.0 * SUM(revenue) / (SELECT SUM(revenue) FROM orders), 2) AS pct_of_total,
    RANK() OVER (ORDER BY SUM(revenue) DESC) AS revenue_rank
FROM orders
GROUP BY category
ORDER BY total_revenue DESC;


/* --------------------------------------------------------------------------
   Q5. Is there a discount "sweet spot" - does more discount always mean
       more revenue?
   Business need: Test if the discounting strategy is actually profitable.
   RESULT: 20-40% discount band has the HIGHEST avg revenue/order (Rs 74,214).
           60%+ discount band has the LOWEST avg revenue/order (Rs 63,950)
           despite having the most units sold - deep discounts are burning
           revenue, not building it.
-------------------------------------------------------------------------- */
SELECT
    CASE
        WHEN discount_percent < 20 THEN '0-20%'
        WHEN discount_percent < 40 THEN '20-40%'
        WHEN discount_percent < 60 THEN '40-60%'
        ELSE '60%+'
    END AS discount_band,
    COUNT(*)               AS orders,
    ROUND(AVG(units_sold), 1) AS avg_units,
    ROUND(AVG(revenue), 2)    AS avg_revenue
FROM orders
GROUP BY discount_band
ORDER BY discount_band;


/* --------------------------------------------------------------------------
   Q6. Does a Festival sales event actually lift revenue, and does it lift
       every category equally?
   RESULT: Electronics jumps from Rs 1,17,865 (Normal) to Rs 1,91,012
           (Festival) avg/order - the single biggest festival responder.
-------------------------------------------------------------------------- */
SELECT
    category,
    sales_event,
    ROUND(AVG(revenue), 0) AS avg_revenue
FROM orders
GROUP BY category, sales_event
ORDER BY category, sales_event;


/* --------------------------------------------------------------------------
   Q7. Does higher competition force deeper discounts, and does it pay off?
   RESULT: High competition -> avg discount 42.9% but avg revenue/order
           (Rs 70,922) is LOWER than Low competition (Rs 72,217, discount
           33.8%) - discounting harder against competition isn't winning
           more revenue per order.
-------------------------------------------------------------------------- */
SELECT
    competition_intensity,
    ROUND(AVG(discount_percent), 2) AS avg_discount,
    ROUND(AVG(revenue), 2)          AS avg_revenue,
    ROUND(AVG(units_sold), 2)       AS avg_units
FROM orders
GROUP BY competition_intensity
ORDER BY avg_revenue DESC;


/* --------------------------------------------------------------------------
   Q8. Which specific state + category combinations are declining the most?
   Business need: Pinpoint exactly where to intervene (not just "Tamil Nadu"
   or "Grocery" broadly, but the exact combination).
   RESULT: Telangana-Grocery Essentials -33.2%, MP-Beauty -32.2%,
           UP-Beauty -31.1%, Delhi NCR-Footwear -29.5%, TN-Sports -29.0%.
-------------------------------------------------------------------------- */
WITH combo AS (
    SELECT state, category, strftime('%Y', order_date) AS year, SUM(revenue) AS revenue
    FROM orders
    WHERE strftime('%Y', order_date) IN ('2023', '2025')
    GROUP BY state, category, year
),
pivoted AS (
    SELECT
        state, category,
        MAX(CASE WHEN year = '2023' THEN revenue END) AS rev_2023,
        MAX(CASE WHEN year = '2025' THEN revenue END) AS rev_2025
    FROM combo
    GROUP BY state, category
)
SELECT
    state, category,
    ROUND(rev_2023, 0) AS rev_2023,
    ROUND(rev_2025, 0) AS rev_2025,
    ROUND(100.0 * (rev_2025 - rev_2023) / rev_2023, 2) AS growth_pct
FROM pivoted
ORDER BY growth_pct ASC
LIMIT 5;


/* --------------------------------------------------------------------------
   Q9. How does Mass vs Premium brand performance differ by zone?
   RESULT: South and North zones are the biggest revenue pools for both
           brand types; Premium avg final price is consistently ~25-30%
           higher than Mass across every zone.
-------------------------------------------------------------------------- */
SELECT
    zone,
    brand_type,
    ROUND(SUM(revenue), 0) AS total_revenue,
    ROUND(AVG(final_price), 0) AS avg_final_price
FROM orders
GROUP BY zone, brand_type
ORDER BY zone, brand_type;


/* --------------------------------------------------------------------------
   Q10. Does high inventory pressure lead to panic-discounting, and does
        it help revenue?
   RESULT: High inventory pressure -> avg discount 43.2% but avg revenue
           (Rs 70,217) is lower than Low pressure (Rs 71,422, discount
           35.9%) - same pattern as Q7, discounting harder isn't paying off.
-------------------------------------------------------------------------- */
SELECT
    inventory_pressure,
    ROUND(AVG(discount_percent), 2) AS avg_discount,
    ROUND(AVG(revenue), 0)          AS avg_revenue
FROM orders
GROUP BY inventory_pressure;
