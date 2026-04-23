-- Create Report: gold.report_products
/*Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
       - total orders
       - total sales
       - total quantity sold
       - total customers (unique)
       - lifespan (in months)
    4. Calculates valuable KPIs:
       - recency (months since last sale)
       - average order revenue (AOR)
       - average monthly revenue */

IF OBJECT_ID('gold.report_products', 'V') IS NOT NULL
    DROP VIEW gold.report_products;
GO

-- Create Report: gold.report_products
create view gold.product_report as
--1) Base Query: Retrieves core columns from fact_sales and dim_products
with base as(
select
f.product_surrogate_key,
p.product_name,
p.category,
p.sub_category,
p.cost,
f.order_date,
f.quantity,
f.sales,
f.order_number,
f.customer_surrogate_key
from gold.fact_sales f
left join
gold.dim_products p 
on f.product_surrogate_key=p.product_surrogate_key)

,metrics as(
--2) Product Aggregations: Summarizes key metrics at the product level
select
product_surrogate_key,
product_name,
category,
sub_category,
cost,
sum(quantity) as total_quantity,
sum(sales) as total_sales,
count(customer_surrogate_key) as total_customers,
count( distinct order_number) as total_orders,
max(order_date) as last_sale_date,
datediff(month,min(order_date),max(order_date)) as life_span
from base
group by product_surrogate_key,
product_name,
category,
sub_category,
cost)
 -- 3) Final Query: Combines all product results into one output
select 
product_surrogate_key,
product_name,
category,
sub_category,
cost,
total_quantity,
total_sales,
total_customers,
total_orders,
last_sale_date,
life_span,
CASE WHEN total_sales > 50000 THEN 'High-Performer'
	WHEN total_sales >= 10000 THEN 'Mid-Range'
	ELSE 'Low-Performer'
END AS product_segment,
DATEDIFF(year, last_sale_date, GETDATE()) AS recency_in_months,
-- Average Order Revenue (AOR)
case when total_orders =0 then 0
else (total_sales/total_orders)  
end as avg_order_revenue,
 --average monthly revenue
 case when life_span=0 then 0
 else total_sales/life_span
 end as average_monthly_revenue

from metrics