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