-- Q2. Refunds!

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel, public;
DROP TABLE IF EXISTS q2 CASCADE;

CREATE TABLE q2 (
    airline CHAR(2),
    name VARCHAR(50),
    year CHAR(4),
    seat_class seat_class,
    refund REAL
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW if EXISTS Inbound CASCADE;
DROP VIEW IF EXISTS outbound CASCADE;
DROP VIEW IF EXISTS Domestic CASCADE;
DROP VIEW IF EXISTS RefundAmount35D CASCADE;
DROP VIEW IF EXISTS RefundAmount50D CASCADE;
DROP VIEW IF EXISTS domestic_refunds CASCADE;
DROP VIEW IF EXISTS international CASCADE;
DROP VIEW IF EXISTS RefundAmount35I CASCADE;
DROP VIEW IF EXISTS RefundAmount50I CASCADE;
DROP VIEW IF EXISTS international_refunds CASCADE;
DROP VIEW IF EXISTS all_refunds CASCADE;
DROP VIEW IF EXISTS get_airline CASCADE;


-- Define views for your intermediate steps here:

-- Outbound and Inbound Flights

create view outbound as (
select country as outboundCountry,flight.id as flightOID, airline as out_airline, s_dep as depO, s_arv as arrO
from airport join flight on outbound = code
);

create view inbound as (
select country as inboundCountry, flight.id as flightIID
from airport join flight on inbound = code 
);

-- Domestic Flights first

create view Domestic as (
select flightOID as domID, depO, arrO, out_airline
from outbound, inbound
where outboundCountry = inboundCountry and flightOID = flightIID
);

-- flights that desever 35% refund and amount of the refund
create view RefundAmount35D as (
select domId as rid, seat_class, (0.35 * price) as amount, extract(year from ArrDT) as year, out_airline
from  booking, (
select domID, arrival.datetime as ArrDT, out_airline
from Domestic, arrival, departure
where domID = arrival.flight_id and domID = departure.flight_id
and (departure.datetime - depO) <  '10:00:00' and (departure.datetime - depO) >= '5:00:00' 
and (departure.datetime - depO) <= (arrival.datetime - arrO) * 2
) as REFUND35D
where domID = booking.flight_id
);
-- flights that desever 50% refund and amount
create view RefundAmount50D as (
select domId as rid, seat_class, (0.5 * price) as amount, extract(year from ArrDT) as year, out_airline
from booking, 
(
select domID, arrival.datetime as ArrDT, out_airline
from Domestic, arrival,departure
where domID = arrival.flight_id and domID = departure.flight_id
and (departure.datetime - depO) >=  '10:00:00' and (departure.datetime - depO) <= (arrival.datetime - arrO) * 2
) as REFUND50D
where domID = booking.flight_id
);

-- all domestic refunds
create view domestic_refunds as (
(select * from RefundAmount35D) union all 
(select * from RefundAmount50D)
);

-- international flights

create view international as (
select flightOID as intID, depO, arrO, out_airline
from outbound, inbound
where outboundCountry <> inboundCountry and flightOID = flightIID
);
-- flights that desever 35% refund and amount of the refund
create view RefundAmount35I as (
select intId as rid, seat_class, (0.35 * price) as amount, extract(year from ArrDT) as year, out_airline
from booking, (
select intID, arrival.datetime as ArrDT, out_airline
from international, arrival, departure
where intID = arrival.flight_id and intID = departure.flight_id
and (departure.datetime - depO) <  '12:00:00' and (departure.datetime - depO) >= '8:00:00' 
and (departure.datetime - depO) <= (arrival.datetime - arrO) * 2
) as REFUND35I
where intID = booking.flight_id
);
-- flights that desever 50% refund and amount of the refund
create view RefundAmount50I as (
select intId as rid, seat_class, (0.5 * price) as amount, extract(year from ArrDT) as year, out_airline
from booking,  (
select intID, arrival.datetime as ArrDT, out_airline
from international, arrival,departure
where intID = arrival.flight_id and intID = departure.flight_id
and (departure.datetime - depO) >=  '12:00:00' and (departure.datetime - depO) <= (arrival.datetime - arrO) * 2
) as REFUND50I
where intID = booking.flight_id
);
-- all international refunds
create view international_refunds as (
(select * from RefundAmount35I) union all 
(select * from RefundAmount50I)
);

-- all refunds
create view all_refunds as (
(select * from domestic_refunds) union all
(select * from international_refunds)
);


-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q2

select out_airline, name, year, seat_class, sum(amount) as refund
from all_refunds join airline on code = out_airline
group by (out_airline, name, seat_class, year)
order by out_airline


