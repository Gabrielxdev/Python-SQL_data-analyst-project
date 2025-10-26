##  Projeto de Análise de Vendas

Este projeto realiza uma análise exploratória de dados (EDA) sobre um conjunto de dados de vendas. O objetivo é extrair insights sobre desempenho de produtos, tendências regionais, crescimento temporal e performance de categorias.

### Processo de ETL e Análise

1.  **Fonte de Dados:** O conjunto de dados brutos foi obtido da plataforma Kaggle.
2.  **Extração e Transformação (ETL):** Os dados foram processados usando **Python**, com as bibliotecas **Pandas** e **NumPy** para limpeza, tratamento de valores ausentes e transformação de tipos de dados.
3.  **Carregamento (Load):** O dataframe tratado (`df_orders_py`) foi carregado em um banco de dados **SQL Server** para análise.
4.  **Análise:** As consultas foram executadas diretamente no SQL Server usando T-SQL, aproveitando Common Table Expressions (CTEs), funções de janela (`ROW_NUMBER`) e agregações para responder às perguntas de negócio.

-----

### Análises e Descobertas

Abaixo estão as principais perguntas de negócio respondidas durante a análise:

#### 1\. Top 10 Produtos por Receita

  * **Objetivo:** Identificar os 10 produtos que mais geraram receita.
  * **Resultado:** O produto `TEC-CO-10004722` foi o líder absoluto em receita, gerando **R$ 59.514,00**, seguido pelo `OFF-BI-10003527` com **R$ 26.525,30**.

<!-- end list -->

```sql
select top 10
	product_id,
	sum(sale_price) as sales
from
	df_orders_py
group by product_id
order by sales desc
```

#### 2\. Top 5 Produtos Mais Vendidos por Região

  * **Objetivo:** Entender o desempenho dos produtos em cada região para identificar preferências locais.
  * **Resultado:** A análise destacou os 5 principais produtos em cada uma das quatro regiões (Central, East, South, West). Notavelmente, o produto `TEC-CO-10004722` é um best-seller em múltiplas regiões (East, Central e West), indicando uma forte presença nacional.

<!-- end list -->

```sql
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
```

#### 3\. Comparativo de Vendas Mensais (2022 vs. 2023)

  * **Objetivo:** Comparar o crescimento das vendas mês a mês (MoM) entre 2022 e 2023.
  * **Resultado:** Foi criada uma tabela pivô que compara as vendas de cada mês lado a lado. Isso permite uma fácil identificação de sazonalidade e crescimento ano a ano. Por exemplo, Março (mês 3) viu um crescimento de **R$ 80.106,00** em 2022 para **R$ 82.512,30** em 2023.

<!-- end list -->

```sql
with cte_two as (
select
	year(order_date) as order_year,
	month(order_date) as order_month,
	sum(sale_price) as sales
from
	df_orders_py
group by year(order_date), month(order_date)
)
select 
	order_month, 
	sum(case when order_year=2022 then sales else 0 end) as '2022',
	sum(case when order_year=2023 then sales else 0 end) as '2023'
from
	cte_two
group by order_month
order by order_month asc
```

#### 4\. Mês de Maior Venda por Categoria (2022-2023)

  * **Objetivo:** Identificar o mês/ano de pico de vendas para cada categoria de produto.
  * **Resultado:**
      * **Furniture:** Outubro de 2022 (R$ 42.888,90)
      * **Office Supplies:** Fevereiro de 2023 (R$ 44.118,50)
      * **Technology:** Outubro de 2023 (R$ 53.000,10)

<!-- end list -->

```sql
with cte_three as (
select
	category,
	FORMAT(order_date, 'yyyyMM') as order_year_month,
	sum(sale_price) as sales
from df_orders_py
group by category, format(order_date, 'yyyyMM')
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
```

#### 5\. Subcategoria com Maior Crescimento (2022 vs. 2023)

  * **Objetivo:** Identificar qual subcategoria teve o maior crescimento percentual de receita, comparando 2023 com 2022.
  * **Resultado:** A consulta foi estruturada para pivotar as vendas de 2022 e 2023 por subcategoria e calcular a variação percentual `(Vendas 2023 - Vendas 2022) / Vendas 2022`. A subcategoria com o maior percentual positivo é o principal vetor de crescimento da empresa no período.

<!-- end list -->

```sql
with cte_five as (
select
	sub_category,
	year(order_date) as order_year,
	sum(sale_price) as sales
from
	df_orders_py
group by year(order_date), sub_category
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
```
