-- Lab 4 Subqueries --
-- Thomas Magnusson --
-- Alan   Labouseur --

-- 1. Get the cities of agents booking an order for a customer whose cid is 'c006'. --
select city
from agents
where aid in (
  select aid
  from orders
  where cid in ('c006')
);


-- 2. Get the distinct ids of products ordered through any agent who takes at least one --
--    order from a customer in Beijing, sorted by pid from highest to lowerest.         --

-- product ids of products ordered through.. --
select distinct pid
from orders
where aid in (
  -- agents who take orders from... --
  select aid
  from orders
  where cid in (
    -- customers from Beijing --
    select cid
    from customers
    where city in ('Beijing')
  )
)
-- from highest to lowest --
order by pid desc;


-- 3. Get the ids and names of cutomers who did not place an order through agent a03. --

-- ids and names of customers who are not in the list of... --
select cid, name
from customers
where cid not in (
  -- customers who placed an order through agent a03 --
  select cid
  from orders
  where aid in ('a03')
);


-- 4. Get the ids of customers who ordered both product p01 and p07. --

-- The ids of customers who are in...
select distinct cid
from orders
where cid in (
  -- the list of customers who ordered p01 --
  select cid
  from orders
  where pid in ('p01')
)
and --and--
cid in (
  -- the list of customers who ordered p07 --
  select cid
  from orders
  where pid in ('p07')
);


-- 5. Get the ids of products not ordered by any customers who placed any    --
--     order through agents a02 or a03, in pid order from highest to lowest. --

-- the products not ordered by customers in...
select pid
from orders
where cid not in (
  -- the list of customers who placed orders through a02 or a03 --
  select distinct cid
  from orders
  where aid in ('a02', 'a03')
)
order by pid desc;


-- 6. Get the name, discount, and city for all customers who place orders through agents in London. --

-- The name, discount and city for all customer in... --
select name, discountPct, city
from customers
where cid in (
  -- the list of customers who place orders through agents in... --
  select cid
  from orders
  where aid in (
    -- the list of agents in London --
    select aid
    from agents
    where city in ('London')
  )
);


-- 7. Get all customers who have the same discount as that of any customers in Duluth or London. --

-- the customers who have the same discount as the discounts in
select *
from customers
where discountPct in (
  -- the list of discounts of customers in Duluth or London --
  select discountPct
  from customers
  where city in ('Duluth', 'London')
);


-- 8. A Check constraint makes sure that only predefined sets of values are able to
--    be entered for a specific value in a column. They are good for enforcing only
--    small sets of known, constant values to be entered in the value for a column.
--    For example, if someone who was storing information about a card game and had
--    to store the suits of cards,  they could constrain the 'Suit'  column to only
--    accept 'Spades', 'Clubs',  'Hearts',  or 'Diamonds'. This makes sure that the
--    data within this column is consistent. No on could enter 'Alan is so Awesome'
--    in such a column, despite the validity of the statement. It maintains correct
--    context for the data, which allows us to derive accurate information from our
--    database, which is the goal.  Check constratins are bad for values that could
--    change.  If someone were to set up a database with values for cities, and the
--    company for which they're setting it up the tables has offices only in London
--    and New York City,  it would be a bad idea to constrain the city column of an 
--    Offices table to only those two values. The company might transition or move, 
--    rendering the check constraint's restriction much more annoying than helpful.



