-- Инструкция SELECT, использующая предикат сравнения.
-- Вывести все машины с мощностью двигателя меньше 300 и ценой больше миллиона
SELECT C.car_model, C.price, C.engine_capacity
FROM crash.car as C
WHERE C.price > 1000000 and C.engine_capacity < 300

-- 2. Инструкция SELECT, использующая предикат BETWEEN.
-- Вывести все аварии, которые произошли за лето
SELECT A.accident_id, A.accident_date
FROM crash.accident as A
WHERE A.accident_date BETWEEN '2021-06-01' AND '2021-08-31'

-- 3. Инструкция SELECT, использующая предикат LIKE.
-- Вывести все внедорожники, в которые попадал водители с именем Иван

SELECT DISTINCT C.car_model, Dt.accident_id, D.name, D.surname
FROM crash.details as Dt join crash.car as C on (Dt.car_id = C.car_id)
                        join crash.driver as D on (D.driver_id = Dt.driver_id)
WHERE  C.car_type like 'внедорожник' and D.name like 'Иван'

-- 4. Инструкция SELECT, использующая предикат IN с вложенным подзапросом.
-- Вывести всех водителей, которые попадали в аварию при температуре меньше 5 градусов

SELECT DISTINCT Dr.name, Dr.surname
FROM crash.details as Dt join crash.driver as Dr on (Dt.driver_id = Dr.driver_id)
WHERE Dt.accident_id in (SELECT A.accident_id
                         FROM crash.accident as A
                         WHERE A.temperature < 5)

-- 5. Инструкция SELECT, использующая предикат EXISTS с вложенным подзапросом.
-- Вывести все модели машин, на которых были виновными в аварии

SELECT DISTINCT CC.car_model
FROM crash.car as Cc
WHERE EXISTS (SELECT *
              FROM crash.details as Dt join crash.car as C on (Dt.car_id = C.car_id)
              WHERE Dt.is_blamed = True and Cc.car_id = C.car_id)

-- 6. Инструкция SELECT, использующая предикат сравнения с квантором.
-- Вывести машины, которые стоят дороже чем все, на которых попадали в аварию и были виноваты
SELECT Cc.price, Cc.car_model
FROM crash.car as Cc
WHERE Cc.price > ALL (SELECT C.price
                     FROM crash.details as Dt join crash.car as C on (Dt.car_id = C.car_id)
                     WHERE Dt.is_blamed = True)

-- 7. Инструкция SELECT, использующая агрегатные функции в выражениях столбцов
-- Вывести среднее опьянение водителей для каждой модели мерседеса, которые были виновны в аварии
SELECT C.car_model, avg(D.alcohol_level) AS "Mean Alcohol_Level"
FROM crash.details as D join crash.car as C on (D.car_id = C.car_id)
WHERE D.is_blamed = True and C.car_model like '%Mercedes%'
GROUP BY C.car_model

-- 8. Инструкция SELECT, использующая скалярные подзапросы в выражениях столбцов.
-- Вывести цену, среднюю цену и количество аварий с этой машиной для каждой модели ниссана
SELECT DISTINCT C.car_id, C.car_model, C.price, (SELECT AVG(CC.price)
                              FROM crash.car as CC
                              WHERE CC.car_model = C.car_model) as "AVERAGE PRICE",
                            (SELECT count(Dt.accident_id)
                             FROM crash.details as Dt join crash.car as Ccc on (Dt.car_id = C.car_id)
                             WHERE Ccc.car_id = C.car_id) as "COUNT CRASHES"
FROM crash.car as C
WHERE C.car_model like '%Nissan%'

-- 9. Инструкция SELECT, использующая простое выражение CASE.
-- Вывести времена года, когда случилась авария, и виновный получил тяжёлые повреждения

SELECT Dt.accident_id, A.accident_date,
       CASE
        WHEN A.accident_date BETWEEN '2021-01-01' and '2021-02-28' THEN 'Зима'
        WHEN A.accident_date BETWEEN '2021-03-01' and '2021-05-31' THEN 'Весна'
        WHEN A.accident_date BETWEEN '2021-06-01' and '2021-08-31' THEN 'Лето'
        WHEN A.accident_date BETWEEN '2021-09-01' and '2021-11-30' THEN 'Осень'
      END as "Время года"
FROM crash.details as Dt join crash.accident as A on (Dt.accident_id = A.accident_id)
WHERE Dt.is_blamed = True and Dt.driver_damage like '%Тяжёлые%' and A.accident_date BETWEEN '2021-01-01' and '2021-11-30'

