select * from dim_campaigns;
select * from dim_products;
select * from dim_stores;
select * from fact_events;


--  STORE PERFORMANCE ANALYSIS
-- TOP 10 STORES BY IR%
select e.store_id,s.city,
	round((total_sales_after_promo-total_sales_before_promo)*100/(total_sales_before_promo),2) as IR_pct
from new_fact_events_table e
join dim_stores s
	on e.store_id=s.store_id
order by IR_pct desc
limit 10;

-- TOP 10 STORES BY ISU((INCREMENTAL SOLD UNIT)
select e.store_id,s.city,
	total_quantity_sold_after_promo-quantity_sold_before_promo as ISU
from new_fact_events_table e
join dim_stores s
	on e.store_id=s.store_id
order by ISU desc
limit 10;

-- PERFORMANCE 1O STORES BY CITY
with Incremental_sold_qty as (
	select x.*,
		  rank() over(partition by city order by ISU desc) as rank_order 
	from(
		select e.store_id,s.city,
			total_quantity_sold_after_promo-quantity_sold_before_promo as ISU
		from new_fact_events_table e
		join dim_stores s
			on e.store_id=s.store_id) x)
			
select * from Incremental_sold_qty
where rank_order<=10;

-- PROMOTION TYPE ANALYSIS
-- TOP 2 PROMO TYPE RESULT IN INCREMENTAL REVENUE
select distinct promo_type,sum(IR) as Total
from(
	select e.promo_type,
		round((total_sales_after_promo-total_sales_before_promo)/1000000,2) as IR
	from new_fact_events_table e
	join dim_stores s
		on e.store_id=s.store_id
	order by IR desc) x
group by promo_type
order by Total desc
limit 2;

-- TOP 2 PROMO TYPE RESULT IN INCREMENTAL SOLD UNIT
select distinct promo_type,sum(ISU) as Total
from(
	select e.promo_type,
		total_quantity_sold_after_promo-quantity_sold_before_promo as ISU
	from new_fact_events_table e
	join dim_stores s
		on e.store_id=s.store_id) x	
group by promo_type
order by Total desc
limit 2;
 
 
 -- BOGOF VS CASHBACK
select promo_type ,
	sum(total_quantity_sold_after_promo-quantity_sold_before_promo) as Sold_qty_diff,
    round(sum(total_sales_after_promo-total_sales_before_promo)/1000000,2) as Revenue_diff_million,
    round(sum(total_sales_after_promo-total_sales_before_promo)*100/sum(total_sales_before_promo),2) as Revenue_diff_pct
from new_fact_events_table
where promo_type in('BOGOF','500 Cashback')
group by promo_type;
 
 -- WHICH PROMO TYPE MAINTAIN HEALTHY BALANCE BETWEEN SOLD QTY & MARGINS
 select promo_type,
	sum(total_quantity_sold_after_promo-quantity_sold_before_promo) as Sold_qty_diff,
    round(sum(total_sales_after_promo-total_sales_before_promo)/1000000,2) as Revenue_diff_million,
    round(sum(total_sales_after_promo-total_sales_before_promo)*100/sum(total_sales_before_promo),2) as Revenue_diff_pct
 from new_fact_events_table
 group by promo_type
 having Revenue_diff_pct>0
 order by Revenue_diff_pct;
 
-- PRODUCT AND CATEGORY ANALYSIS
-- TOP CATEGORY BY SALES DURING PROMO
with t1 as(
			select p.category,
					sum(total_sales_after_promo-total_sales_before_promo) as IR
			from new_fact_events_table e
			join dim_stores s
				on e.store_id=s.store_id
			join dim_products p
				on p.product_code=e.product_code
			group by p.category)
select category 
from t1
order by t1.IR desc
limit 1;

-- TOP PRODUCTS BY SALES DURING PROMO

select p.product_name,
		sum(total_quantity_sold_after_promo-quantity_sold_before_promo) as Sold_qty_diff,
        round(sum(total_sales_after_promo-total_sales_before_promo)/1000000,2) as Revenue_diff_million
from new_fact_events_table e
join dim_products p 
	on e.product_code=p.product_code
group by p.product_name
order by Revenue_diff_million desc
limit 5;


select p.product_name,group_concat(distinct promo_type,',') as promo_type,
		sum(total_quantity_sold_after_promo-quantity_sold_before_promo) as Sold_qty_diff,
        round(sum(total_sales_after_promo-total_sales_before_promo)/1000000,2) as Revenue_diff_million
from new_fact_events_table e
join dim_products p 
	on e.product_code=p.product_code
group by p.product_name
order by Revenue_diff_million desc
limit 5;
    
    
 -- WORST PRODUCT DURING PROMOTION   
select p.product_name,group_concat(distinct promo_type,',') as promo_type,
		sum(total_quantity_sold_after_promo-quantity_sold_before_promo) as Sold_qty_diff,
        round(sum(total_sales_after_promo-total_sales_before_promo)/1000000,2) as Revenue_diff_million
from new_fact_events_table e
join dim_products p 
	on e.product_code=p.product_code
group by p.product_name
having Revenue_diff_million< 0
order by Revenue_diff_million ;

select promo_type,count(*)
from fact_events
group by promo_type;

