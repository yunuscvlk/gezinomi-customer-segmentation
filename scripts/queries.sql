create table public.gezinomi(
  sale_id int,
  sale_date timestamp,
  check_in_date timestamp,
  price float,
  concept_name text,
  sale_city_name text,
  c_in_day text,
  sale_check_in_day_diff int,
  seasons text
);

select * from public.gezinomi limit 5;

select
  count(1) as total_rows,
  sum(case when sale_id is null then 1 else 0 end) as missing_sale_id,
  sum(case when sale_date is null then 1 else 0 end) as missing_sale_date,
  sum(case when check_in_date is null then 1 else 0 end) as missing_check_in_date,
  sum(case when price is null then 1 else 0 end) as missing_price,
  sum(case when concept_name is null then 1 else 0 end) as missing_concept_name,
  sum(case when sale_city_name is null then 1 else 0 end) as missing_sale_city_name,
  sum(case when c_in_day is null then 1 else 0 end) as missing_c_in_day,
  sum(case when sale_check_in_day_diff is null then 1 else 0 end) as missing_sale_check_in_day_diff,
  sum(case when seasons is null then 1 else 0 end) as missing_seasons
from public.gezinomi;

create table public.gezinomi_filled_price as
select
  g.*,
  coalesce(
    price, (
      select
        avg(price)
      from public.gezinomi
      where price is not null
    )
  ) as filled_price
from public.gezinomi g;

select * from public.gezinomi_filled_price limit 5;

create table public.gezinomi_sales as
select
  gfp.*,
  case
    when sale_check_in_day_diff >= 0  and sale_check_in_day_diff < 7  then 'Last Minuters'
    when sale_check_in_day_diff >= 7  and sale_check_in_day_diff < 30 then 'Potential Planners'
    when sale_check_in_day_diff >= 30 and sale_check_in_day_diff < 90 then 'Planners'
    else 'Early Bookers'
  end as eb_score
from
  public.gezinomi_filled_price gfp;

select * from public.gezinomi_sales limit 5;

create table public.gezinomi_sales_scs as
select
  sale_city_name,
  concept_name,
  seasons,
  avg(filled_price) as mean_filled_price,
  count(1) as count
from
  public.gezinomi_sales
group by
  sale_city_name,
  concept_name,
  seasons
order by
  mean_filled_price desc;

select * from public.gezinomi_sales_scs limit 5;

create table public.gezinomi_sales_level_based as
select
  gsscs.*,
  regexp_replace(replace(replace(upper(lower(concat(
    gsscs.sale_city_name, '_',
    gsscs.concept_name, '_',
    gsscs.seasons
  ))), 'Ğ', 'G'), 'Ş', 'S'), '(\x20\+\x20)|(\x20)', '_', 'g') as sales_level_based
from
  public.gezinomi_sales_scs gsscs;

select * from public.gezinomi_sales_level_based limit 5;

select
  min(mean_filled_price) as min_price,
  max(mean_filled_price) as max_price,
  avg(mean_filled_price) as avg_price,
  percentile_cont(0.25) within group (order by mean_filled_price) as q1,
  percentile_cont(0.50) within group (order by mean_filled_price) as median,
  percentile_cont(0.75) within group (order by mean_filled_price) as q3
from
  public.gezinomi_sales_level_based;

create table public.gezinomi_segment as
select
  gslb.*,
  case
    when mean_filled_price >= 25.27 and mean_filled_price <= 39.67 then 'D'
    when mean_filled_price >  39.67 and mean_filled_price <= 54.54 then 'C'
    when mean_filled_price >  54.54 and mean_filled_price <= 65.26 then 'B'
    else 'A'
  end as segment
from
  public.gezinomi_sales_level_based gslb;

select * from public.gezinomi_segment limit 5;