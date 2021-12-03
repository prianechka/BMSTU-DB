import psycopg2
import os
from tabulate import tabulate

connection = psycopg2.connect(user="bob",
                password="admin",
                host="localhost",
                port="5432",
                database="bmstu")

cur = connection.cursor()

# Подсчитать среднее опьянение среди всех участников аварий
def task_1():
    try:
        cur.execute('''
                SELECT AVG(Dt.alcohol_level) FROM crash.details as Dt;
            ''')
        headers = [desc[0] for desc in cur.description]
        print(tabulate(cur.fetchall(), headers = headers))
        cur.close()
    except:
        connection.rollback()
    else:
        connection.commit()


# По каждой автошколе вывести среднее освещение во время аварий, где их ученики были виноваты
def task_2():
    try:
        cur.execute('''
                        SELECT D.autoschool, avg(A.light_extent)
                        FROM crash.details as Dt join crash.driver as D on (Dt.driver_id = D.driver_id)
                        JOIN crash.accident as A on (Dt.accident_id = A.accident_id)
                        WHERE Dt.is_blamed = true
                        GROUP BY D.autoschool
                        ORDER BY D.autoschool ASC;
            ''')
        headers = [desc[0] for desc in cur.description]
        print(tabulate(cur.fetchall(), headers = headers))
        cur.close()
    except:
        connection.rollback()
    else:
        connection.commit()


# По каждой модели машин, которая участвовала в аварии 6 или 7 раз, вывести стоимость каждой машины, которая участвовала в аварии
def task_3():
    try:
        cur.execute('''
            WITH Model(car_model, cnt) AS 
            (
                SELECT C.car_model, count(*) as Cnt
                FROM crash.car as C JOIN crash.details as Dt on (C.car_id = Dt.car_id)
                GROUP BY C.car_model
            )
            SELECT C.car_number, C.car_type, C.car_model, C.price, 
                    ROUND(AVG(C.price) OVER(PARTITION BY C.car_model), 2) as AVGPRICE
            FROM crash.car as C JOIN Model as M on (C.car_model = M.car_model)
            WHERE M.cnt > 5 and M.cnt < 8;
            ''')
        headers = [desc[0] for desc in cur.description]
        print(tabulate(cur.fetchall(), headers = headers))
        cur.close()
    except:
        connection.rollback()
    else:
        connection.commit()

# Вывести все таблицы в текущей БД и текущей схеме
def task_4():
    try:
        cur.execute('''
            SELECT table_catalog as db, table_schema as schema, table_name as table 
            from information_schema.tables where table_catalog = 'bmstu' and table_schema = 'crash';
            ''')
        headers = [desc[0] for desc in cur.description]
        print(tabulate(cur.fetchall(), headers = headers))
        cur.close()
    except:
        connection.rollback()
    else:
        connection.commit()

# По каждой модели машины выводит среднюю стоимость
def task_5():
    try:
        cur.execute('''
            select DISTINCT C.car_model, crash.modelAveragePrice(C.car_model) from crash.car as C;
            ''')
        headers = [desc[0] for desc in cur.description]
        print(tabulate(cur.fetchall(), headers = headers))
        cur.close()
    except:
        connection.rollback()
    else:
        connection.commit()

# Вывести все машины, которые дороже заданной цены
def task_6():
    try:
        X = int(input("Введите параметр запроса - цену (целое число > 0), по которой искать машины: "))
        string = f"SELECT * FROM crash.print_cars_with_big_price({X})"
        cur.execute(string)
        headers = [desc[0] for desc in cur.description]
        print(tabulate(cur.fetchall(), headers = headers))
        cur.close()
    except ValueError:
        print("Вы неправильно ввели целое число!")
    except:
        connection.rollback()
    else:
        connection.commit()

def task_7():
    try:
        region = input("Введите параметр запроса - регион, по которому делать запрос: ")
        string = f"call crash.Defend('{region}')"
        connection = psycopg2.connect(user="bob",
                password="admin",
                host="localhost",
                port="5432",
                database="bmstu")
        cur = connection.cursor()
        cur.execute(string)
        array = connection.notices
        print("Регион: {}".format(region))
        print("-" * 20)
        for i in range(len(array) - 1):
            print(array[i])
        cur.close()
    except:
        connection.rollback()
    else:
        connection.commit()

