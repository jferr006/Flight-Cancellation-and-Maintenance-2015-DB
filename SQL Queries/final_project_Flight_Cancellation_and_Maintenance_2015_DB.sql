-- Final Project Queries for Flight Cancellation and Maintenance 2015 Database

--1) What's the most common cancellation reason?
--Jean Charles
SELECT 
    C.cancellation_description, 
    COUNT(F.CANCELLED) AS Total_cancellations
FROM flights_sample AS F
INNER JOIN cancellation_codes AS C ON F.CANCELLATION_REASON = C.cancellation_reason
WHERE F.CANCELLED = 1
GROUP BY C.cancellation_description
ORDER BY Total_Cancellations DESC;

--2) Which airlines have a higher number of cancellations?

SELECT 
    AL.airline, 
    COUNT(*) AS Total_Cancellations,
    RANK() OVER (ORDER BY COUNT(*) DESC) AS Cancellation_Rank
FROM flights_sample AS F
INNER JOIN airlines AS AL ON F.AIRLINE = AL.iata_code
WHERE F.CANCELLED = 1
GROUP BY AL.airline;

--3) Cancellation percentage per airline

WITH AirlineTotals AS (
    SELECT AIRLINE, COUNT(*) AS Total_Flights
    FROM flights_sample
    GROUP BY AIRLINE
),
AirlineCancellations AS (
    SELECT AIRLINE, COUNT(*) AS Cancelled_Flights
    FROM flights_sample
    WHERE CANCELLED = 1
    GROUP BY AIRLINE
)
SELECT 
    AL.airline,
    AT.Total_Flights,
    AC.Cancelled_Flights,
    CAST(ROUND((AC.Cancelled_Flights * 100.0 / AT.Total_Flights), 2) AS DECIMAL(10,2)) AS Cancellation_Rate
FROM AirlineTotals AS AT
INNER JOIN AirlineCancellations AS AC ON AT.AIRLINE = AC.AIRLINE
INNER JOIN airlines AS AL ON AT.AIRLINE = AL.iata_code
ORDER BY AT.Total_Flights DESC;

--4) Flights with above average delay-Possible outliers

SELECT TOP 5
    AIRLINE, 
    FLIGHT_NUMBER, 
    ARRIVAL_DELAY
FROM flights_sample
WHERE ARRIVAL_DELAY > (SELECT AVG(ARRIVAL_DELAY) FROM flights_sample)
ORDER BY ARRIVAL_DELAY DESC; 

--5) Flight information. Get flight information for an specific flight number.Get flight information for possible outliers  

GO
CREATE PROCEDURE GetFlightDetails
    @FlightNumber INT
AS
BEGIN
    SELECT 
        F.YEAR, 
        F.MONTH, 
        F.DAY, 
        AL.airline AS Airline_Name, 
        F.FLIGHT_NUMBER, 
        F.TAIL_NUMBER, 
        ARo.city AS Origin_City,
        ARo.airport AS Origin_Airport, 
        ARd.city AS Destination_City,
        ARd.airport AS Destination_Airport, 
        F.DEPARTURE_DELAY AS Departure_Delay, 
        F.ARRIVAL_DELAY AS Arrival_Delay,
        F.DISTANCE
        FROM flights_sample AS F
        INNER JOIN airlines AS AL ON F.AIRLINE = AL.iata_code
        INNER JOIN airports AS ARo ON F.ORIGIN_AIRPORT = ARo.iata_code
        INNER JOIN airports AS ARd ON F.DESTINATION_AIRPORT = ARd.iata_code
        WHERE F.FLIGHT_NUMBER = @FlightNumber
        ORDER BY F.YEAR, F.MONTH, F.DAY;
END
GO
EXEC GetFlightDetails @FlightNumber = 1187

--6) Which airlines are the most popular? 

SELECT TOP (5) 
    AL.airline, 
    COUNT(*) AS Number_Of_Flights
FROM flights_sample AS F
INNER JOIN airlines AS AL ON F.AIRLINE = AL.iata_code
GROUP BY AL.airline
ORDER BY Number_Of_Flights DESC

--7) Long-haul routes: What are the longest flights (distance)? 

SELECT DISTINCT TOP (5) 
    (SELECT airline FROM airlines WHERE iata_code = F.AIRLINE) AS Airline_Name,
    F.FLIGHT_NUMBER, 
    (SELECT airport FROM airports WHERE iata_code = F.ORIGIN_AIRPORT) AS Origin_Airport,
    (SELECT airport FROM airports WHERE iata_code = F.DESTINATION_AIRPORT) AS Destination_Airport,
    F.DISTANCE
