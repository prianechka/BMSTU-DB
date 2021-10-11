DROP SCHEMA IF EXISTS lab CASCADE ;

CREATE SCHEMA crash

CREATE TABLE crash.Region
(
	region_id INT PRIMARY KEY,
	name TEXT,
	region_type TEXT,
	full_name TEXT,
	federal_district TEXT,
	timezone INT not null
);
CREATE TABLE crash.Driver
(
	driver_id INT PRIMARY KEY,
	passport_id TEXT,
	surname TEXT,
	name TEXT,
	middle_name TEXT,
	date_of_birth DATE,
	sex TEXT,
	year_of_get_license INT not null,
	study_transmission TEXT,
	attemps_of_pass INT not null,
	autoschool TEXT,
	FOREIGN KEY (region_id) references crash.Region(region_id) on delete cascade
);
CREATE TABLE crash.Car 
(
	car_id INT PRIMARY KEY,
	car_number TEXT,
	car_model TEXT,
	car_type TEXT,
	transmission TEXT,
	drive_unit TEXT,
	engine_capacity INT not null,
	engine_volume DECIMAL(3, 5),
	fuel_type TEXT,
	car_color TEXT,
	price INT not null
)

CREATE TABLE crash.Accident
(
	accident_id INT PRIMARY KEY,
	accident_date DATE,
	accident_time TIME,
	number_members INT not null,
	road_type TEXT,
	road_cover_type TEXT,
	temperature INT,
	light_extent DECIMAL(2, 5),
	moisture_extent INT
);
CREATE TABLE crash.Details
(
	id INT not null,
	FOREIGN KEY (accident_id) references crash.Accident(accident_id) on delete cascade
	FOREIGN KEY (car_id) references crash.Car(car_id) on delete cascade
	FOREIGN KEY (driver_id) references crash.Driver(driver_id) on delete cascade
	alcohol_level DECIMAL(2, 5),
	is_blamed BOOLEAN,
	is_exited_crash BOOLEAN,
	driver_damage TEXT,
	n_passengers INT
)