/*CREATE TABLE df_orders_py (
    -- Chave primária da tabela, identificador único do pedido
    order_id      INT PRIMARY KEY,

    -- Informações do Pedido
    order_date    DATE NOT NULL,
    ship_mode     VARCHAR(20),
    quantity      INT NOT NULL,
    discount      DECIMAL(7, 2),
    sale_price    DECIMAL(7, 2) NOT NULL,
    profit        DECIMAL(7, 2) NOT NULL,

    -- Informações do Cliente e Localização
    segment       VARCHAR(20),
    country       VARCHAR(20),
    city          VARCHAR(20),
    state         VARCHAR(20),
    postal_code   VARCHAR(20),
    region        VARCHAR(20),

    -- Informações do Produto
    product_id    VARCHAR(50) NOT NULL,
    category      VARCHAR(20),
    sub_category  VARCHAR(20)
);*/


select 
	*
from
	df_orders_py


-- Perguntas que queremos responder em nossa análise exploratória 


-- 1. Encontre o top 10 produtos gerados por receita

select top 10
	product_id,
	sum(sale_price) as sales
from
	df_orders_py
group by product_id
order by sales desc


--2. Encontre os top 5 maiores vendas de produtos por região
with cte as (
select 
	region as 'região',
	product_id as 'produto', 
	ROW_NUMBER() over (partition by region order by sum(sale_price) desc, region) as rn,
	sum(sale_price) as 'total vendas'
from
	df_orders_py
group by region, product_id
)

select
   *
from 
	cte
where rn <= 5

-- encontre month-over-month camparando o crescimento de 2022 e 2023 de vendas, ex: jan 2022 vs. jsn 2023
with cte_two as (
select
	year(order_date) as order_year,
	month(order_date) as order_month,
	sum(sale_price) as sales
from
	df_orders_py
group by year(order_date), month(order_date)
--order by year(order_date), month(order_date)
)

select 
	order_month, 
	sum(case when order_year=2022 then sales else 0 end) as '2022',
	sum(case when order_year=2023 then sales else 0 end) as '2023'
from
	cte_two
group by order_month
order by order_month asc

-- Para cada categoria, qual mês teve mais vendas de 2022 até 2023 
with cte_three as (
select
	category,
	FORMAT(order_date, 'yyyyMM') as order_year_month,
	sum(sale_price) as sales
from df_orders_py
group by category, format(order_date, 'yyyyMM')
--order by category, format(order_date, 'yyyyMM'), sum(sale_price) desc
),

cte_four as (
select
	category,
	sales,
	order_year_month,
	ROW_NUMBER() over(partition by category order by sales desc) as  rn
from
	cte_three
)

select
	*
from
	cte_four
where rn = 1

-- Qual subcategoria teve a maior crescente de receita em 2023 comparado ao ano de 2022

with cte_five as (
select
	sub_category,
	year(order_date) as order_year,
	sum(sale_price) as sales
from
	df_orders_py
group by year(order_date), sub_category
--order by year(order_date)
),

 cte_six as (
select 
	sub_category, 
	sum(case when order_year=2022 then sales else 0 end) as sales_22,
	sum(case when order_year=2023 then sales else 0 end) as sales_23
from
	cte_five
group by sub_category
)

select top 1
	*,
	(sales_23-sales_22)/sales_22*100 as variacao
from	
	cte_six
order by variacao desc