create database bank_churn;
select database();
show tables;
select * from bank_churn;
select * from customerinfo;

/*Distribution of account balances across different regions*/
select 
      g.GeographyLocation as Region,
      round(sum(b.Balance),2) as Total_Balance
from bank_churn b 
join customerinfo c 
on b.CustomerID = c.CustomerID
join geography g 
on c.GeographyID = g.GeographyID
group by g.GeographyLocation
order by Total_Balance desc;

/*Display top 5 customers who joined in Quarter 4 based on highest estimated salary*/
select 
      CustomerID,
      Surname,
      EstimatedSalary
from customerinfo 
where quarter(str_to_date(`Bank DOJ`,'%d/%m/%y')) = 4
order by EstimatedSalary desc
limit 5;

/*average number of products used by customers who have a credit card*/
select avg(NumOfProducts) as Avg_Products_with_creditcard
from bank_churn 
where HasCrCard = 1;

/*churn rate by gender for the most recent year*/ 
Select
      g.GenderCategory,
      round(sum(case when b.Exited = 1 then 1 else 0 end) * 100.0 / count(*),2) 
      as churn_rate
from bank_churn b
join customerinfo c
on b.CustomerID = c.CustomerID
join gender g
on c.GenderID = g.GenderID
where year(str_to_date(`Bank DOJ`,'%d/%m/%y')) = 
(select max(year(str_to_date(`Bank DOJ`,'%d/%m/%y'))) from customerinfo)
group by g.GenderCategory;

/*average credit score of customers who have exited and those who retained*/
select 
      case when Exited = 1 then 'Exited' else 'Retained'
      end as Customer_Status,
      round(avg(CreditScore),2) as Avg_Credit_Score
from bank_churn
group by Exited;

/*average estimated salary grouped by gender*/
select
      g.GenderCategory,
      round(avg(c.Estimatedsalary),2) as Avg_Estimated_salary,
      sum(b.IsActiveMember) as Active_Accounts
from customerinfo c
join gender g
on c.GenderID = g.GenderId
join bank_churn b 
on c.CustomerID = b.CustomerID
group by g.GenderCategory;

/*Customer Segmentation based on credit score*/
select
      case when CreditScore < 600 then 'Low'
           when creditscore between 600 and 700 then 'Medium'
           else 'High'
	  end as Credit_Segment,
      round(sum(case when Exited = 1 then 1 else 0 end) * 100.0 / count(*),2)
      as Exit_Rate
from bank_churn
group by Credit_Segment
order by Exit_Rate desc;

/*geographic region with highest number of active customers and
with a tenure greater than 5 years*/
select
      g.GeographyLocation as Region,
      count(*) as Active_Customers
from bank_churn b 
join customerinfo c 
on b.CustomerID = c.CustomerID
join geography g 
on c.GeographyID = g.GeographyID
where b.IsActiveMember = 1
and b.Tenure > 5
group by g.GeographyLocation
order by Active_Customers desc;

/*Customer churn based on customer having Credit card and customer without credit card*/
select
      case 
          when HasCrCard = 1 then 'Has Credit Card'
		  else 'No Credit Card'
          end as Credit_Card_Status,
	  round(sum(case when Exited = 1 then 1 else 0 end) * 100.0 / count(*),2) 
      as churn_rate
from bank_churn
group by HasCrCard;

/*Count of customers based on Number of Products*/
select
      NumOfProducts,
      count(*) as Customer_Count
from bank_churn
where Exited = 1
group by NumOfProducts
order by Customer_Count desc;

/*Count of customers based on joining year*/
select
      year(str_to_date(`Bank DOJ`, '%d/%m/%y')) as join_year,
      count(*) as customers_joined
from customerinfo
group by join_year
order by join_year;

/*Count of customers based on joining month*/
select
      year(str_to_date(`Bank DOJ`, '%d/%m/%y')) as join_year,
      month(str_to_date(`Bank DOJ`,'%d/%m/%y')) as join_month,
      count(*) as customers_joined 
from customerinfo
group by join_year,join_month
order by join_year,join_month;

/*relationship between the number of products and
 account balance for customers who have exited*/
select
      NumOfProducts,
      round(avg(Balance),2) as Avg_Balance
from bank_churn
where Exited = 1
group by NumOfProducts
order by NumOfProducts;

/*the average balance and standard deviation of account balances*/
select
      CustomerID,
      Balance
from bank_churn
where Exited = 0
and Balance > ( select
                      avg(Balance)+2 * stddev(Balance) 
				from bank_churn
                where Exited = 0)
order by Balance desc;

/*gender-wise average income of males and females in each geography location*/
select
      geo.GeographyLocation,
      g.GenderCategory,
      round(avg(c.EstimatedSalary),2) as Avg_Income,
      rank() over(partition by geo.GeographyLocation 
                  order by avg(c.EstimatedSalary) desc) as Gender_Rank
from customerinfo c 
join gender g 
on c.GenderID = g.GenderID
join geography geo
on c.GeographyID = geo.GeographyID
group by geo.GeographyLocation, g.GenderCategory;

/*average tenure of the people who have exited in each age bracket*/
select
      case
		  when Age >= 18 and Age < 30 then '18-30'
          when Age >= 30 and Age <= 50 then '30-50'
          else '50+'
	  end as age_bracket,
      round(avg(b.Tenure),2) as avg_tenure
