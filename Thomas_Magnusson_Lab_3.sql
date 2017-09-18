-- Lab 3 --
-- For Alan's WONDERFUL DATABASE COURSE --

-- 1 --
﻿select ordno, totalusd
from orders;

-- 2 --
select name, city
from agents
where name='Smith';

-- 3 --
select pid, name, priceusd
from products
where qty>200010;

-- 4 --
select name, city
from customers
where city='Duluth';

-- 5 --
select name
from agents
where city!='New York' and city!='Duluth';

-- 6 --
select *
from products
where city!='Duluth' and city!='Dallas' and priceusd>=1;

-- 7 --
select *
from orders
where month='Mar' or month='May';

-- 8 --
select *
from orders
where month='Feb' and totalusd>=500;

-- 9 --
select *
from orders
where cid='c005';
