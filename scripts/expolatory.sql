-- exploring all objects in database
select * from INFORMATION_SCHEMA.tables

-- exploring all columns in db
select * from INFORMATION_SCHEMA.columns

--dimentions(min/max/distict)
select distinct country from gold.dim_customers

select distinct  category,sub_category,product_name from gold.dim_products
order by 1,2,3


select min(order_date) as first_order_date,
max(order_date) as last_order_date,
DATEDIFF(year,min(order_date),max(order_date)) as date_range
from gold.fact_sales


select min(birthdate) as oldest_birthdate ,
datediff(year,min(birthdate),getdate()) as oldest_date,
max(birthdate) as youngest_birthdate,
datediff(year,max(birthdate),getdate()) as youngest_age
from gold.dim_customers


--measures( avg sum)
--FACT
--total number of sales
select sum(sales) from gold.fact_sales
--how many items are sold (quantity)
select sum(quantity) from gold.fact_sales
--average price
select avg(price) from gold.fact_sales
--how many orders
select count(distinct order_number) from gold.fact_sales  --to remove duplicets since one order can have many items
select * from gold.fact_sales
order by order_number
--PRODUCTS
--total number of products
select count(product_name) from gold.dim_products
--CUSTOMERS
--total customers
select count(customer_surrogate_key) from gold.dim_customers
select count(customer_id) from gold.dim_customers


--reporting all findings
select 'total sales' as 'measure name', sum(sales) as 'measure value' from gold.fact_sales
union all
select 'total sold items ',sum(quantity) from gold.fact_sales
union all
select  'average price', avg(price) from gold.fact_sales
union all
select 'total num of orders' ,count(distinct order_number) from gold.fact_sales 
union all
select 'total num of products',count(product_name) from gold.dim_products
union all
select 'total num of customers', count(customer_surrogate_key) from gold.dim_customers


--agg measure by dimention
-- ex: total customers by country
select 
country,
count(customer_id) as'number of customers'
from gold.dim_customers
group by country
order by 'number of customers' desc
-- ex: total customers by gender
select 
gender,
count(customer_id) 'number of customers'
from gold.dim_customers
group by gender
order by 'number of customers' desc
-- ex: total customers by material_status
select 
material_status,
count(customer_id) 'number of customers'
from gold.dim_customers
group by material_status
--ex:total products by category
select 
category,
count(product_id) 'number of products'
from gold.dim_products
group by category
order by 'number of products' desc
--average cost per category
select
category,
avg(cost) 'average cost'
from gold.dim_products
group by category
order by 'average cost' desc
--total revenue for each category
select
p.category,
sum(s.sales) 'total sales'
from  gold.fact_sales s
left join gold.dim_products p
on s.product_surrogate_key=p.product_surrogate_key
group by p.category
order by 'total sales' desc
--total revenue by each customer (top 3)
select
c.customer_surrogate_key
first_name,
sum(sales) 'total_revenue'
from gold.fact_sales f
left join gold.dim_customers c
on f.customer_surrogate_key=c.customer_surrogate_key
group by c.customer_surrogate_key ,first_name
order by 'total_revenue' desc
--distribution of items sold across contries
select
c.country,
sum(f.quantity) 'total sold items'
from gold.fact_sales f
left join gold.dim_customers c
on f.customer_surrogate_key=c.customer_surrogate_key
group by c.country
order by 'total sold items' desc


--ranking (order by +top) / row number
--which 5 products generate the highest revenue
select top 5
p.product_name,
sum(s.sales) total_revenue
from gold.fact_sales s
left join gold.dim_products p
on s.product_surrogate_key=p.product_surrogate_key
group by p.product_name
order by total_revenue desc

select *
from(
	select
	p.product_name,
	sum(s.sales) total_revenue,
	row_number() over(order by sum(s.sales) desc) as rank_products
	from gold.fact_sales s
	left join gold.dim_products p
	on s.product_surrogate_key=p.product_surrogate_key
	group by p.product_name)t
where rank_products<6
