-- Хранимая процедура с параметром
-- Процедура, выводящая количество аварий, которые произошли на определённом типе дороги
CREATE OR REPLACE PROCEDURE crash.countCrashRoad(req_road_type TEXT)
AS
    $$
    DECLARE
        cnt INTEGER;
    BEGIN
        SELECT into cnt count(*)
        FROM crash.accident as A
        WHERE A.road_type = req_road_type;

    RAISE NOTICE 'The number of % crashes: %', req_road_type, cnt;
    END;

    $$ language plpgsql;

CALL crash.countCrashRoad('Обычная дорога типа I');

-- Рекурсивная хранимая процедура
-- Вывести количество машин, мощность двигателя которых находится в промежутке от StartCap до EndCap

CREATE OR REPLACE PROCEDURE crash.CountCarsEngine(startCap integer, endCap integer, in cnt integer)
AS
    $$
    DECLARE tmp INTEGER;
    BEGIN
        if startCap > endCap then
            raise notice 'The number of cars: %', cnt;
            return;
        end if;
        select into tmp count(*)
        from crash.car as C
        WHERE C.engine_capacity = startCap;
        cnt := cnt + tmp;
        call crash.CountCarsEngine(startCap + 1, endCap, cnt);
    END;
    $$ language plpgsql;

call crash.CountCarsEngine(100, 150, 0);


-- Хранимая процедура с курсором
-- Вывести ФИО каждого виновного участника аварии

CREATE OR REPLACE PROCEDURE crash.PrintBlamed()
as
    $$
    DECLARE
        cur_driver RECORD;
        all_drivers CURSOR for
        select D.name, D.middle_name, D.surname
        from crash.details as Dt join crash.driver as D on (Dt.driver_id = D.driver_id)
        where Dt.is_blamed = true;

    BEGIN
        open all_drivers;
        LOOP
            fetch all_drivers into cur_driver;
            raise notice 'ФИО виновного: % % %', cur_driver.name, cur_driver.middle_name, cur_driver.surname;
            EXIT When not found;
        end loop;
        close all_drivers;
    end;
    $$ language plpgsql;

call crash.PrintBlamed()

-- Хранимая процедура доступа к метаданным
-- Вывести по названию схемы все таблицы
create or replace procedure crash.PrintMeta(schema_name TEXT)
as $$
declare temp record;
begin
    for temp in select table_catalog as db, table_schema as schema, table_name as table
                from information_schema.tables
                where table_catalog = 'bmstu' and table_schema = schema_name
    loop
        raise info 'Catalog, schema, table = %', temp;
    end loop;
end; $$ language plpgsql;

call crash.PrintMeta('crash');