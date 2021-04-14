-- Q4. Plane Capacity Histogram

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel, public;
DROP TABLE IF EXISTS q4 CASCADE;

CREATE TABLE q4 (
	airline CHAR(2),
	tail_number CHAR(5),
	very_low INT,
	low INT,
	fair INT,
	normal INT,
	high INT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS departed_flights CASCADE;
DROP VIEW IF EXISTS capacity_plane CASCADE;
DROP VIEW IF EXISTS dep_flights_info CASCADE;
DROP VIEW IF EXISTS filled CASCADE;
DROP VIEW IF EXISTS lt20 CASCADE;
DROP VIEW IF EXISTS lt40 CASCADE;
DROP VIEW IF EXISTS lt60 CASCADE;
DROP VIEW IF EXISTS lt80 CASCADE;
DROP VIEW IF EXISTS final CASCADE;



-- Define views for your intermediate steps here:

create view departed_flights as (
select id as depId, plane as pid
from flight join departure
on id = flight_id
);

create view capacity_plane as (
select tail_number, 
(plane.capacity_economy + plane.capacity_business + plane.capacity_first) as capacity
from plane
);

create view dep_flights_info as (
select depId, pid, capacity
from departed_flights join capacity_plane
on tail_number = pid
);




create view filled as (
select depId, pid, (count * 100/ capacity) as percent_filled
from dep_flights_info, 
(select depid as perId, count (id) as count
from departed_flights left join Booking
on depId = flight_id
group by depId) as pas_per_plane
where depId = perId 
);


create view lt20 as (
select airline, tail_number, count_lowest
from plane natural left join 
(select pid as tail_number, count(depid) as count_lowest
from filled 
where percent_filled >=0 and percent_filled <=20
group by pid
) as lowest
);


create view lt40 as (
select airline, tail_number, count_lowest,count_low
from lt20 natural left join  
(select pid as tail_number, count(depId) as count_low
from filled 
where percent_filled > 20 and percent_filled <=40
group by pid
) as low
);


create view lt60 as (
select airline , tail_number,count_lowest, count_low, count_fair
from lt40 natural left join
(select pid as tail_number, count(depId) as count_fair
from filled 
where percent_filled > 40 and percent_filled <=60
group by pid
) as fair
);


create view lt80 as (
select airline, tail_number, count_lowest, count_low, count_fair, count_medium
from lt60 natural left join
(select pid as tail_number, count(depId) as count_medium
from filled 
where percent_filled > 60 and percent_filled <=80
group by pid) as medium
);


create view final as (
select airline, tail_number,
count_lowest, count_low, count_fair, count_medium, count_high
from lt80 natural left join 
(select pid as tail_number, count(depid) as count_high
from filled 
where percent_filled >80
group by pid) as high
);

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q4

select airline,tail_number,
CASE when count_lowest is null then 0 else count_lowest end, 
CASE when count_low is null then 0 else count_low end,
CASE when count_fair is null then 0 else count_fair end,
CASE when count_medium is null then 0 else count_medium end,
CASE when count_high is null then 0 else count_high end
from final;