-- 10. Инструкция SELECT, использующая поисковое выражение CASE.
-- Вывести для каждого участника аварии степень опьянения (аварии только с 4 людьми и бетонным покрытием)
SELECT Dt.accident_id, D.name, D.surname, Dt.alcohol_level,
       CASE
            WHEN Dt.alcohol_level < 0.3 THEN 'Не было влияния алкоголя'
            WHEN Dt.alcohol_level < 0.5 THEN 'Незначительное влияние алкоголя'
            WHEN Dt.alcohol_level < 1.5 THEN 'Лёгкое опьянение'
            WHEN Dt.alcohol_level < 2.5 THEN 'Среднее опьянение'
            WHEN Dt.alcohol_level < 3.0 THEN 'Сильное опьянение'
            WHEN Dt.alcohol_level < 5 THEN 'Тяжёлое опьянение'
     END as "Степень опьянения"
FROM crash.details as Dt JOIN crash.accident as A on (A.accident_id = Dt.accident_id)
        JOIN crash.driver as D on (Dt.driver_id = D.driver_id)
WHERE A.number_members = 4 and A.road_cover_type like 'Бетон'

-- 11. Создание новой временной локальной таблицы из результирующего набора данных инструкции SELECT.
-- Создание таблицы, гле для каждого водителя хранится название региона, где он получал права и сколько раз попадал в аварию

SELECT D.driver_id, D.name, D.surname, R.full_name, (SELECT count(*)
                                                     FROM crash.details as Dt
                                                     WHERE Dt.driver_id = D.driver_id) as "Кол-во Аварий"
INTO crash.stats
FROM crash.driver as D join crash.region as R on (D.region_id = R.region_id)
ORDER BY  "Кол-во Аварий" DESC

-- 12. Инструкция SELECT, использующая вложенные коррелированные подзапросы в качестве производных таблиц в предложении FROM
-- Вывести регион водителя-мужчины, который больше всех попадал в аварию и водителя-женщину с таким же требованием
-- но с Рязанской области
SELECT R.full_name, D.sex, D.name, D.surname, My.cnt
FROM crash.driver as D JOIN crash.region as R on (D.region_id = R.region_id)
    JOIN
    (SELECT Dt.driver_id, count(Dt.driver_id) as cnt
    FROM crash.details as Dt JOIN crash.driver as Ddr on (Dt.driver_id = Ddr.driver_id)
    WHERE Ddr.sex = 'М'
    GROUP BY Dt.driver_id
    ORDER BY cnt DESC
    limit 1) as My
    on (My.driver_id = D.driver_id)
UNION
SELECT R.full_name, D.sex, D.name, D.surname, My.cnt
FROM crash.driver as D JOIN crash.region as R on (D.region_id = R.region_id)
    JOIN
    (SELECT Dt.driver_id, count(Dt.driver_id) as cnt
    FROM crash.details as Dt JOIN crash.driver as Ddr on (Dt.driver_id = Ddr.driver_id)
    WHERE Ddr.sex = 'Ж'
    GROUP BY Dt.driver_id
    ORDER BY cnt DESC
    limit 1) as My
    on (My.driver_id = D.driver_id)

-- 13. Инструкция SELECT, использующая вложенные подзапросы с уровнем вложенности 3.
-- Вывести самого старого человека, который попадал при минимальной температуре аварии
SELECT D.name, D.surname ,D.date_of_birth, R.full_name
FROM crash.driver as D JOIN crash.region as R on (D.region_id = R.region_id)
WHERE D.driver_id = (SELECT Dd.driver_id
                     FROM crash.driver as Dd JOIN crash.details as Dt on (Dd.driver_id = Dt.driver_id)
                     WHERE Dt.accident_id = (SELECT Aa.accident_id
                                              FROM crash.accident as Aa
                                              ORDER BY AA.temperature
                                              limit 1)
order by Dd.date_of_birth
limit 1)

-- 14. Инструкция SELECT, консолидирующая данные с помощью предложения GROUP BY, но без предложения HAVING.
-- Для каждого региона вывести количество виновных в авариях

SELECT DISTINCT R.region_id, R.full_name, count(R.region_id)
FROM crash.driver as D JOIN crash.region as R on (D.region_id = R.region_id)
        JOIN crash.details as Dt on (D.driver_id = Dt.driver_id)
GROUP BY R.region_id

-- 15.Инструкция SELECT, консолидирующая данные с помощью предложения GROUP BY и предложения HAVING.
-- Для автошкол с количеством участнков аварий > 30 вывести среднее опьянение водителей

SELECT D.autoschool, count(D.autoschool), cast(round(avg(Dt.alcohol_level), 2) as numeric (5, 2))
FROM crash.driver as D JOIN crash.details as Dt on (D.driver_id = Dt.driver_id)
GROUP BY D.autoschool
HAVING count(D.autoschool) > 30

-- 16. Однострочная инструкция INSERT, выполняющая вставку в таблицу одной строки значение
INSERT INTO crash.driver(driver_id, passport_id, surname, name, middle_name, date_of_birth, sex, year_of_get_license, study_transmission, attemps_of_pass, autoschool, region_id)
VALUES (20001, '0415286283', 'Прянишников', 'Александр', 'Николаевич', '2001-05-28', 'М', 2020, 'механика', 1, 'Азбука вождения', 24)

