-- Lab 6 Interesting and Painful Queries
-- Tom Magnusson
-- Alan Labouseur

-- 1. Display the name and city of customers who live in any city that makes the most different kinds of products
-- There are two cities that make the most different products. Return the name and city of customer from either one of those).

-- name and city of customers who live in...
select name, city
from Customers
where city in (
  -- Most varied-product cities
  select city
  from Products
  group by city
  having count(*) in (
    -- product count of most varied cities
    select count(*)
    from Products
    group by city
    order by count(*) desc
    limit 1
  )
);


-- 2. Display the names of products whose priceUSD is at or above the average priceUSD, in reverse-alpha order.

select name
from Products
where priceUSD >= (
  -- avg product priceUSD
  select avg(priceUSD)
  from Products
)
order by name desc;


-- 3. Display the (customer name, pid ordered, and the total) for (all orders)[every order?], sorted by total from low to high

select c.name, o.pid, o.totalUSD
from Orders o
inner join Customers c
on o.cid = c.cid
order by o.totalUSD asc;


-- 4. Display all customer names (in reverse alpha order) and their total ordered, and nothing more. Use coalesce to avoid showing NULLs.
-- You're so tricky, stupid ACME

-- if the customer hasn't made any orders, the total order value is 0.
select c.name, coalesce(sum(o.totalUSD), 0)
from Orders o
right outer join Customers c
on o.cid = c.cid
group by c.cid -- ugh, that's devious
order by c.name desc;


-- 5. Display the names of all customers who bought products from (any) agents based in Newark [along with the names of the products [they](the customers, only customers order) ordered](only the products they ordered from
-- agents based in Newark, not any products they've ordered),
-- and the names of the agents who sold [it](the products that the customers bought from agents in Newark) to [them](the correspdoning customers that bought from agents based in Newark).

select c.name as "Customer Name", p.name as "Product Name", a.name as "Agent Name"
from Orders o
inner join Agents a
on o.aid = a.aid
inner join Products p
on o.pid = p.pid
inner join Customers c
on o.cid = c.cid
where a.city = 'Newark';

-- 6. Write a query to check the accuracy of the totalUSD column in the Orders table.

select o.quantity, p.priceUSD, o.totalUSD, (o.quantity * p.priceUSD) as "Checked Total USD", ((o.quantity * p.priceUSD) = o.totalUSD) as "Stored total = checked total"
from Orders o
inner join Products p
on o.pid = p.pid
where ((o.quantity * p.priceUSD) != o.totalUSD);

-- 7. What's the different between a LEFT OUTER JOIN and a RIGHT OUTER JOIN? Give example queries in SQL to demonstrate.

-- Joins combine two tables by some common value(s). Outer joins match two tables by some common values as well as include the records that do not match.
-- The records from the table that contain values will be filled in, but the other table's corresponding records will be null (signifying nothing was able to be joined). Left and right outer joins
-- include the null-filled records from the first table defined in the query or the second table defined, respectively.

-- Left outer joins will include all the non-matching records from the first table in a query (the SQL statement you write), and represent the non matching rows' values from the second table as NULL.
-- Right outer joins will include all the non-matching records form the second table in a query, and represent the non matching rows' values form the first table as NULL.
-- The only difference is the order in which you form your SQL query. Conceptually, they perform the same action.

-- 4. Display all customer names (in reverse alpha order) and their total ordered, and nothing more. Use coalesce to avoid showing NULLs.

-- if the customer hasn't made any orders, the total order value is 0. The corresponding orders values will be null, which is why why coalesce the value into 0 (which we know is what null represents in this context).
select c.name, coalesce(sum(o.totalUSD), 0)
from Orders o -- left table, make it so that the total usd is null for customers who haven't ordered anything
right outer join Customers c -- right table, include the row values from all the rows in this table (all customers who haven't placed an order), even though the totalUSD for them is NULL
on o.cid = c.cid
group by name
order by c.name desc;

-- is the same as

select c.name, coalesce(sum(o.totalUSD), 0)
from Customers c -- left table, include the row values from all rows in this table, etc.
left outer join Orders o -- right table, make it so that the total usd is null for customers who haven't ordered anything.
on o.cid = c.cid
group by name
order by c.name desc;

-- the only difference between the two queries is that Customers c and Orders o are swapped around, corresponding to the left and right outer join semantics.



