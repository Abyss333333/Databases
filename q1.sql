-- Q1. Airlines

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel, public;
DROP TABLE IF EXISTS q1 CASCADE;

CREATE TABLE q1 (
    pass_id INT,
    name VARCHAR(100),
    airlines INT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS flight_taken CASCADE;
DROP VIEW IF EXISTS p_info CASCADE;
DROP VIEW IF EXISTS null_join CASCADE;


-- Define views for your intermediate steps here:

--- connection Flights -> Booking -> Passenger

-- All Flights Taken that have departed, this means that the flight has been taken.

create view flight_taken as(
select Flight.airline as airline, Flight.id as flid
from Flight, Departure
where Departure.flight_id = Flight.id
);

-- All Bookings of those flights that have departed, this will help get the booking info which will allow to get passenger id.
create view p_info as (
select flid, airline, Booking.pass_id as Bid
from Booking join flight_taken on Booking.flight_id = flid
);

create view null_join as (
select id, firstname, surname, count(distinct airline) as count
from p_info right join passenger on id = Bid
group by id
);

-- Your query that answers the question goes below the "insert into" line:
-- left join because we have to include every Passenger whether they have taken a flight or not.
INSERT INTO q1
select id, firstname||' '||surname, count
from null_join





