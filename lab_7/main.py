import json
import psycopg2
import os
import decimal
from sqlalchemy.engine import result
from tabulate import tabulate
from faker import Faker
from faker.providers import person
from faker.providers import date_time
from faker.providers import company
from random import randint
from random import choice

from sqlalchemy import create_engine, text, MetaData, func
from sqlalchemy.orm import mapper, Session, query

TABLE_MONTH = [[-7, 85], [-6, 82], [-1, 68], [7, 66], [13, 66], [17, 66], [20, 72], [18, 75], [12, 80], [6, 82], [0, 86], [-4, 86]]
TABLE_BRIGHT = [2, 1.8, 1.6, 1.2, 0.8, 0.4]
TABLE_STREETS = ["Автомагистраль", "Скоростная дорога", "Обычная дорога типа I",
                        "Обычная дорога типа II", "Обычная дорога типа III", "Обычная дорога типа IV"]
TABLE_LETTERS = ["А", "В", "Е", "К", "М", "Н", "О", "Р", "С", "Т", "У", "Х"]
TABLE_COLORS = ["белый", "чёрный", "серый", "синий", "пурпурный"]

connect_string = 'postgresql+psycopg2://bob:admin@localhost:5432/bmstu'
engine = create_engine(connect_string)
meta = MetaData()
meta.reflect(bind=engine, schema='crash')

# Link to object

# Подсчитать количество водителей, виноватых в авариях по региону
def count_driver_damage():
    region = input("Введите название региона: ")
    connection = Session(bind = engine)
    query = text('select count(*) '
                'from crash.region as R join crash.driver d on (R.region_id = d.region_id) '
                'join crash.details as Dt on (d.driver_id = Dt.driver_id) '  
                'where (Dt.is_blamed = true) and R.full_name = :region').bindparams(region=region)
    result = connection.execute(query).fetchone()[0]
    connection.close()
    print("Результат: ", result)

# По каждой автошколе вывести среднее освещение во время аварий, где их ученики были виноваты
def count_extent():
    connection = Session(bind = engine)
    query = text('SELECT D.autoschool, avg(A.light_extent) '
                'FROM crash.details as Dt join crash.driver as D on (Dt.driver_id = D.driver_id) '
                'JOIN crash.accident as A on (Dt.accident_id = A.accident_id) '  
                'WHERE Dt.is_blamed = true '
                'GROUP BY D.autoschool '
                'ORDER BY D.autoschool ASC ')
    result = connection.execute(query).fetchall()
    connection.close()
    print(tabulate(result, headers=['autoschool', 'avg(light extent)']))

# Вывести все машины, которые дороже заданной цены
def print_with_price():
    try:
        price = int(input("Введите цену для запроса: "))
    except:
        return
    connection = Session(bind = engine)
    query = text('SELECT C.car_model, C.car_type, C.transmission, C.fuel_type, C.price '
                 'FROM crash.car as C '
                 'WHERE C.price > :price;').bindparams(price = price)
    result = connection.execute(query).fetchall()
    connection.close()
    print(tabulate(result, headers=['car model', 'car type', 'transmission', 'fuel', 'price']))

def drivers_with_vnedo():

    connection = Session(bind = engine)
    query = text('SELECT DISTINCT C.car_model, Dt.accident_id, D.name, D.surname ' 
                 'FROM crash.details as Dt join crash.car as C on (Dt.car_id = C.car_id) '
                 'join crash.driver as D on (D.driver_id = Dt.driver_id) '
                 "WHERE  C.car_type like 'внедорожник' and D.name like 'Иван' ")
    result = connection.execute(query).fetchall()
    connection.close()
    print(tabulate(result, headers=['car model', 'accident_id', 'name', 'surname']))

def avg_mercedes():
    connection = Session(bind = engine)
    query = text('SELECT C.car_model, avg(D.alcohol_level) AS "Mean Alcohol_Level" ' 
                 'FROM crash.details as D join crash.car as C on (D.car_id = C.car_id) '
                 "WHERE D.is_blamed = True and C.car_model like '%Mercedes%' "
                 "GROUP BY C.car_model ")
    result = connection.execute(query).fetchall()
    connection.close()
    print(tabulate(result, headers=['car model', 'mean alcohol level']))

