
---Retail Data Analysis (Case Study 1)

USE DB_CASE1   

SELECT * FROM CUSTOMER;
SELECT * FROM PROD_CAT_INFO;
SELECT * FROM TRANSACTIONS;

--------DATA PREPARATION AND UNDERSTANDING 

---Q1 What is the total number of rows in each of the 3 tables in the database? 

(SELECT 'CUSTOMER' AS TABLE_NAME, COUNT(*) AS N0_OF_ROWS  FROM Customer)
UNION ALL                
(SELECT 'PRO_CAT_INFO' AS TABLE_NAME, COUNT(*) AS N0_OF_ROWS  FROM prod_cat_info)
UNION ALL
(SELECT 'TRANSACTIONS' AS TABLE_NAME, COUNT(*) AS N0_OF_ROWS  FROM Transactions )

				
---Q2 What is the total number of transactions that have a return? 

SELECT COUNT(*) AS RETURN_TRAN
FROM Transactions
WHERE CAST(total_amt AS float) < 0


--Q3 As you would have noticed, the dates provided across the datasets are not in a correct
-----format. As first steps, pls convert the date variables into valid date formats before 
-----proceeding ahead.

SELECT *,
CONVERT(DATE, DOB, 105) AS NEW_DOB
FROM Customer

SELECT *,
CONVERT(DATE, TRAN_DATE, 105) AS NEW_TRAN_DATE
FROM Transactions


--Q4 What is the time range of the transaction data available for analysis? Show the output in
-----number of days, months and years simultaneously in different columns.

SELECT
DATEDIFF(YEAR, MIN(TRAN_DATE), MAX(TRAN_DATE)) AS [YEAR],
DATEDIFF(MONTH, MIN(TRAN_DATE), MAX(TRAN_DATE)) AS [MONTH],
DATEDIFF(DAY, MIN(TRAN_DATE), MAX(TRAN_DATE)) AS [DAYS] 
FROM Transactions

--Q5 Which product category does the sub-category “DIY” belong to? 

SELECT
PROD_CAT
FROM prod_cat_info
WHERE prod_subcat = 'DIY'

---DATA ANALYSIS 

--Q1 Which channel is most frequently used for transactions?
 
SELECT STORE_TYPE FROM (
						SELECT TOP 1 STORE_TYPE,
						COUNT(Store_type) AS STORE_TYPE_COUNT
						FROM Transactions
						GROUP BY STORE_TYPE 
						ORDER BY STORE_TYPE_COUNT DESC
						) AS A

--Q2 What is the count of Male and Female customers in the database?
 
      SELECT 'MALE' AS GENDER,
       COUNT(customer_id) as [Cust_count]
        FROM Customer
         WHERE Gender = 'M'

UNION ALL

       SELECT 'FEMALE' AS GENDER,
        COUNT(customer_id) as [Cust_count]
         FROM Customer
          WHERE Gender = 'F'

--Q3 From which city do we have the maximum number of customers and how many?
 
   SELECT TOP 1 CITY_CODE,
    COUNT(customer_Id) AS CUST_COUNT
     FROM Customer
   GROUP BY city_code
   ORDER BY CUST_COUNT DESC

--Q4 How many sub-categories are there under the Books category?

SELECT 
COUNT(PROD_SUBCAT) AS SUB_CAT
FROM prod_cat_info
WHERE prod_cat LIKE 'BOOKS'

--Q5 What is the maximum quantity of products ever ordered? 

SELECT 
ABS(MAX(QTY)) AS MAX_QTY
FROM Transactions

--Q6 What is the net total revenue generated in categories Electronics and Books?

SELECT
SUM(CAST(TOTAL_AMT AS float)) AS NET_REV
FROM Transactions AS T1
INNER JOIN prod_cat_info AS T2
ON T1.prod_cat_code = T2.prod_cat_code
where T2.prod_cat IN ('electronics','books')

--Q7 How many customers have >10 transactions with us, excluding returns? 


Select Count(*) as No_of_Customer from
 (
   Select Cust_id, COUNT(transaction_id) as No_of_Customer
   From Transactions
   Where CAST(total_amt AS float)> 0
   Group by cust_id
   having count(transaction_id)>10) as tbl

--Q8 What is the combined revenue earned from the “Electronics” & “Clothing” categories, 
-----from “Flagship stores”?

SELECT 
SUM(CAST(total_amt AS float)) AS COMB_REV
FROM prod_cat_info AS T1
INNER JOIN Transactions AS T2
ON T1.prod_cat_code = T2.prod_cat_code
WHERE prod_cat IN ('ELECTRONICS','CLOTHING')
		AND
      Store_type IN ('FLAGSHIP STORE')
	

--Q9 What is the total revenue generated from “Male” customers in “Electronics” category? 
-----Output should display total revenue by prod sub-cat. 

SELECT 
prod_subcat,
SUM(CAST(TOTAL_AMT AS float)) AS TOT_REV
FROM prod_cat_info AS X
INNER JOIN (
			SELECT
			prod_subcat_code, TOTAL_AMT
		    FROM Customer AS T1
			INNER JOIN Transactions AS T2
			ON T1.customer_Id = T2.cust_id
			WHERE Gender = 'M'
			) AS Y
