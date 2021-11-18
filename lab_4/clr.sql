--create extension plpython3u;

drop schema clr cascade;
create schema clr;

-- Определяемая пользователем скалярная функция
-- Функция, которая возвращает количество аварий, в которых участвовал автомобиль заданного типа
CREATE OR REPLACE FUNCTION clr.CountCrashCarsTypes(type TEXT)
RETURNS INTEGER language plpython3u
AS
    $$
    result = plpy.execute(f"\
                            SELECT distinct count(*) \
                            FROM crash.car as C join crash.details as D on (C.car_id = D.car_id) \
                            WHERE C.car_type = '{type}';")
    return result[0]['count'];
    $$;

SELECT car_type, clr.CountCrashCarsTypes(car_type)
FROM crash.car
GROUP by car_type;

-- Пользовательская агрегатная функция
-- Вывести среднее опьянение виновных женщин по каждому региону
CREATE OR REPLACE FUNCTION clr.MeanFemaleRegionAlc(region TEXT)
RETURNS DECIMAL language plpython3u
AS
    $$
    result = plpy.execute(f"\
                            SELECT round(avg(Dt.alcohol_level), 3) as mean\
                            FROM crash.driver as D join crash.region as R on (D.region_id = R.region_id) \
                                join crash.details as Dt on (Dt.driver_id = D.driver_id) \
                            WHERE D.sex = 'Ж' and Dt.is_blamed = True and R.full_name = '{region}';")
    return result[0]['mean'];
    $$;

SELECT full_name, clr.MeanFemaleRegionAlc(full_name)
FROM crash.region
GROUP by full_name;

-- Определяемая пользователем табличная функция CLR
-- Вывести таблицу машин, на которых попадали в аварию люди, получившие права с 2016 и позже
CREATE OR REPLACE FUNCTION clr.CarsWithYoungDrivers()
RETURNS TABLE
(
    car_id INTEGER,
    car_model TEXT,
    car_type TEXT,
    price INTEGER
) language plpython3u
AS
    $$
    result = plpy.execute(f"\
                            SELECT C.car_id, C.car_model, C.car_type, C.price \
                            FROM crash.driver as D join crash.details as Dt on (Dt.driver_id = D.driver_id) \
                                join crash.car as C on (C.car_id = Dt.car_id) \
                            WHERE D.year_of_get_license > 2015;")
    for string in result:
        yield (string["car_id"], string['car_model'], string['car_type'], string['price']);
    $$;

SELECT * from clr.CarsWithYoungDrivers();


-- Хранимая процедура CLR
-- Вывести все машины, у которых мощность двигателя находится в заданном интервале
CREATE OR REPLACE PROCEDURE clr.CountCarsWithEngine(first integer, second integer, cnt integer)
language plpython3u
AS
    $$
    if first > second:
        plpy.notice(f"Общее количество: {cnt}");
        return;
    result = plpy.execute(f"\
                            select count(*) as count \
                            from crash.car as C \
                            WHERE C.engine_capacity = {first};")
    plpy.execute(f"call clr.CountCarsWithEngine({first} + 1, {second}, {cnt} + {result[0]['count']})");
    $$;

call clr.CountCarsWithEngine(100, 150, 0);



-- Триггер CLR
-- При добавлении нового человека выводится, во сколько лет человек получил права
CREATE OR REPLACE FUNCTION clr.CountFullAge()
returns trigger
AS
    $$
        year = plpy.execute(f"SELECT EXTRACT(year from TIMESTAMP '{TD['new']['date_of_birth']}')")
        delta = TD['new']['year_of_get_license'] - year[0]['extract']
        plpy.notice(f"Количество полных лет: {delta}");
    $$ LANGUAGE PLPYTHON3U;

drop trigger if exists print_age on crash.driver;
CREATE TRIGGER print_age AFTER INSERT ON crash.driver
FOR ROW EXECUTE PROCEDURE clr.CountFullAge();

INSERT INTO crash.driver(driver_id, passport_id, surname, name, middle_name, date_of_birth, sex, year_of_get_license, study_transmission, attemps_of_pass, autoschool, region_id)
VALUES (20002, '0415286283', 'Прянишников', 'Александр', 'Николаевич', '1991-05-28', 'М', 2021, 'механика', 1, 'Азбука вождения', 24)

-- Определяемый пользователем тип данных CLR
-- По заданному количеству аварий определить машины, на которых в аварии попадали чаще
drop type MyCarType cascade
create type MyCarType AS
(
    car_model TEXT,
    count INT
)

drop function clr.mytype(crashval integer);

create or replace function clr.MyType(crashes INTEGER)
RETURNS setof MyCarType language plpython3u as $$
    result = plpy.cursor(f"\
            select C.car_model, count(*)\
            from crash.car as C join crash.details as Dt on (C.car_id = Dt.car_id) \
            group by C.car_model \
            having count(C.car_model) > {crashes};")
    for string in map(lambda string: (string['car_model'], string['count']), result):
        yield string
    $$;

select * from clr.MyType(20)