DROP SCHEMA IF EXISTS rk3 CASCADE ;
CREATE SCHEMA rk3;

CREATE TABLE rk3.Employee
(
    id SERIAL PRIMARY KEY,
    FIO TEXT,
    date_of_birth DATE,
    department TEXT
);

CREATE TABLE rk3.Times
(
	employer_id INT,
	currents_date DATE,
	week_day TEXT,
	time_action TIME,
	type INT,
	FOREIGN KEY (employer_id) references rk3.Employee(id) on delete cascade
);

insert into rk3.Employee(fio, date_of_birth, department) values
    ('Александр Прянишников', '28-05-2001', 'Tinkoff'),
    ('София Шелия', '15-04-2001', 'Mail'),
    ('Татьяна Солнцева', '17-11-2001', 'Ситимобил'),
    ('Артём Богаченко', '13-09-1999', 'Arrival'),
    ('Андрей Тонкоштан', '13-11-2001', 'Кайф'),
    ('Илья Муравьёв', '15-11-2001', 'Бухгалтерия');

insert into rk3.Times(employer_id, currents_date, week_day, time_action, type) values
    (1, '18-12-2021', 'Суббота', '9:20', 1),
    (1, '18-12-2021', 'Суббота', '9:40', 2),
    (1, '18-12-2021', 'Суббота', '11:00', 1),
    (1, '18-12-2021', 'Суббота', '18:00', 2),

    (2, '18-12-2021', 'Суббота', '9:01', 1),
    (2, '18-12-2021', 'Суббота', '9:40', 2),
    (2, '18-12-2021', 'Суббота', '11:00', 1),
    (2, '18-12-2021', 'Суббота', '18:00', 2),

    (6, '18-12-2021', 'Суббота', '7:00', 1),
    (6, '18-12-2021', 'Суббота', '21:00', 2),

    (2, '20-12-2021', 'Понедельник', '9:00', 1),
    (2, '20-12-2021', 'Понедельник', '18:00', 2),

    (3, '20-12-2021', 'Понедельник', '10:00', 1),
    (3, '20-12-2021', 'Понедельник', '17:00', 2),

    (4, '20-12-2021', 'Понедельник', '9:00', 1),
    (4, '20-12-2021', 'Понедельник', '20:00', 2),

    (5, '21-12-2021', 'Вторник', '10:10', 1),
    (5, '21-12-2021', 'Вторник', '10:30', 2),
    (5, '21-12-2021', 'Вторник', '11:00', 1),
    (5, '21-12-2021', 'Вторник', '12:00', 2);

-- Написать табличную функцию, возвращающую сотрудников, не пришедших сегодня на
-- работу. «Сегодня» необходимо вводить в качестве параметра.
CREATE OR REPLACE FUNCTION find_people(day DATE)
RETURNS TABLE
    (
        ID INT,
        FIO TEXT
    )
AS
    $$
    BEGIN
    RETURN QUERY
    SELECT E.FIO, E.id
    FROM rk3.Employee as E
    WHERE E.id NOT IN (
                        SELECT DISTINCT E.id
                        FROM rk3.Employee as E JOIN rk3.Times as T ON (E.id = T.employer_id)
                        WHERE T.currents_date = day AND T.type = 1
                      );
END;
$$ LANGUAGE PLPGSQL;

-- Чекаем по специально выбранному днж
select * from find_people('18-12-2021');

-- Найти сотрудников, опоздавших сегодня меньше чем на 5 минут
-- Нужно проверить самое первое появление сотрудника в течении дня, поэтому без min не обойтись

-- Ответ совпал с тем, что лежит в базе
SELECT F.employer_id
FROM (SELECT T.employer_id, min(T.time_action) as "min_time"
      FROM rk3.Times as T
      WHERE T.currents_date = current_date and (T.type = 1)
      GROUP BY T.employer_id) as F
WHERE F."min_time" BETWEEN '9:01' and '9:04';

-- Найти сотрудников, которые выходили больше чем на 10 минут в течение дня
-- Всё работает
SELECT DISTINCT F.employer_id
FROM (SELECT T.employer_id, T.time_action, T.type, LEAD(T.time_action) OVER (PARTITION BY T.employer_id) - T.time_action as "m"
      FROM rk3.Times as T) as F
WHERE F."m" is not null and F.type = 2 and F."m" < '0 month 0 days 0 hours -10 minutes'::INTERVAL;



-- Найти сотрудников бухгалтерии, приходящих на работу раньше 8:00
-- Тоже совпало, добавил специально для проверки одну запись
SELECT F.employer_id
FROM (SELECT T.employer_id, min(T.time_action) as "min_time"
      FROM rk3.Times as T
      WHERE T.type = 1
      GROUP BY T.employer_id) as F JOIN rk3.Employee as E on (F.employer_id = E.id)
WHERE F."min_time" < '8:00' and E.department = 'Бухгалтерия';