from customerinfo c 
join bank_churn b
on c.CustomerID = b.CustomerID
where b.Exited = 1
group by age_bracket;

/*correlation between salary and the account balance of the customers*/
select
      Exited,
      round(avg(EstimatedSalary),2) as avg_salary,
      round(avg(Balance),2) as avg_balance
from customerinfo c 
join bank_churn b 
on c.CustomerID = b.CustomerID
group by Exited;

/*correlation between the salary and the Credit score of customers*/
select
      case
          when CreditScore < 600 then 'Low'
          when CreditScore between 600 and 700 then 'Medium'
          else 'High'
	  end as credit_segment,
      round(avg(EstimatedSalary),2) as avg_salary
from customerinfo c 
join bank_churn b 
on c.CustomerID = b.CustomerID
group by credit_segment;

/*Count of customers in each credit score segment who churned the bank*/
select
      case
          when CreditScore < 600 then 'Low'
          when CreditScore between 600 and 700 then 'Medium'
          else 'High'
	  end as credit_segment,
      count(*) as churned_customers,
      rank() over(order by count(*) desc) as segment_rank
from bank_churn
where Exited = 1
group by credit_segment;

/*Count of customers who have credit card in each age bracket*/
with age_bucket_data as ( 
                         select
                               case
                                   when Age >= 18 and Age <30 then '18-30'
                                   when Age >= 30 and Age <= 50 then '30-50'
                                   else '50+'
							   end as age_bucket,
                               count(*) as credit_card_customers
						from customerinfo c
                        join bank_churn b 
                        on c.CustomerID = b.CustomerID
                        where HasCrCard = 1
                        group by age_bucket)
select * from age_bucket_data
where credit_card_customers <  (select avg(credit_card_customers) 
                                from age_bucket_data);
 
/*Ranking of locations based on customer count and average account balance*/
select
      g.GeographyLocation as Location,
      count(*) as Customers_joined,
      round(avg(b.Balance),2) as avg_balance,
      rank() over(order by count(*) desc) as customer_rank,
      rank() over(order by avg(b.Balance) desc) as balance_rank
from customerinfo c 
join geography g 
on c.GeographyID = g.GeographyID
join bank_churn b 
on c.CustomerID = b.CustomerID
group by g.GeographyLocation;

/*Concatenation of CustomerID and Surname*/
select
      CustomerID,
      Surname,
      concat(CustomerID, '_', Surname) as Customer_Key
from customerinfo;

/*Extracting “ExitCategory” column from ExitCustomers table to Bank_Churn table*/
select
      b.CustomerID,
      b.Exited,
      (select
             ExitCategory
	   from exitcustomer e
       where e.ExitID = b.Exited) as ExitCategory
from bank_churn b;

/*Customer IDs and their last name whose surname ends with “on”*/
select
      c.CustomerID,
      c.Surname,
      case
          when b.IsActiveMember = 1 then 'Active'
          else 'Inactive'
	  end as active_status
from customerinfo c 
join bank_churn b 
on c.CustomerID = b.CustomerID
where c.Surname like '%on';

/*Data Disrupency present in IsActiveMember and Exited columns*/
select
      count(*) as Disrupency
from bank_churn
where Exited = 1 and IsActiveMember = 1;

/*Customer Segmentation by Age*/
Select
    Case
        when Age BETWEEN 18 AND 25 THEN '18-25'
        when Age BETWEEN 26 AND 35 THEN '26-35'
        when Age BETWEEN 36 AND 45 THEN '36-45'
        when Age BETWEEN 46 AND 55 THEN '46-55'
        else '56+'
    end as Age_Group,
   count(*) AS Total_Customers
from customerinfo
group by Age_Group;

/*Customer Segmentation by Geography*/
select
    g.GeographyLocation,
    count(*) as Total_Customers
from customerinfo c 
join geography g 
on g.GeographyID = c.GeographyID
group by g.GeographyLocation
order by Total_Customers desc;

/*Customer Segmentation by Number of Products*/
select
    b.NumOfProducts,
    count(*) as Total_Customers
from customerinfo c
join bank_churn b 
on b.CustomerID = c.CustomerID
group by b.NumOfProducts
order by b.NumOfProducts;

/*Customer Segmentation by Credit Score*/ 
select
case
    when b.CreditScore < 600 THEN 'Poor'
    when b.CreditScore BETWEEN 600 AND 699 THEN 'Fair'
    when b.CreditScore BETWEEN 700 AND 799 THEN 'Good'
    else 'Excellent'
end as Credit_Category,
count(*) AS Customers
from customerinfo c 
join bank_churn b 
on b.CustomerID = c.CustomerID
group by Credit_Category;

/*Customer Segmentation by Balance*/
select
case
    when b.Balance < 50000 THEN 'Low Balance'
    when b.Balance BETWEEN 50000 AND 100000 THEN 'Medium Balance'
    else 'High Balance'
end as Balance_Category,
count(*) as Customers
from customerinfo c 
join bank_churn b 
on b.CustomerID = c.CustomerID
group by Balance_Category;

/*Customer Segmentation by Active Member Status*/
select
case
    when b.IsActiveMember = 1 THEN 'Active'
    else 'Inactive'
end as Member_Status,
count(*) as Customers
from customerinfo c 
join bank_churn b 
on b.CustomerID = c.CustomerID
group by Member_Status;
                    





      



      