# Link to SQL

class Region(object):
    def __init__(self, region_id, name, region_type, full_name, federal_district, timezone):
        self.region_id = region_id
        self.name = name
        self.region_type = region_type
        self.full_name = full_name
        self.federal_district = federal_district
        self.timezone = timezone

    def to_tuple(self):
        return (self.region_id, self.name, self.region_type, self.full_name, self.federal_district, self.timezone)
    
    @staticmethod
    def __headers__():
        return ['region_id', 'name', 'region type', 'full name', 'federal district', 'timezone']

class Driver(object):
    def __init__(self, driver_id, passport_id, surname, name, middle_name, date_of_birth, sex, year_of_get_license, 
                 study_transmission, attemps_of_pass, autoschool, region_id):
        self.driver_id = driver_id
        self.passport_id = passport_id
        self.surname = surname
        self.name = name
        self.middle_name = middle_name
        self.date_of_birth = date_of_birth
        self.sex = sex
        self.year_of_get_license = year_of_get_license
        self.study_transmission = study_transmission
        self.attemps_of_pass = attemps_of_pass
        self.autoschool = autoschool
        self.region_id = region_id
    
    def to_tuple(self):
        return (self.driver_id, self.passport_id, self.surname, self.name, self.middle_name, self.date_of_birth,
                self.sex, self.year_of_get_license, self.study_transmission, self.attemps_of_pass, self.autoschool,
                self.region_id)
    
    @staticmethod
    def __headers__():
        return ['driver_id', 'passport', 'surname', 'name', 'middle name', 'date of birth', 'sex', 
                'year of get license', 'study transmission', 'attemps of pass', 'autoschool', 'region_id']

class Car(object):
    def __init__(self, car_id, car_number, car_model, car_type, transmission, drive_unit, engine_capacity, engine_volume,
                 fuel_type, car_color, price):
        self.car_id = car_id
        self.car_number = car_number
        self.car_model = car_model
        self.car_type = car_type
        self.transmission = transmission
        self.drive_unit = drive_unit
        self.engine_capacity = engine_capacity
        self.engine_volume = engine_volume
        self.fuel_type = fuel_type
        self.car_color = car_color
        self.price = price
    
    def to_tuple(self):
        return (self.car_id, self.car_number, self.car_model, self.car_type, self.transmission, self.drive_unit, 
                self.engine_capacity, self.engine_volume, self.fuel_type, self.car_color, self.price)
    
    @staticmethod
    def __headers__():
        return ['car_id', 'car number', 'car model', 'car type', 'transmission', 'drive unit', 
                'engine capacity', 'engine volume', 'fuel type', 'car color', 'price']

class Accident(object):
    def __init__(self, accident_id, accident_date, accident_time, number_members, road_type, road_cover_type,
                 temperature, light_extent, moisture_extent):
        self.accident_id = accident_id
        self.accident_date = accident_date
        self.accident_time = accident_time
        self.number_members = number_members
        self.road_type = road_type
        self.road_cover_type = road_cover_type
        self.temperature = temperature
        self.light_extent = light_extent
        self.moisture_extent = moisture_extent


    def to_tuple(self):
        return (self.accident_id, self.accident_date, self.accident_time, self.number_members, self.road_type,
                self.road_cover_type, self.temperature, self.light_extent, self.moisture_extent)
    
    @staticmethod
    def __headers__():
        return ['accident_id', 'accident date', 'accident time', 'number members', 'road type', 'road cover type', 
                'temperature', 'light extent', 'moisture extent']

