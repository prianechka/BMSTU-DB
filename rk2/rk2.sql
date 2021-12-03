DROP SCHEMA IF EXISTS rk2 CASCADE ;

CREATE SCHEMA rk2;

-- Задание 1
CREATE TABLE rk2.currency
(
	currency_id SERIAL PRIMARY KEY,
	currency TEXT
);

CREATE TABLE rk2.ExchangeRate
(
    exc_id SERIAL PRIMARY KEY,
    currency_id INT UNIQUE,
    sale DECIMAL,
    buy DECIMAL,
    FOREIGN KEY (currency_id) references rk2.currency (currency_id) on delete cascade
);

CREATE TABLE rk2.Personal
(
    personal_id SERIAL PRIMARY KEY,
    FIO TEXT,
    year_of_birthday INT NOT NULL,
    post TEXT
);

CREATE TABLE rk2.Operations
(
    operation_id SERIAL PRIMARY KEY,
    personal_id INT,
    exc_id INT,
    summa DECIMAL, -- Сколько куплено валюты (5 долларов, 1000 биткоинов)
    FOREIGN KEY (exc_id) references rk2.ExchangeRate (exc_id) on delete cascade,
    FOREIGN KEY (personal_id) references rk2.Personal (personal_id) on delete cascade
);

INSERT INTO rk2.Personal(FIO, year_of_birthday, post) VALUES
    ('Куров Андрей Владимирович', 1950, 'заместитель начальника кафедры ИУ7'),
    ('Гаврилова Юлия Михайловна', 1995, 'преподаватель по БД'),
    ('Кукс Игорь Владимирович', 1960, 'майор запаса РТВ'),
    ('Солнцева Татьяна Викторовна', 2001, 'сотрудница'),
    ('Иванов Иван Ивановмч', 1990, 'сотрудник'),
    ('Тонкоштан Андрей Алексеевич', 2001, 'сотрудник'),
    ('Прянишников Александр Николаеви', 2001, 'сотрудник'),
    ('Козлова Ирина', 2001, 'сотрудница'),
    ('Путин Владимир Владимирович', 1952, 'президент'),
    ('Фёдоров Мирон Янович', 1990, 'рэпер');

INSERT INTO rk2.currency(currency) VALUES
('Рубль'), ('Доллар'), ('Евро'), ('Йен'), ('Рупи'), ('Гривна'), ('Фунт'), ('Лира'), ('Биткоин'), ('Эфир');

INSERT INTO rk2.ExchangeRate(currency_id, sale, buy) VALUES
(1, 70.5, 72), (2, 65, 69), (3, 13.5, 27.3), (4, 6, 1.2), (5, 22, 23.6), (6, 72, 22.2222), (7, 3, 4), (8, 66, 66.6),
    (9, 12, 13), (10, 1, 2);

INSERT INTO rk2.Operations(personal_id, exc_id, summa) VALUES
(2, 2, 10000), (3, 2, 500), (6, 7, 3000), (6, 9, 12.45), (9, 2, 500.47), (1, 9, 777), (8, 4, 666), (4, 5, 6),
(1, 3, 5), (2, 4, 6);


-- 2 Задание


-- 1
-- Инструкция SELECT, использующая вложенные подзапросы с уровнем вложенности 3.

-- Выводит ФИО сотрудника, который провёл единственную операцию с фунтом (ищем по названию валюты)
SELECT P.fio
FROM rk2.Personal as P
WHERE P.personal_id = (SELECT O.personal_id
                       FROM rk2.Operations as O
                       WHERE O.exc_id = (SELECT ER.exc_id
                                         FROM rk2.ExchangeRate as ER JOIN rk2.currency as C on (ER.currency_id = C.currency_id)
                                         WHERE C.currency like 'Фунт'));

-- 2
-- Многострочная инструкция INSERT, выполняющая вставку в таблицу результирующего набора
-- данных вложенного подзапроса.

-- Добавляет сотрудника с другим ФИО и годом рождения, но с таким же постом, как у самого старого сотрудника
INSERT INTO rk2.Personal(fio, year_of_birthday, post) VALUES
('Шелия София Малхазовна', 2001, (SELECT P.post
                            FROM rk2.Personal as P
                            ORDER BY P.year_of_birthday ASC
                            LIMIT 1));

-- 3
-- Инструкция SELECT, использующая простое выражение CASE.

-- Вывожу по персоналу этап жизни, проверяя год рождения
SELECT P.personal_id, P.FIO,
       CASE
        WHEN P.year_of_birthday > 2000 THEN 'Студент'
        WHEN P.year_of_birthday BETWEEN 1990 and 2000 THEN 'В рассвете сил'
        WHEN P.year_of_birthday < 1990 THEN 'Старик'
      END as "Кто по жизни"
FROM rk2.Personal as P;

-- 3 задание

-- Создать хранимую процедуру с входным параметром, которая выводит имена и описания типа
-- объектов (только хранимых процедур и скалярных функций), в тексте которых на языке SQL
-- встречается строка, задаваемая параметром процедуры. Созданную хранимую процедуру протестировать.

create procedure rk2.FindObjects(name TEXT)
as'
DECLARE
    temp RECORD;
BEGIN
    FOR temp in
    SELECT routine_name, routine_type
    FROM information_schema.routines
    WHERE (routine_definition like ''%'' || name || ''%'')
    LOOP
        RAISE NOTICE ''Object: %'', temp;
    END LOOP;
END;
' LANGUAGE plpgsql;


-- Тестирование заключается в том, что ищем слова из только что созданной процедуры)
-- Работает!!!
call rk2.FindObjects('LOOP');
call rk2.FindObjects('RAISE NOTICE');