FROM flights_sample AS F
ORDER BY F.DISTANCE DESC;


--8) What's the most popular day of the week to fly and what is the corresponding cancellation rate? 

WITH DailyStats AS (
    SELECT 
        DAY_OF_WEEK,
        COUNT(*) AS Total_Flights_Scheduled,
        CAST(AVG(DEPARTURE_DELAY) AS DECIMAL(10,2)) AS Avg_Departure_Delay
    FROM flights_sample
    GROUP BY DAY_OF_WEEK
),
DailyCancellations AS (
    SELECT 
        DAY_OF_WEEK,
        COUNT(*) AS Total_Flights_Cancelled
    FROM flights_sample
    WHERE CANCELLED = 1
    GROUP BY DAY_OF_WEEK
)
SELECT 
    CASE D.DAY_OF_WEEK
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
        WHEN 7 THEN 'Sunday'
    END AS Day_of_the_week,
    D.Total_Flights_Scheduled,
    D.Avg_Departure_Delay, 
    CAST((DC.Total_Flights_Cancelled * 100.0 / D.Total_Flights_Scheduled) AS DECIMAL(10,2)) AS Cancellation_Rate_Percent
FROM DailyStats AS D
INNER JOIN DailyCancellations AS DC ON D.DAY_OF_WEEK = DC.DAY_OF_WEEK
ORDER BY D.Total_Flights_Scheduled DESC;

--9) What are the busiest airports?

SELECT TOP (10) 
    AR.airport, 
    COUNT(F.ORIGIN_AIRPORT) AS Departures
FROM flights_sample AS F
INNER JOIN airports AS AR ON F.ORIGIN_AIRPORT = AR.iata_code
GROUP BY AR.airport
ORDER BY Departures DESC;

--10) Busy airports with major delays 
SELECT 
    AR.airport AS Airport, 
    COUNT(*) AS Number_of_Flights,
    CAST(AVG(F.DEPARTURE_DELAY) AS DECIMAL(10,2)) AS Average_Delay
FROM flights_sample AS F
INNER JOIN airports AS AR ON F.ORIGIN_AIRPORT = AR.iata_code
GROUP BY AR.airport
HAVING COUNT(*) > 100 AND AVG(F.DEPARTURE_DELAY) > 15
ORDER BY Average_Delay DESC;

--11) Statistics for every airports. Statistics for Miami International Airport

GO
CREATE PROCEDURE AirportStats @AirportCode VARCHAR(10)
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM airports WHERE iata_code = @AirportCode)
        PRINT 'Error: Airport code ' + @AirportCode + ' does not exist in the database.';
    ELSE
    SELECT 
        ORIGIN_AIRPORT, 
        COUNT(*) AS Total_Departures,
        AVG(TAXI_OUT) AS Avg_Taxi_Out_Time
    FROM flights_sample
    WHERE ORIGIN_AIRPORT = @AirportCode
    GROUP BY ORIGIN_AIRPORT
END;
GO
-- 
EXEC AirportStats @AirportCode = 'MIA'

--12) Get airport traffic statistics 

GO
CREATE VIEW AirportTraffic AS
SELECT 
    AR.city,
    AR.state,
    AR.airport,
    COUNT(F.FLIGHT_NUMBER) AS Total_Flights,
    COUNT(DISTINCT F.DESTINATION_AIRPORT) AS Unique_Destinations
FROM airports AS AR
INNER JOIN flights_sample AS F ON AR.iata_code = F.ORIGIN_AIRPORT
GROUP BY AR.city, AR.state, AR.airport
GO

SELECT TOP (10) * FROM AirportTraffic
ORDER BY Total_Flights DESC;

-- 14) Number of maintenance based off year of aircraft models, Sorted by year_built

SELECT ai.year_built, COUNT(*) AS Maintenance
FROM maintenance_history mh
JOIN aircraft_info ai ON mh.tail_number = ai.tail_number
GROUP BY ai.year_built
ORDER BY ai.year_built ASC;

-- 15) Number of maintenance based off manufacturer

SELECT ai.manufacturer, COUNT(*) AS Maintenance
FROM maintenance_history mh
JOIN aircraft_info ai ON mh.tail_number = ai.tail_number
GROUP BY ai.manufacturer
ORDER BY Maintenance DESC;

-- 16) Number of maintenance based off airline_company