ON X.prod_sub_cat_code = Y.PROD_SUBCAT_CODE
WHERE prod_cat = 'ELECTRONICS'
GROUP BY prod_subcat

--Q10 What is percentage of sales and returns by product sub category; display only top 5 sub
------categories in terms of sales? 

SELECT TOP 5 prod_subcat,
ROUND(SUM(CASE WHEN CAST(TOTAL_AMT AS FLOAT) > 0 THEN CAST(TOTAL_AMT AS FLOAT) ELSE 0 END) / SUM(CASE WHEN CAST(TOTAL_AMT AS FLOAT) < 0 THEN ABS(TOTAL_AMT) ELSE CAST(TOTAL_AMT AS FLOAT) END)*100,2) AS [% OF SALES],
ROUND(SUM(CASE WHEN CAST(TOTAL_AMT AS FLOAT) < 0 THEN CAST(TOTAL_AMT AS FLOAT) ELSE 0 END) / SUM(CASE WHEN CAST(TOTAL_AMT AS FLOAT) < 0 THEN ABS(TOTAL_AMT) ELSE CAST(TOTAL_AMT AS FLOAT) END)*100,2) AS [% OF RETURNS]
FROM
prod_cat_info AS P
INNER JOIN
Transactions AS T
ON P.prod_cat_code = T.prod_cat_code
GROUP BY prod_subcat
ORDER BY ROUND(SUM(CASE WHEN CAST(TOTAL_AMT AS FLOAT) < 0 THEN ABS(TOTAL_AMT) ELSE TOTAL_AMT END),2) DESC



--Q11 For all customers aged between 25 to 35 years find what is the net total revenue generated 
------by these consumers in last 30 days of transactions from max transaction date available 
------in the data? 
SELECT
SUM(TOTAL_REV) AS NET_TOTAL_REV
FROM (
		SELECT
		CUSTOMER_ID,
		DATEDIFF(YEAR, DOB, (SELECT MAX(TRAN_DATE) FROM TRANSACTIONS)) as AGE,
		SUM(CAST(TOTAL_AMT AS float)) AS TOTAL_REV
		FROM Customer AS T1
		INNER JOIN Transactions AS T2
		ON T1.customer_Id = T2.cust_id
		WHERE DATEDIFF(YEAR, DOB, (SELECT MAX(TRAN_DATE) FROM TRANSACTIONS)) BETWEEN 25 AND 35
				AND
			tran_date >=  DATEADD(DAY, -30, (SELECT MAX(TRAN_DATE) FROM TRANSACTIONS) )
		GROUP BY  customer_Id, DATEDIFF(YEAR, DOB, GETDATE()) , DOB
		) AS X

--Q12 Which product category has seen the max value of returns in the last 3 months of transactions? 

  SELECT TOP 1
  PROD_CAT_CODE,      
  SUM(CAST(Qty AS int)) AS SUM_RETURN,
  DATEADD(MONTH, -3, max(tran_date)) AS [DATE]
  FROM Transactions   
  WHERE CAST(total_amt AS float) < 0      
  GROUP BY prod_cat_code
  ORDER BY SUM_RETURN 
 

--Q13 Which store-type sells the maximum products; by value of sales amount and by quantity sold? 

SELECT 
STORE_TYPE,
SALES_VALUE,
QTY_SOLD
FROM (	SELECT TOP 1
		Store_type,
		SUM(CAST(total_amt AS float)) AS SALES_VALUE,
		sum(cast(Qty as int)) as QTY_SOLD
		FROM Transactions 
		GROUP BY Store_type
		ORDER BY SUM(CAST(total_amt AS float)) DESC , QTY_SOLD DESC
		) AS X

--Q14 What are the categories for which average revenue is above the overall average.

SELECT
prod_cat_code,
AVG(CAST(TOTAL_AMT AS float)) AS AVG_REV
FROM Transactions
GROUP BY prod_cat_code 
HAVING AVG(CAST(TOTAL_AMT AS float)) > (SELECT	
										AVG(CAST(TOTAL_AMT AS float)) AS OVERALL_AVG
										FROM Transactions)

--Q15 Find the average and total revenue by each subcategory for the categories which are 
------among top 5 categories in terms of quantity sold. 

SELECT 
Y.prod_cat,
Y.prod_subcat,
AVG(CAST(X.total_amt AS float)) AS AVERAGE,
SUM(CAST(X.total_amt AS float)) AS TOT_REV 
FROM Transactions AS X
INNER JOIN prod_cat_info AS Y
ON X.prod_subcat_code = Y.prod_sub_cat_code
where  Y.prod_cat in (SELECT TOP 5
							T2.prod_cat
							FROM Transactions AS T1
							INNER JOIN prod_cat_info AS T2
							ON T1.prod_subcat_code = T2.prod_sub_cat_code
							GROUP BY T2.prod_cat
							ORDER BY SUM(CAST(QTY AS int)) DESC )
GROUP BY  Y.prod_subcat,  Y.prod_cat