class Details(object):

    def __init__(self, id, accident_id, car_id, driver_id, alcohol_level, is_blamed, is_exited_crash, 
                 driver_damage, n_passengers):
        self.id = id
        self.accident_id = accident_id
        self.car_id = car_id
        self.driver_id = driver_id
        self.alcohol_level = alcohol_level
        self.is_blamed = is_blamed
        self.is_exited_crash = is_exited_crash
        self.driver_damage = driver_damage
        self.n_passengers = n_passengers
    
    def to_tuple(self):
        return (self.id, self.accident_id, self.car_id, self.driver_id, self.alcohol_level, self.is_blamed, self.is_exited_crash,
                self.driver_damage, self.n_passengers)
    
    @staticmethod
    def __headers__():
        return ['id', 'accident_id', 'car_id', 'driver_id', 'alcohol_level', 'is blamed', 'is exited crash', 
                'driver damage', 'n passengers']

mapper(Region, meta.tables['crash.region'])
mapper(Driver, meta.tables['crash.driver'])
mapper(Car, meta.tables['crash.car'])
mapper(Accident, meta.tables['crash.accident'])
mapper(Details, meta.tables['crash.details'])

# Получить список машин заданной модели
# Однотабличная
def cars_model():
    model = str(input('Введите модель машины: '))
    connection = Session(bind=engine)
    cars = connection.query(Car).filter(text('car_model = :model')) \
        .params(model = model).all()[:10]
    connection.close()

    data = []
    for car in cars:
        data.append(car.to_tuple())

    print(tabulate(data, headers=Car.__headers__()))

# Вывести чёрные машины, которые участвовали в аварии при плохом освещении
# Многотабличная
def black_cars():
    connection = Session(bind=engine)
    cars = connection.query(Car, Details, Accident).filter(Car.car_id == Details.car_id).filter(Accident.accident_id == Details.accident_id)\
        .filter(Car.car_color == 'чёрный').filter(Accident.light_extent < 0.4).all()[:10]
    connection.close()
    
    data = []
    for car in cars:
        r = list(map(lambda c: c.to_tuple(), car))
        data.append(r[0][:len(r[0]) - 2])

    print(tabulate(data, headers=Car.__headers__()))

# Добавить инцидент
def add_accident():
    connection = Session(bind=engine)
    fake = Faker('ru_RU')
    fake.add_provider(date_time)
    date = fake.date_between(start_date = "-1y")
    time = fake.time()

    N = randint(2, 4)
    type_street = choice(TABLE_STREETS)
    type_cover = None
    if (type_street in ["Автомагистраль", "Скоростная дорога"]):
        type_cover = choice(["Бетон", "Асфальт"])
    else:
        type_cover = choice(["Бетон", "Асфальт", "Грунт", "Гравий"])
    
    month = date.month - 1
    hour = int(time[:2])
    global TABLE_MONTH
    global TABLE_BRIGHT

    temp = TABLE_MONTH[month][0] + randint(-5, 5)
    water = TABLE_MONTH[month][1] + randint(-10, 10)

    bright = TABLE_BRIGHT[TABLE_STREETS.index(type_street)] + randint(0, 4) / 10 - randint(0, 1) / 20 * abs(15 - hour)
    if (bright < 0.1):
        bright = randint(0, 1) / 10

    query = text('Select max(A.accident_id) '
                 'from crash.accident as A ')
    accident_id = int(connection.execute(query).fetchone()[0]) + 1

    connection.add(Accident(accident_id, date, time, N, type_street, type_cover, temp, bright, water))
    connection.commit()
    connection.close()

# Кикнуть водилу
def delete_driver():
    try:
        id = int(input("Введите ID водителя, которого хотите удалить: "))
    except:
        print("Ошибка ввода!")
        return
    connection = Session(bind=engine)
    try:
        query = connection.query(Driver).filter(text('driver_id = :id')).params(id = id).one()
    except:
        print("Таких водителей не найдено!")
        return
    print("Вы действительно хотите удалить этого водителя:")
    print(query.to_tuple())

    answer = input("Введите 1, если хотите его удалить: ")
    if (answer == '1'):
        connection.delete(query)
        connection.commit()
        print("Удаление прошло успешно!")
    else:
        print("Удаления не произошло!")
    connection.close()

