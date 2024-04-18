-- CREATE TABLE TO GET PRICE AFTER PROMO TYPE APPLIED AND TI GET QUANTITY
create table new_fact_events_table as
select *,
	quantity_sold_before_promo*base_price as total_sales_before_promo,
    total_quantity_sold_after_promo*new_base_price as total_sales_after_promo
from( 
select *,
	case 
		when promo_type='50% OFF' then round(base_price*0.5,1)
		when promo_type='25% OFF' then round(base_price*0.75,1)
		when promo_type='500 Cashback' then round(base_price-500,1)
		when promo_type='BOGOf' then round(base_price*0.5,1)
		when promo_type='33% OFF' then round(base_price*(1-0.33),1)
		else round(base_price,1)
	end as new_base_price,
    case
		when promo_type='BOGOF' then quantity_sold_after_promo*2
		else quantity_sold_after_promo
		end as total_quantity_sold_after_promo
from fact_events) x;

select * from new_fact_events_table;

                                           -- BUSINESS INSIGHT
                                           
							-- PRODUCT ON WHICH BOGOF PROMO CODE IS APPLIED
select e.product_code,p.product_name,e.base_price,
	round(sum(quantity_sold_before_promo)/1000,2) as qty_before_promo,
    round(sum(total_quantity_sold_after_promo)/1000,2) as qty_after_promo,
	round(sum(total_sales_before_promo)/1000000,2) as sales_before_promo,
    round(sum(total_sales_after_promo)/1000000,2) as sales_after_promo
from new_fact_events_table e
join dim_products p
on e.product_code=p.product_code
where promo_type='BOGOF'
and base_price>=500
group by p.product_name,e.product_code,e.base_price;


                                        -- NO OF STORE IN EACH CITY
select s.city,count(distinct s.store_id) as No_of_stores,
	round(sum(e.quantity_sold_before_promo)/1000,2) as qty_sold_before_promo,
    round(sum(e.total_quantity_sold_after_promo)/1000,2) as qty_sold_after_promo,
	round(sum(e.total_sales_before_promo)/1000000,2) as sales_before_promo,
    round(sum(e.total_sales_after_promo)/1000000,2) as sales_after_promo
from dim_stores s
join new_fact_events_table e
	on e.store_id=s.store_id
group by s.city
order by No_of_stores desc;

							 -- TOTAL REVENUE BEFORE AND AFTER PROMOTION 
select
	campaign_id,
    round(sum(quantity_sold_before_promo)/1000,2) as qty_sold_before_promo,
    round(sum(total_quantity_sold_after_promo)/1000,2) as qty_sold_after_promo,
	round(sum(total_sales_before_promo)/1000000,2) as Total_revenue_before_promo,
	round(sum(total_sales_after_promo)/1000000,2) as Total_revenue_after_promo
from new_fact_events_table 
group by campaign_id;
    
    
                           -- ISU% (INCREMENTAL SOLD QUANTITY) FOR EACH CATEGORY
select p.category,group_concat(distinct x.promo_type) as promo_type,
	round(sum(qty_sold_before)/1000,2) as qty_sold_before,
    round(sum(qty_sold_after)/1000,2) as qty_sold_after,
    round(avg(x.ISU_pct),2)  as avg_ISU_pct,
	round(sum(revenue_before)/1000000,2) as revenue_before,
    round(sum(revenue_after)/1000000,2) as revenue_after,
    round(avg(x.IR_pct),2)  as avg_IR_pct
from (
		select product_code, promo_type,
			quantity_sold_before_promo as qty_sold_before,
			total_quantity_sold_after_promo as qty_sold_after,
			round((total_quantity_sold_after_promo-quantity_sold_before_promo)*100/quantity_sold_before_promo,2) as ISU_pct,
            total_sales_before_promo as revenue_before,
            total_sales_after_promo as revenue_after,
			round((total_sales_after_promo-total_sales_before_promo)*100/(total_sales_before_promo),2) as IR_pct
		from new_fact_events_table
        where campaign_id='CAMP_DIW_01') x
join dim_products p
	on p.product_code=x.product_code
group by p.category
order by avg_ISU_pct desc;
   


                              -- TOP 5 PRODUCT BY INCREMENTAL REVENUE
with t as (
select x.*,
	rank() over(order by IR_pct desc) as rank_order
from(
	select p.product_name,
		round(sum(quantity_sold_before_promo)/1000,2) as qty_before_promo,
        round(sum(total_quantity_sold_after_promo)/1000,2) as qty_after_promo,
        round(sum(total_quantity_sold_after_promo-quantity_sold_before_promo)*100/sum(quantity_sold_before_promo),2) as ISU_pct,
        round(sum(total_sales_before_promo)/1000000,2) as sales_before_promo,
        round(sum(total_sales_after_promo)/1000000,2) as sales_after_promo,
		round(sum(total_sales_after_promo-total_sales_before_promo)*100/sum(total_sales_before_promo),2) as IR_pct
	from new_fact_events_table ne
	join dim_products p
		on ne.product_code=p.product_code
	where campaign_id='CAMP_DIW_01'
    group by p.product_name) x)
select * 
from t
where rank_order<=5;

select e.*,p.product_name,p.category
from new_fact_events_table e
join dim_products p
	on e.product_code=p.product_code
    where product_name='Atliq_Sonamasuri_Rice (10KG)' 
    and campaign_id='CAMP_DIW_01';
