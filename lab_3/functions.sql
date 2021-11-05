-- Скалярная функция
-- Функция, которая возвращает среднюю стоимость модели машины
CREATE OR REPLACE FUNCTION crash.modelAveragePrice(need_car_model TEXT) RETURNS DECIMAL
AS
    $$
BEGIN
    RETURN (select avg(C.price) from crash.car as C where C.car_model = need_car_model);
END
$$ language plpgsql;

select C.car_model, crash.modelAveragePrice(C.car_model)
from crash.car as C;


-- Подставляемая табличная функция
-- Вывести всех водителей, которые получили права в Красноярском крае до того, как я пошёл в школу
CREATE OR REPLACE FUNCTION crash.print_drivers_from_Kras()
RETURNS TABLE (
                name TEXT,
                middle_name TEXT,
                surname TEXT,
                passport_id TEXT,
                year_of_licence INT
              )
AS $$
    BEGIN
       RETURN query
        SELECT D.name, D.middle_name, D.surname, D.passport_id, D.year_of_get_license
        FROM crash.driver as D JOIN crash.region as R on (R.region_id = D.region_id)
        WHERE D.year_of_get_license < 2008;
    END
$$ language plpgsql;

SELECT *
FROM crash.print_drivers_from_Kras()


-- Многооператорная табличная функция
-- Вывести все машины, которые дороже заданной цены
CREATE OR REPLACE FUNCTION crash.print_cars_with_big_price(req_price INTEGER)
RETURNS TABLE (
                car_model TEXT,
                car_type TEXT,
                transmission TEXT,
                fuel_type TEXT,
                price INT
              )
AS $$
    BEGIN

        DROP TABLE if EXISTS car_big_price;

        CREATE TEMP TABLE car_big_price
        (
                car_model TEXT,
                car_type TEXT,
                transmission TEXT,
                fuel_type TEXT,
                price INT
        );

        INSERT INTO car_big_price(car_model, car_type, transmission, fuel_type, price)
        SELECT C.car_model, C.car_type, C.transmission, C.fuel_type, C.price
        FROM crash.car as C
        WHERE C.price > req_price;

        RETURN query
        SELECT * FROM car_big_price;
    END
$$ language plpgsql;

select *
from crash.print_cars_with_big_price(1000000);

-- Функция с рекурсией или рекурсивным ОТВ
-- Вычислить суммарную стоимость машин между current_id и end_id
CREATE OR REPLACE FUNCTION crash.SumCars(CurrentId int, EndId int)
RETURNS INT AS
    $$
    DECLARE cur_sum int;
    BEGIN
        if CurrentId > EndId then RETURN 0;
        end if;
        SELECT C.price into cur_sum from crash.car as C WHERE C.car_id = CurrentId;
        return cur_sum + crash.SumCars(CurrentId + 1, EndId);
    end;
    $$ language plpgsql;

select crash.SumCars(1, 10)
