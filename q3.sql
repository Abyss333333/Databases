-- Q3. North and South Connections

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel, public;
DROP TABLE IF EXISTS q3 CASCADE;

CREATE TABLE q3 (
    outbound VARCHAR(30),
    inbound VARCHAR(30),
    direct INT,
    one_con INT,
    two_con INT,
    earliest timestamp
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS city_in_Canada CASCADE;
DROP VIEW IF EXISTS city_in_USA CASCADE;
DROP VIEW IF EXISTS cad_to_us CASCADE;
DROP VIEW IF EXISTS us_to_cad CASCADE;
DROP VIEW IF EXISTS x0 CASCADE;

DROP VIEW IF EXISTS April30_21 CASCADE;
DROP VIEW IF EXISTS inbound CASCADE;
DROP VIEW IF EXISTS outbound CASCADE;
DROP VIEW IF EXISTS x1 CASCADE;
DROP VIEW IF EXISTS direct CASCADE;
DROP VIEW IF EXISTS one_connection CASCADE;
DROP VIEW IF EXISTS two_connections CASCADE;

DROP VIEW IF EXISTS numDirect CASCADE;
DROP VIEW IF EXISTS numOneConnection CASCADE;
DROP VIEW IF EXISTS numTwoConnections CASCADE;
DROP VIEW IF EXISTS connections CASCADE;
DROP VIEW IF EXISTS earliest_connections CASCADE;
DROP VIEW IF EXISTS all_routes CASCADE;
DROP VIEW IF EXISTS earliest_all CASCADE;

DROP VIEW IF EXISTS direct_one CASCADE;
DROP VIEW IF EXISTS direct_one_two CASCADE;
DROP VIEW IF EXISTS best_routes CASCADE;




-- Define views for your intermediate steps here:

-- Cities

create view city_in_USA as (
select city as city_us
from airport
where country = 'USA'
);

create view city_in_Canada as (
select city as city_can
from airport
where country = 'Canada'
);

create view cad_to_us as (
select city_can, city_us 
from city_in_Canada, city_in_USA
);

create view us_to_cad as (
select city_us, city_can
from city_in_Canada, city_in_USA
);

create view x0 (city_outbound, city_inbound) as  (
(select * from cad_to_us) union (select * from us_to_cad)
);

-- all flights on April 30 2021
create view April30_21 as (
select inbound, s_arv as arv_time, outbound, s_dep as dep_time
from flight
where extract(year from s_dep) = 2021 and extract ( year from s_arv) = 2021 
and extract(month from s_dep) = 04 and extract(month from s_arv) = 04
and extract(day from s_dep) = 30 and extract(day from s_arv) = 30
);

create view inbound as (
select inbound, outbound, dep_time, arv_time, city as city_inbound
from April30_21 join airport 
on code = inbound
);

create view outbound as (
select inbound, outbound, dep_time, arv_time, city as city_outbound
from April30_21 join airport
on code = outbound
);

create view x1 as (
select * 
from inbound natural join outbound
);


--- get direct, one connections and two connections


create view direct as (
select arv_time, city_outbound,  city_inbound
from x1
where (city_outbound in (select * from city_in_USA) and city_inbound in (select * from city_in_Canada))
or (city_outbound in (select * from city_in_Canada) and city_inbound in (select * from city_in_USA))
);

create view one_connection as (
select  p2.arv_time as arv_time, p1.city_outbound as city_outbound,  p2.city_inbound as city_inbound 
from x1 p1, x1 p2
where ((p1.city_outbound in (select * from city_in_USA) and p2.city_inbound in (select * from city_in_Canada))
or (p1.city_outbound in (select * from city_in_Canada) and p2.city_inbound in (select * from city_in_USA)))
and p1.inbound = p2.outbound and p2.dep_time - p1.arv_time >= '00:30:00'
);

create view two_connections as (
select  p3.arv_time as arv_time, p1.city_outbound as city_outbound,  p3.city_inbound as city_inbound
from x1 p1, x1 p2, x1 p3
where ((p1.city_outbound in (select * from city_in_USA) and p3.city_inbound in (select * from city_in_Canada))
or (p1.city_outbound in (select * from city_in_Canada) and p3.city_inbound in (select * from city_in_USA)))
and p1.inbound = p2.outbound and p2.inbound = p3.outbound 
and p2.dep_time - p1.arv_time >= '00:30:00' and p3.dep_time - p2.arv_time >= '00:30:00'
);

-- counts for each type of flight

create view numDirect as (
select city_outbound as cityod, city_inbound as cityid, count(*)as countd
from direct
group by city_outbound, city_inbound
);

create view numOneConnection as (
select city_outbound as cityo1, city_inbound as cityi1 , count(*) as count1
from one_connection
group by city_outbound, city_inbound
);

create view numTwoConnections as (
select city_outbound as cityo2, city_inbound as cityi2, count(*) as count2
from two_connections
group by city_outbound, city_inbound
);

-- all connections together

create view connections as (
	(select * from one_connection) union all
	(select * from two_connections)
);


-- earliest among connections 
create view earliest_connections as (
select city_outbound, city_inbound, min(arv_time)
from connections
group by city_outbound, city_inbound
);

-- all routes together
create view all_routes as (
	(select * from connections ) union all
	(select * from direct)
);

create view earliest_all as (
select city_outbound, city_inbound, min(arv_time) as earliest
from all_routes
group by city_outbound, city_inbound
);

create view direct_one as (
select cityod, cityid, countd, count1
from numDirect full join numOneConnection
on cityod = cityo1 and cityid = cityi1
);

create view direct_one_two as (
select cityod, cityid, countd, count1, count2
from direct_one full join numTwoConnections
on cityod = cityo2 and cityid = cityi2
);

create view best_routes as (
select cityod, cityid, countd, count1, count2, earliest 
from direct_one_two join earliest_all
on cityod = city_outbound and city_inbound = cityid
);




-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q3

select city_outbound, city_inbound,
CASE when countd is null then 0 else countd end, 
CASE when count1 is null then 0 else count1 end, 
CASE when count2 is null then 0 else count2 end,
earliest
from x0 full join best_routes
on city_outbound = cityod and city_inbound = cityid