# Изменить цену тачки
def change_car_price():

    try:
        car_id = int(input("Введите ID машину, цену которой вы хотите изменить: "))
    except:
        print("Ошибка ввода!")
        return
    connection = Session(bind=engine)
    try:
        query = connection.query(Car).filter(text('car_id = :car_id')).params(car_id = car_id).one()
    except:
        print("Таких машин не найдено!")
        return

    print("Найденная машина:")
    print(query.to_tuple())

    try:
        new_price = int(input("Введите новую цену для машины: "))
    except:
        print("Ввод неправильный!")
        return
    query.price = new_price
    connection.commit()
    print("Изменение прошло успешно!")
    connection.close()

def proc():
    connect= Session(bind=engine)
    results = connect.execute("Select * from crash.modelAveragePrice('SsangYong Rexton II')").fetchone()[0]
    print("Средняя цена: ", int(results))
    connect.close()

# LINQ to JSON
# Создать JSON
def create_drivers_json():
    connection = Session(bind=engine)
    query = "COPY (select row_to_json(C) from crash.driver as C) to '/home/prianechka/Education/BMSTU/DB/BMSTU-DB/lab_7/json/driver.json'"
    connection.execute(query)
    connection.close()

# Чтение из JSON документа
def read_from_json():
    connection = Session(bind=engine)
    query = '''
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
            data json
        )
        '''
    query2 = '''
        COPY json.temp (data) FROM '/home/prianechka/Education/BMSTU/DB/BMSTU-DB/lab_7/json/region.json';
        INSERT INTO json.Region(region_id, name, region_type, full_name, federal_district, timezone)
        SELECT (data->>'region_id')::INT, data->>'name', data->>'region_type', data->>'full_name', data->>'federal_district', (data->>'timezone')::INT FROM json.temp;

        SELECT * from json.region;
        '''
    tmp = connection.execute(query)
    regions = connection.execute(query2)

    print(tabulate(regions, headers=Region.__headers__()))
    connection.close()

# Обновление JSON документа
def update_json():

    connection = Session(bind=engine)
    query = '''
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
            data json
        )
        '''
    query2 = '''
        COPY json.temp (data) FROM '/home/prianechka/Education/BMSTU/DB/BMSTU-DB/lab_7/json/region.json';
        INSERT INTO json.Region(region_id, name, region_type, full_name, federal_district, timezone)
        SELECT (data->>'region_id')::INT, data->>'name', data->>'region_type', data->>'full_name', data->>'federal_district', (data->>'timezone')::INT FROM json.temp;

        UPDATE json.Region
        SET full_name = 'Евреи'
        WHERE region_id = 79;

        SELECT * from json.region;
        '''
    tmp = connection.execute(query)
    regions = connection.execute(query2)

    print(tabulate(regions, headers=Region.__headers__()))
    connection.close()


def print_menu():
    print('''
    1 - Подсчитать количество водителей, виноватых в авариях по региону
    2 - По каждой автошколе вывести среднее освещение во время аварий, где их ученики были виноваты
    3 - Вывести все машины, которые дороже заданной цены
    4 - Вывести все внедорожники, на которых попадали в аварии водители с именем Иван
    5 - Вывести среднее опьянение водителей по всем Мерседесам
    6 - Получить список машин заданной модели
    7 - Вывести чёрные машины, которые участвовали в аварии при плохом освещении
    8 - Добавить новый инцидент
    9 - Удалить водителя по ID
    10 - Изменить цену машину по её ID
    11 - Вывести среднюю цену по модели
    12 - Создать JSON файл с водителями
    13 - Прочитать из JSON все регионы
    14 - Обновить JSON с регионами (изменить Еврейская АО на Евреи)
    0 - выход
    ''')

execute = [
    lambda: print('Bye!'), count_driver_damage, count_extent, print_with_price, drivers_with_vnedo, avg_mercedes,
    cars_model, black_cars, add_accident, delete_driver, change_car_price, proc, create_drivers_json,
    read_from_json, update_json,
]
__exit = len(execute) - 1

if __name__ == '__main__':
    choice_ = -1
    while choice_ != 0:
        print_menu()
        choice_ = int(input('> '))
        execute[choice_]()