# Выводит название текущей базы данных
def task_8():
    try:
        cur.execute('''
            select * from current_catalog;
        ''')
        headers = [desc[0] for desc in cur.description]
        print(tabulate(cur.fetchall(), headers = headers))
        cur.close()
    except:
        connection.rollback()
    else:
        connection.commit()


# Создаёт таблицу из евреев, которые попадали в аварии
def task_9():
    try:
        cur.execute('''
            CREATE TABLE if not exists crash.Jewish
            (
                person_id serial primary key,
                id_from_table INT,
                surname TEXT,
                name TEXT,
                year_of_get_license INT,
                foreign key(id_from_table) references crash.driver(driver_id)
            );
            ''')
        cur.close()
    except:
        connection.rollback()
    else:
        connection.commit()

# Добавляет реальное значение
def task_10():
    try:
        cur.execute('''
        INSERT INTO crash.Jewish(id_from_table, surname, name, year_of_get_license)
        select D.driver_id, D.surname, D.name, D.year_of_get_license
        from crash.driver as D join crash.region as R on (D.region_id = R.region_id)
            join crash.details as Dt on (D.driver_id = Dt.driver_id)
        where R.full_name = 'Еврейская Аобласть' and Dt.is_blamed = true;
            ''')
        cur.execute('''
        select * from crash.jewish
        ''')
        headers = [desc[0] for desc in cur.description]
        print(tabulate(cur.fetchall(), headers = headers))
        cur.close()
    except:
        connection.rollback()
    else:
        connection.commit()

def task_defend():
    try:
        n_pas = int(input("Введите параметр запроса - количество пассажиров: "))
        string = f"SELECT count(distinct d.accident_id) FROM crash.details as d WHERE d.n_passengers = {n_pas}"
        cur.execute(string)
        headers = [desc[0] for desc in cur.description]
        print(tabulate(cur.fetchall(), headers = headers))
        cur.close()
    except:
        connection.rollback()
    else:
        connection.commit()

def print_menu():
    print ('''
1.  Выполнить скалярный запрос: 
    Подсчитать среднее опьянение среди всех участников аварий \n\

2.  Выполнить запрос с несколькими соединениями (JOIN) \n\
    По каждой автошколе вывести среднее освещение во время аварий, где их ученики были виноваты

3.  Выполнить запрос с ОТВ(CTE) и оконными функциями \n\
    По каждой модели машин, которая участвовала в аварии 6 или 7 раз, вывести стоимость каждой машины, которая участвовала в аварии

4.  Выполнить запрос к метаданным \n\
    Вывести все таблицы в текущей БД и текущей схеме

5.  Вызвать скалярную функцию (написанную в третьей лабораторной работе) \n\
    По каждой модели машины вывести среднюю стоимость

6.  Вызвать многооператорную или табличную функцию (написанную в третьей лабораторной работе) \n\
    Вывести все машины, которые дороже заданной цены

7.  Вызвать хранимую процедуру (написанную в третьей лабораторной работе) \n\
    По названию региона вывести сводку количества виновных в авариях по автошколе

8.  Вызвать системную функцию или процедуру \n\
    Вывести название текущей базы данных

9.  Создать таблицу в базе данных, соответствующую тематике БД \n\
    Создать таблицу из евреев, которые попадали в аварии

10. Выполнить вставку данных в созданную таблицу с использованием инструкции INSERT или COPY\n\
    Добавить в таблицу значения

11. Защита
    Вывести количество аварий, в которых хотя бы в одной машине было заданное количество пассажиров

12. Завершить работу\n"
''')

def task_exit():
    cur.execute('''drop table crash.jewish''')
    connection.commit()
    cur.close()

tasks = [
    '__empty__',
    task_1, task_2, task_3, task_4, task_5, 
    task_6, task_7, task_8, task_9, task_10, task_defend,
    task_exit
]

__exit = len(tasks) - 1

if __name__ == '__main__':
    choice = -1
    while choice != __exit:
        print_menu()
        try:
            choice = int(input('> '))
            tasks[choice]()
            cur = connection.cursor()
        except:
            pass
    connection.close()