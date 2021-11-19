-- 1. Из таблиц базы данных, созданной в первой лабораторной работе, извлечь данные в JSON.

COPY (select row_to_json(C) from crash.car as C) to '/home/prianechka/Education/BMSTU/DB/BMSTU-DB/lab_5/json/car.json';
COPY (select row_to_json(C) from crash.driver as C) to '/home/prianechka/Education/BMSTU/DB/BMSTU-DB/lab_5/json/driver.json';
COPY (select row_to_json(C) from crash.accident as C) to '/home/prianechka/Education/BMSTU/DB/BMSTU-DB/lab_5/json/accident.json';
COPY (select row_to_json(C) from crash.region as C) to '/home/prianechka/Education/BMSTU/DB/BMSTU-DB/lab_5/json/region.json';
COPY (select row_to_json(C) from crash.details as C) to '/home/prianechka/Education/BMSTU/DB/BMSTU-DB/lab_5/json/details.json';

-- 2. Выполнить загрузку и сохранение JSON файла в таблицу.
-- Созданная таблица после всех манипуляций должна соответствовать таблице
-- базы данных, созданной в первой лабораторной работе.

drop schema json cascade;
create schema json;

CREATE TABLE json.Region
(
	region_id INT PRIMARY KEY,
	name TEXT,
	region_type TEXT,
	full_name TEXT,
	federal_district TEXT,
	timezone INT not null
);

CREATE TABLE json.temp
(
    data jsonb
)

COPY json.temp (data) FROM '/home/prianechka/Education/BMSTU/DB/BMSTU-DB/lab_5/json/region.json';
INSERT INTO json.Region(region_id, name, region_type, full_name, federal_district, timezone)
SELECT (data->>'region_id')::INT, data->>'name', data->>'region_type', data->>'full_name', data->>'federal_district', (data->>'timezone')::INT FROM json.temp;

SELECT * from json.region;

-- 3. Создать таблицу, в которой будет атрибут(-ы) с типом JSON
-- Заполнить атрибут правдоподобными данными с помощью команд INSERT или UPDATE.

CREATE TABLE json.ex3
(
    id serial primary key,
    name TEXT,
    json_columns json
);

insert into json.ex3(name, json_columns) values
    ('Messi', '{"skill": 93, "position": {"RW":93, "CM":85, "ST":86}, "speed":42, "univer":"Barca"}'::json),
    ('Ronaldo', '{"skill": 91, "position": {"RW":92, "CM":87, "ST":89}, "speed":80, "univer":"street"}'::json),
    ('Prianishnikov', '{"size": 2, "position": {"RW":23, "CM":25, "ST":29}, "speed":21, "univer":"BMSTU"}'::json);

select * from json.ex3;

-- 4.Выполнить следующие действия:
--      1. Извлечь JSON фрагмент из JSON документа
--      2. Извлечь значения конкретных узлов или атрибутов JSON документа
--      3. Выполнить проверку существования узла или атрибута
--      4. Изменить JSON документ
--      5. Разделить JSON документ на несколько строк по узлам

CREATE TABLE json.ex4
(
    data jsonb
);

insert into json.ex4(data) values
    ('{"name":"Messi", "skill": 93, "position": {"RW":93, "CM":85, "ST":86}, "speed":42, "univer":"Barca"}'::json),
    ('{"name":"Ronaldo", "skill": 91, "position": {"RW":92, "CM":87, "ST":89}, "speed":80, "univer":"street"}'::json),
    ('{"name":"Prianishnikov", "size": 2, "position": {"RW":23, "CM":25, "ST":29}, "speed":21, "univer":"BMSTU"}'::json);



-- Извлечь JSON фрагмент из JSON документа.
SELECT data->'name' name FROM json.ex4;

-- Извлечь значения конкретных узлов или атрибутов JSON документа.
SELECT data->'position'->'RW' position_RW_skill
FROM json.ex4
WHERE data->'name' =  '"Messi"';

-- Выполнить проверку существования узла или атрибута.
CREATE FUNCTION json.check_key(json_to_check jsonb, key text)
RETURNS BOOLEAN
AS $$
BEGIN
    RETURN (json_to_check->key) IS NOT NULL;
END;
$$ LANGUAGE PLPGSQL;

SELECT json.check_key('{"name": "Messi", "skill": 90}', 'education');
SELECT json.check_key('{"name": "Prianishnikov", "skill": 22}', 'name');

-- Изменить JSON документ.
UPDATE json.ex4 SET data = data || '{"name": "Lionel"}'::jsonb WHERE data->'name' = '"Messi"';

select * from json.ex4;

-- Разделить JSON документ на несколько строк по узлам.

CREATE TABLE json.ex5
(
    data json
);

insert into json.ex5(data) values
    ('[{"name":"Messi", "skill": 93, "position": {"RW":93, "CM":85, "ST":86}, "speed":42, "univer":"Barca"},
    {"name":"Ronaldo", "skill": 91, "position": {"RW":92, "CM":87, "ST":89}, "speed":80, "univer":"street"},
    {"name":"Prianishnikov", "size": 2, "position": {"RW":23, "CM":25, "ST":29}, "speed":21, "univer":"BMSTU"}]');

select * from json.ex5

SELECT jsonb_array_elements(data::jsonb)
from json.ex5