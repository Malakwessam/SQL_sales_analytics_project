--advanced analytics
--changes over year  
--2013 is the best in sales and quantity
select
year(order_date) as change_over_year,
count(customer_surrogate_key) num_of_customers,
sum(sales) sales,
sum (quantity) quantity
from gold.fact_sales
where order_date is not null
group by year(order_date)
order by year(order_date) 

select     --december is the best while march is the lowest
month(order_date) as change_over_year,
count(customer_surrogate_key) num_of_customers,
sum(sales) sales,
count (quantity) quantity
from gold.fact_sales
where order_date is not null
group by month(order_date)
order by month(order_date) 

--cummulative analytics(running total)
--total sales per month
select
order_dates,
total_sales,
sum(total_sales) over (partition by year(order_dates) order by order_dates) as running_total,
avg_price,
avg(avg_price) over(partition by year(order_dates) order by order_dates) as moving_avg_price
from(
select
datetrunc(month,order_date) as order_dates ,
sum(sales) as total_sales,
avg(price) as avg_price
from gold.fact_sales
where order_date is not null
group  by datetrunc(month,order_date))t

--performance analysis (current - target)
--year performance of products according to avg sales /previous year sales
with performance_analystics as(
select
	p.product_name,
	year(s.order_date) as order_year,
	sum(s.sales) as total_sales
	from gold.fact_sales s
	left join gold.dim_products p
	on s.product_surrogate_key=p.product_surrogate_key
	where year(s.order_date) is not null
	group by year(s.order_date) ,p.product_name )
select
order_year,
product_name,
total_sales,
avg(total_sales) over(partition by product_name) as avg_sales,
total_sales - avg(total_sales) over(partition by product_name) as diff_avg,
case when total_sales - avg(total_sales) over(partition by product_name)<0 then 'below avg'
	when total_sales - avg(total_sales) over(partition by product_name)>0 then 'above avg'
	else 'avg'
end avg_change,
lag(total_sales) over(partition by product_name order by order_year) as prev_year,
total_sales - lag(total_sales) over(partition by product_name order by order_year) as prev_year_diff,
case when total_sales - lag(total_sales) over(partition by product_name order by order_year)<0 then 'decreae'
	when total_sales - lag(total_sales) over(partition by product_name order by order_year)>0 then 'increase'
	else 'stable'
end prev_change
from performance_analystics
order by product_name ,order_year


--part of total
--which category contribute the most overall sales
with category_dist as(
	select
	p.category,
	sum(s.sales) as sales
	from gold.fact_sales s
	left join gold.dim_products p
	on s.product_surrogate_key=p.product_surrogate_key
	group by category)

select 
category,
sales,
sum(sales) over() total_sales,
concat (round( (cast(sales as float) / sum(sales) over() )*100,2), '%') as percentage_of_total
from category_dist


--data segmentations
--segment products into cost ranges(case when then)
select
rangee,
count(product_name) 
from(
select
product_name,
case when cost between 0 and 500 then '0-500'
	when cost between 500 and 1500 then '500-1500'
	else 'above 1500'
end 'rangee'
from gold.dim_products)t
group by rangee

go

--customers into 3 behaviors 
--vip:at least 12 months and more than 5000
--regular:least 12 months and  5000 or less
--new:lifespan less than 12 months
--total num of customers by each group
with customer_beh as(
select
c.customer_surrogate_key,
sum(sales) as total_sales,
datediff( month,min(s.order_date),max(s.order_date)) as life_span
from gold.fact_sales s
left join gold.dim_customers c
on s.customer_surrogate_key=c.customer_surrogate_key
group by c.customer_surrogate_key)

select
category,
count(customer_surrogate_key) 'total_customers'
from(
	select 
	customer_surrogate_key,
	case when life_span>= 12 and total_sales >5000 then 'vip'
		when life_span>= 12 and total_sales <=5000 then 'regular'
		else 'new' 
		end as category
	from customer_beh)t
group by category








go
with customer_cte as(
	select 
	c.customer_surrogate_key,
	max(order_date) as last_order,
	sum(s.sales) as total_sales
	from gold.fact_sales s
	left join gold.dim_customers c
	on s.customer_surrogate_key=c.customer_surrogate_key
	group by c.customer_surrogate_key)

select
total_sales,
last_order,
case when last_order >= dateadd(month,-12,getdate()) and total_sales > 5000 then 'vip'
     when last_order >= dateadd(month,-12,getdate()) and total_sales <= 5000 then 'regular'
else 'new'
end
from customer_cte



--how many orders by each customer and the average order number
select 
first_name,
customer_surrogate_key,
number_of_orders,
total_revenue,
avg(number_of_orders) over()
from (
select
c.first_name,
c.customer_surrogate_key,
count(s.order_number) as number_of_orders,
sum(sales) 'total_revenue'
from gold.fact_sales s
left join gold.dim_customers c
on s.customer_surrogate_key=c.customer_surrogate_key
group by c.customer_surrogate_key ,c.first_name
)t
order by total_revenue desc



