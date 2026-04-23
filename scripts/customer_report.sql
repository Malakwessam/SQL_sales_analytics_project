/*  CUSTOMER REPORT(metrics and behavior)

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
	   - total orders
	   - total sales
	   - total quantity purchased
	   - total products
	   - lifespan (in months)
    4. Calculates valuable KPIs:
	    - recency (months since last order)
		- average order value
		- average monthly spend

*/

IF OBJECT_ID('gold.report_customers', 'V') IS NOT NULL
    DROP VIEW gold.report_customers;
GO
create view gold.customers_report as
 --base:retrives core columns from tables
with base as(    
select
s.product_surrogate_key,
s.customer_surrogate_key,
s.order_date,
s.sales,
s.quantity,
s.order_number,
concat(c.first_name,' ',c.last_name) as customer_name,
datediff(year,c.birthdate,getdate()) as age
from gold.fact_sales s
left join gold.dim_customers c
on s.customer_surrogate_key=c.customer_surrogate_key
where order_date is not null)

--summarizes key metrics
,customer_aggregation as(  
select 
	customer_surrogate_key,
	customer_name,
	age,
	count(distinct order_number) as total_orders,
	sum(sales) as total_sales,
	sum(quantity) as total_quantity ,
	count(product_surrogate_key) as total_products,
	max(order_date) as last_order_date,
	datediff(month,min(order_date),max(order_date)) as life_span
from base
group by 
customer_surrogate_key,
customer_name,
age)

select
	customer_surrogate_key,
	customer_name,
	age,
	case when age <30 then 'under 30'
	when age between 30 and 60 then '30-60'
	else 'above 50'
	end age_range,
	case when life_span>= 12 and total_sales >5000 then 'vip'
		when life_span>= 12 and total_sales <=5000 then 'regular'
		else 'new' 
	end as category,
	datediff(month,last_order_date,getdate()) as recency, 
	total_orders,
	total_sales,
	total_quantity ,
	total_products,
	case when total_sales=0 then 0
	else total_orders/total_sales 
	end as avg_order_value,
	case when life_span =0 then total_sales
	else total_sales/ life_span
	end avg_sales_per_month,
	life_span
from customer_aggregation



