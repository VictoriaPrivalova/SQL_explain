
--ÚKOL č. 1
--Napište SQL dotaz, který vypisuje veškeré informace o filmech
--s atributem "Behind the Scenes".

select *
from film
where 'Behind the Scenes' in  (select unnest(special_features))


--ÚKOL č. 2
--Napište další 2 způsoby vyhledávání filmů s atributem "Behind the Scenes",
--pomocí jiných funkcí nebo operátorů jazyka SQL pro vyhledávání hodnot v poli.

select *
from film
where special_features@>array['Behind the Scenes']


select *
from film
where 'Behind the Scenes'= any (special_features)

--ÚKOL č. 3
--Pro každého zákazníka spočítejte, kolik filmů si pronajal
--s atributem "Behind the Scenes".

--POVINNÁ PODMÍNKA PRO VYKONÁNÍ ÚKOLU: Použijte dotaz z úkolu č. 1,
--umístěný do CTE (společného tabulkového výrazu). CTE je nutné použít k řešení úkolu.

explain analyze--760
with cte as(
select *
from film f
where 'Behind the Scenes' in  (select unnest(special_features)))
select c.customer_id , count(rental_id) 
from rental r
join customer c on r.customer_id=c.customer_id
join inventory i on i.inventory_id=r.inventory_id
join cte on cte.film_id=i.film_id
group by 1
order by c.customer_id asc


--ÚKOL č. 4
--Pro každého zákazníka spočítejte, kolik filmů si pronajal
--s atributem "Behind the Scenes".

--POVINNÁ PODMÍNKA PRO VYKONÁNÍ ÚKOLU: Použijte dotaz z úkolu č. 1,
--umístěný do poddotazu, který je nutné použít k řešení úkolu.

explain analyze--599
select c.customer_id , count(rental_id)
from (select *
from film f
where 'Behind the Scenes' in  (select unnest(special_features))
) ss
join inventory i on i.film_id=ss.film_id
join rental r on i.inventory_id=r.inventory_id
join customer c on r.customer_id=c.customer_id
group by 1
order by c.customer_id asc




--ÚKOL č. 5
--Vytvořte materializované zobrazení s dotazem z předchozího úkolu
--a napište dotaz pro aktualizaci materializovaného zobrazení.

create materialized view taskN5 as
select c.customer_id , count(rental_id)
from (select *
from film f
where 'Behind the Scenes' in  (select unnest(special_features))
) ss
join inventory i on i.film_id=ss.film_id
join rental r on i.inventory_id=r.inventory_id
join customer c on r.customer_id=c.customer_id
group by 1
order by c.customer_id asc
with no data

select *
from taskn5 

refresh materialized view taskN5



--ÚKOL č. 6
--Proveďte analýzu rychlosti vykonání dotazů z předchozích úkolů
--pomocí explain analyze a odpovězte na otázky:

--1. Kterým operátorem nebo funkcí jazyka SQL používanou při vykonávání domácího úkolu
-- je vyhledávání hodnoty v poli rychlejší?
--2. Která varianta výpočtu funguje rychleji:
-- s použitím CTE nebo s použitím poddotazu?


-- №1

explain analyze---113.75/0.023
select *
from film
where 'Behind the Scenes' in  (select unnest(special_features))


-- №2
explain analyze--67.50/0.017
select *
from film
where special_features@>array['Behind the Scenes']

explain analyze--77.50/0.014 - быстрее
select *
from film
where 'Behind the Scenes'= any (special_features)

-- №3


explain analyze--760/11.132
with cte as(
select *
from film f
where 'Behind the Scenes' in  (select unnest(special_features)))
select c.customer_id , count(rental_id) 
from rental r
join customer c on r.customer_id=c.customer_id
join inventory i on i.inventory_id=r.inventory_id
join cte on cte.film_id=i.film_id
group by 1
order by c.customer_id asc

explain analyze--599/9.978-----лучше
select c.customer_id , count(rental_id)
from (select *
from film f
where 'Behind the Scenes' in  (select unnest(special_features))
) ss
join inventory i on i.film_id=ss.film_id
join rental r on i.inventory_id=r.inventory_id
join customer c on r.customer_id=c.customer_id
group by 1
order by c.customer_id asc







--======== DODATEČNÁ ČÁST ==============

--ÚKOL č. 1
--Proveďte toto zadání ve formě odpovědi na webové stránce Netology.

explain analyze---1090.40/58.131
select distinct cu.first_name  || ' ' || cu.last_name as name, 
	count(ren.iid) over (partition by cu.customer_id)
from customer cu
full outer join 
	(select *, r.inventory_id as iid, inv.sf_string as sfs, r.customer_id as cid
	from rental r 
	full outer join 
		(select *, unnest(f.special_features) as sf_string
		from inventory i
		full outer join film f on f.film_id = i.film_id) as inv 
		on r.inventory_id = inv.inventory_id) as ren 
	on ren.cid = cu.customer_id 
where ren.sfs like '%Behind the Scenes%'
order by count desc


---->  Subquery Scan on inv  (cost=77.50..996.42 rows=5 width=4) (actual time=3.243..14.206 rows=2494 loops=1) 

select c.customer_id , count(rental_id)
from (select *
from film f
where 'Behind the Scenes' in  (select unnest(special_features))
) ss
join inventory i on i.film_id=ss.film_id
join rental r on i.inventory_id=r.inventory_id
join customer c on r.customer_id=c.customer_id
group by 1
order by c.customer_id asc


--ÚKOL č. 2
--Pomocí okenní funkce vypište pro každého zaměstnance
--informace o jeho první prodeji.

select rn.staff_id,i.film_id,title,rn.amount,payment_date,c.first_name,c.last_name,row_number
from (select*,
row_number()over(partition by staff_id order by payment_date)
from payment) rn
join rental r on rn.payment_id=r.rental_id
join inventory i on r.inventory_id=i.inventory_id
join film f on i.film_id=f.film_id
join customer c on r.customer_id=c.customer_id
where row_number =1


--ÚKOL č. 3
--Pro každý obchod určete a vypište jedním SQL dotazem následující analytické ukazatele:
-- 1. den, kdy bylo pronajato nejvíce filmů (den ve formátu rok-měsíc-den)
-- 2. počet filmů, které byly v tomto dni pronajaty
-- 3. den, kdy byly filmy prodány za nejnižší částku (den ve formátu rok-měsíc-den)
-- 4. celkovou částku prodeje v tomto dni.


explain analyse--2007.24

with cte1 as(
select st.store_id,rental_date::date as "день, в который арендовали больше всего фильмов",count(rental_id) as "Количество фильмов взятых в аренду"
from (select *,
count(rental_id)over( order by rental_date)
from rental) ri
join staff s on ri.staff_id=s.staff_id
join store st on s.store_id=st.store_id
group by 1,2
order by count(rental_id) desc
limit 2),
cte2 as(
select st.store_id,payment_date::date as "день, в который продали фильмов на наименьшую сумму", sum(amount)  as "суммa продажи"
from (select *,
sum(amount)over( order by payment_date)
from payment) p
join staff s on p.staff_id=s.staff_id
join store st on s.store_id=st.store_id
group by 1,2
order by sum(amount) asc
limit 2)
select *
from cte1 x
join cte2 y on x.store_id=y.store_id