SELECT mh.airline_company, COUNT(*) AS Maintenance
FROM maintenance_history mh
GROUP BY mh.airline_company
ORDER BY Maintenance DESC;

-- 17) Number of maintenance based off tail_number

SELECT mh.tail_number, COUNT(*) AS Maintenance
FROM maintenance_history mh
GROUP BY mh.tail_number
ORDER BY Maintenance DESC;

-- 18) Large assortment of all 4 catergories

SELECT ai.year_built, mh.airline_company, ai.manufacturer, mh.tail_number, COUNT(*) AS Maintenance
FROM maintenance_history mh
JOIN aircraft_info ai ON mh.tail_number = ai.tail_number
GROUP BY ai.manufacturer, ai.year_built, mh.airline_company, mh.tail_number
ORDER BY Maintenance DESC;

-- 19) Holiday flights
/*
using 'flights_sample' and 'airlines' tables.
We Filter DAY from 'flights_sample' to only include '25' = Christmas Day.
We Cross reference AIRLINE from 'flights_sample' with iata_code from 'airlines' to get the airline company name.
*/

SELECT a.Airline, COUNT(*) AS Christmas_Flights
FROM flights_sample f
JOIN airlines a ON f.AIRLINE = a.iata_code
WHERE f.DAY = 25
GROUP BY a.Airline
ORDER BY Christmas_Flights DESC;

/*
using 'flights_sample' and 'airlines' tables.
We Filter DAY from 'flights_sample' to only include '31' = New Year's Day.
We Cross reference AIRLINE from 'flights_sample' with iata_code from 'airlines' to get the airline company name.
*/

SELECT a.Airline, COUNT(*) AS New_Years_Flights
FROM flights_sample f
JOIN airlines a ON f.AIRLINE = a.iata_code
WHERE f.DAY = 31
GROUP BY a.Airline
ORDER BY New_Years_Flights DESC;

-- 20) Highest seated capacity rated
/*
We pull form the aircraft_info table selecting columns seating_capacity and tail_number.
We pull from the maintenance_history table selecting tail_number and airline_company.
We cross reference tail_number from both tables to get the airline company name and seating capacity.
Showing the top 10 highest seating capacity models of each airline company.
*/

SELECT mh.airline_company, ai.tail_number, ai.manufacturer, ai.model, ai.seating_capacity
FROM maintenance_history mh
JOIN aircraft_info ai ON mh.tail_number = ai.tail_number
ORDER BY ai.seating_capacity DESC;

-- 21) Most expensive maintenance cost
/*
We will be using the tables 'maintenance_history'.
Selecting columns airline_company, tail_number, maintenance_cost.
We will be joining each unique airline_company with their respective tail_number and maintenance_cost.
*/

SELECT 
    airline_company,
    SUM(cost) AS total_cost,
    COUNT(DISTINCT tail_number) AS aircrafts_maintained,
    COUNT(airline_company) AS sum_of_maintenances
FROM maintenance_history
GROUP BY airline_company
ORDER BY total_cost DESC;

-- 22) Airline with the most expensive maintenance cost per seating capacity
/*
We will be using the tables 'maintenance_history' and 'aircraft_info'.
We will join these tables on the 'tail_number' column.
We will calculate the total maintenance cost for each airline and divide it by the total seating capacity of all aircraft operated by that airline.
*/

SELECT 
    mh.airline_company,
    SUM(mh.cost) AS total_maintenance_cost,
    SUM(ai.seating_capacity) AS total_seating_capacity,
    ROUND(CAST(SUM(mh.cost) / SUM(ai.seating_capacity) AS DECIMAL(10,2)), 2) AS mtnc_cost_vs_seat_cap
FROM maintenance_history mh
JOIN aircraft_info ai ON mh.tail_number = ai.tail_number
GROUP BY mh.airline_company
ORDER BY mtnc_cost_vs_seat_cap DESC;

-- 23) Most used aircraft model from each airline company
/*
We will be using the tables maintenance_history and aircraft_info.
we will join these tables on the tail_number column.
We will group by airline_company, manufacturer, and model to get the count of each model used by each airline company.
*/

SELECT
    mh.airline_company,
    ai.manufacturer,
    ai.model,
    COUNT(*) AS usace_count
FROM maintenance_history mh
JOIN aircraft_info ai ON mh.tail_number = ai.tail_number
GROUP BY mh.airline_company, ai.manufacturer, ai.model
ORDER BY airline_company ASC;


