-- Триггер AFTER

-- Если номер машины блатной, то выводится информационное сообщение о том, с какой структуры человек
CREATE OR REPLACE FUNCTION crash.CheckNumber()
returns trigger
AS
    $$
    BEGIN
        if new.car_number like 'P%МР_97' then
            raise notice 'Блатной номер для министерства юстиций';
        end if;
        if new.car_number like 'А%ОО_97' or new.car_number like 'В%ОО_97' then
            raise notice 'Блатной номер для управления делами президента';
        end if;
        if new.car_number like 'Е%КХ_99' then
            raise notice 'Блатной номер для федеральной службы охраны РФ';
        end if;
        if new.car_number like 'В%ОР%' then
            raise notice 'Блатной номер для футболиста или вора в законе';
        end if;
        return new;
    end;
    $$ language plpgsql;

drop trigger if exists check_price_and_discount on crash.car;
CREATE TRIGGER check_car_number AFTER INSERT ON crash.car
FOR ROW EXECUTE PROCEDURE crash.CheckNumber();

insert into crash.car(car_id, car_number, car_model, car_type, transmission, drive_unit, engine_capacity, engine_volume, fuel_type, car_color, price)
VALUES (14895, 'В00ОР8_77', 'Opel Corsa D', 'внедорожник', 'робот', 'передний', 500, 1.6, 'бензин', 'чёрный', 1000000);

UPDATE crash.region as R
SET full_name = 'Еврейская АО'
WHERE region_id = 79;

-- Триггер INSTEAD OF
-- Не давать водительские права: 1) людям с Еврейской автономной области  (евреев) 2) женщин с количеством попыток > 3

CREATE OR REPLACE FUNCTION forbide_jude_and_woman()
RETURNS TRIGGER
AS $$
DECLARE
    region TEXT;
BEGIN
IF (New.region_id = (SELECT R.region_id
                        FROM crash.region as R
                        WHERE R.full_name = 'Еврейская АО')) then
        RAISE EXCEPTION 'Евреям нельзя получать водительские права.';
    end if;

    IF (New.sex = 'Ж' and New.attemps_of_pass > 3) then
        RAISE EXCEPTION 'Женщинам нельзя садиться за руль при таком количестве пересдач...';
    ELSE
        INSERT INTO crash.driver (driver_id, passport_id, surname, name, middle_name, date_of_birth, sex, year_of_get_license, study_transmission, attemps_of_pass, autoschool, region_id)
        VALUES (New.driver_id, New.passport_id, New.surname, New.name, New.middle_name, New.date_of_birth, New.sex, New.year_of_get_license,
            New.study_transmission, New.attemps_of_pass, New.autoschool, New.region_id);
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE PLPGSQL;

CREATE VIEW view_drivers AS
SELECT * FROM crash.driver LIMIT 10;

CREATE TRIGGER view_insert
    INSTEAD OF insert on view_drivers
    FOR EACH ROW
    EXECUTE PROCEDURE forbide_jude_and_woman();

INSERT INTO view_drivers(driver_id, passport_id, surname, name, middle_name, date_of_birth, sex, year_of_get_license, study_transmission, attemps_of_pass, autoschool, region_id)
VALUES (20003, '1234567891', 'Юнкина', 'Диана', 'Максимовна', '2002-11-25', 'Ж', 2021, 'механика', 4, 'Драйв', 24)
