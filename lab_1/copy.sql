\copy crash.Region FROM 'data/table_regions.csv' DELIMITER ',' CSV HEADER;
\copy crash.Driver FROM 'data/table_drivers.csv' DELIMITER ',' CSV HEADER;
\copy crash.Car  FROM 'data/table_cars.csv' DELIMITER ',' CSV HEADER;
\copy crash.Accident FROM 'data/table_crash.csv' DELIMITER ',' CSV HEADER;
\copy crash.Details FROM 'data/table_details.csv' DELIMITER ',' CSV HEADER;