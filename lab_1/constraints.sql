--Driver constraints
ALTER TABLE crash.Driver
    ADD CONSTRAINT correct_date_birth CHECK (date_of_birth >= '1920-01-01'::date AND date_birth <= '2003-12-31'::date);

ALTER TABLE crash.Driver
    ADD CONSTRAINT correct_year_of_license CHECK (year_of_get_license >= 1950 AND year_of_get_license <= 2021);

ALTER TABLE crash.Driver
	ADD CONSTRAINT correct_passport CHECK (LENGTH(passport_id) = 10);

ALTER TABLE crash.Driver
	ADD CONSTRAINT correct_transmission CHECK (study_transmission = 'автомат' OR study_transmission = 'механика');

ALTER TABLE crash.Driver
	ADD CONSTRAINT correct_sex CHECK (sex = 'М' OR sex = 'Ж');


--Car constraints
ALTER TABLE crash.Car
    ADD CONSTRAINT correct_engine CHECK (engine_capacity < 120 AND engine_capacity > 50);

ALTER TABLE crash.Car 
    ADD CONSTRAINT correct_volume CHECK (engine_volume > 0.000125 AND engine_volume < 10);

ALTER TABLE crash.Car
    ADD CONSTRAINT correct_price CHECK (price < 100000000);

ALTER TABLE crash.Car
    ADD CONSTRAINT correct_drive_unit CHECK (drive_unit = 'передний' OR drive_unit = 'полный' OR drive_unit = 'задний');

ALTER TABLE crash.Car
    ADD CONSTRAINT correct_fuel CHECK (fuel_type = 'Бензин' OR fuel_type = 'Дизель' OR fuel_type = 'Гибрид');

--Crash constraints
ALTER TABLE crash.Accident
    ADD CONSTRAINT correct_date CHECK (accident_date >= '2020-10-10'::date AND date_added <= current_date);

ALTER TABLE crash.Accident	
	ADD CONSTRAINT correct_temperature CHECK (temperature >= -40 AND temperature <= 40);

ALTER TABLE crash.Accident	
	ADD CONSTRAINT correct_light CHECK (light_extent <= 3);

ALTER TABLE crash.Accident
	ADD CONSTRAINT correct_moisture CHECK (moisture <= 100);

--Details constraints
ALTER TABLE crash.Details
	ADD CONSTRAINT correct_alcohol CHECK (alcohol_level < 7);
	
ALTER TABLE crash.Details
	ADD CONSTRAINT correct_passengers CHECK (n_passengers < 20);

ALTER TABLE crash.Details
	ADD CONSTRAINT correct_damage CHECK (driver_damage = 'Лёгкие' OR  driver_damage = 'Средние' OR driver_damage = 'Тяжёлые');

	