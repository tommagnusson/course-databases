select ordno, totalusd 
from orders;

select name, city
from agents
where name='Smith';

select pid, name, priceusd
from products
where qty>200010;

select name, city
from customers
where city='Duluth';

select name
from agents
where city!='New York' and city!='Duluth';

select *
from products
where city!='Duluth' and city!='Dallas' and priceusd>=1;

select *
from orders
where month='Mar' or month='May';

select *
from orders
where month='Feb' and totalusd>=500;

select *
from orders
where cid='c005';