-- 17. Многострочная инструкция INSERT, выполняющая вставку в таблицу результирующего набора данных вложенного подзапроса.
INSERT INTO crash.car(car_id, car_number, car_model, car_type, transmission, drive_unit, engine_capacity, engine_volume, fuel_type, car_color, price)
SELECT 14894, (SELECT C.car_number
               FROM crash.car as C
               WHERE C.car_model like '%LADA%'
               ORDER BY C.price DESC
               limit 1), 'Volkswagen Passat B7', 'седан', 'автомат', 'передний', 162, 1.9, 'бензин', 'белый', 4200000;

SELECT *
FROM crash.car as C
WHERE C.price = 4200000;

-- 18. Простая инструкция UPDATE.
-- Изменить значение цены для Лады из прошлого задания
UPDATE crash.car as C
SET price = 4200000
WHERE car_number = 'С835ХВ_68';

-- 19. Инструкция UPDATE со скалярным подзапросом в предложении SET.
-- Изменить для всех пассатов цену на среднюю для всех мерседесов
UPDATE crash.car
SET price = (SELECT avg(Cc.price)
            FROM crash.car as Cc
            WHERE Cc.car_model like '%Mercedes%')
WHERE car_model = 'Volkswagen Passat B7';

-- 20. Простая инструкция DELETE.
DELETE FROM crash.car
WHERE price = 4200000;

-- 21. Инструкция DELETE с вложенным коррелированным подзапросом в предложении WHERE.
-- Удалить все машины, цена которых равна средней по мерседесам и являются пассатом

DELETE FROM crash.car
WHERE price = (SELECT avg(C.price)
               FROM crash.car as C
               WHERE C.car_model like '%Mercedec%') and car_model = 'Volkswagen Passat B7';

-- 22. Инструкция SELECT, использующая простое обобщенное табличное выражение
-- Вывести степень опьянения водителей, которые покинули аварию, а также дорогу аварии
WITH MyTemp(accident_id, road_type) AS
    (SELECT accident_id, road_type
     FROM crash.accident AS A
     WHERE A.temperature < 0
    )
SELECT Dt.accident_id, Dt.alcohol_level, MT.road_type
FROM crash.details as Dt JOIN MyTemp as MT on (Dt.accident_id = MT.accident_id)
WHERE Dt.is_exited_crash = True;

-- 23. Инструкция SELECT, использующая рекурсивное обобщенное табличное выражение.

-- Вывести пирамиду сотрудников

DROP TABLE IF EXISTS crash.ex23
CREATE TABLE crash.ex23
(
    EmployeeID int NOT NULL,
    FirstName text NOT NULL,
    LastName text NOT NULL,
    Title text NOT NULL,
    ManagerID int NULL,
    CONSTRAINT PK_EmployeeID PRIMARY KEY (EmployeeID)
)

INSERT INTO crash.ex23
VALUES (1, N'Леонид', N'Федун', N'Президент',NULL),
(2, N'Дмитрий', N'Попов', N'Спортивный директор',1),
(3, N'Нариман', N'Акавов', N'Главный скаут',2),
(4, N'Александр', N'Прянишников', N'Аналитик',3),
(5, N'Иван', N'Максимов', N'Скаут',4),
(6, N'Шамиль', N'Газизов', N'Генеральный директор',1),
(7, N'Станислав', N'Меркис', N'Менеджер по работе с общественностью',6),
(8, N'Мария', N'Кудашкина', N'Главный бухгалтер',6)

WITH RECURSIVE ANS (ManagerID, EmployeeID, Title, Level) AS
(
    SELECT ManagerID, EmployeeID, Title, 0 AS Level FROM crash.ex23
    WHERE ManagerID IS NULL
    UNION ALL
    SELECT tb.ManagerID, tb.EmployeeID, tb.Title, d.Level + 1 FROM crash.ex23  AS tb INNER JOIN ANS AS d
    ON tb.ManagerID = d.EmployeeID
)
SELECT ManagerID, EmployeeID, Title, Level FROM ANS;

-- 24. Оконные функции. Использование конструкций MIN/MAX/AVG OVER()
-- По каждой машине добавить минимальную, среднюю и максимальную цену модели
SELECT C.car_number, C.car_type, C.car_model, C.price, MIN(C.price) OVER(PARTITION BY C.car_model) as MinPrice,
                                MAX(C.price) OVER(PARTITION BY C.car_model) as MaxPrice,
                                AVG(C.price) OVER(PARTITION BY C.car_model) as MinPrice
FROM crash.car as C

-- 25. Оконные фнкции для устранения дублей
-- По каждой машине добавить минимальную цену модели
SELECT row_number() over (PARTITION BY C.car_model) as num, C.car_model, MIN(C.price) OVER(PARTITION BY C.car_model) as MinPrice
FROM crash.car as C