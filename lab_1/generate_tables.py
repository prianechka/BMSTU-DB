from typing import Text
import pandas as pd
from faker import Faker
from faker.providers import person
from faker.providers import date_time
from faker.providers import company
from random import randint
from random import choice
import numpy as np
from pandas.io.pytables import dropna_doc
from scipy import stats
import codecs
import requests
import bs4
import unicodedata

TABLE_MONTH = [[-7, 85], [-6, 82], [-1, 68], [7, 66], [13, 66], [17, 66], [20, 72], [18, 75], [12, 80], [6, 82], [0, 86], [-4, 86]]
TABLE_BRIGHT = [2, 1.8, 1.6, 1.2, 0.8, 0.4]
TABLE_STREETS = ["Автомагистраль", "Скоростная дорога", "Обычная дорога типа I",
                        "Обычная дорога типа II", "Обычная дорога типа III", "Обычная дорога типа IV"]
TABLE_LETTERS = ["А", "В", "Е", "К", "М", "Н", "О", "Р", "С", "Т", "У", "Х"]
TABLE_COLORS = ["белый", "чёрный", "серый", "синий", "пурпурный"]

def generate_regions():
    region_data = pd.read_csv("inc/region.csv", sep = ",")[["name", "type", "name_with_type", "federal_district", "kladr_id", "timezone"]]
    region_data["kladr_id"] //= 100000000000
    region_data["name_with_type"] = region_data["name_with_type"].str.replace("Респ", "Республика")
    region_data["name_with_type"] = region_data["name_with_type"].str.replace("обл", "область")
    region_data["name_with_type"] = region_data["name_with_type"].str.replace("г ", "")
    return region_data

def generate_school():
    f = codecs.open("inc/base_schools.txt", "r", "utf_8_sig")
    text = f.read()
    school_list = text.split("\r\n")
    return school_list

def generate_person():
    fake = Faker('ru_RU')
    fake.add_provider(person)
    fake.add_provider(date_time)
    fake.add_provider(company)
    sex = choice(['М', 'Ж'])
    number = ''.join((list(np.random.choice(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'], size = 10))))
    if (sex == 'М'):
        name = fake.first_name_male()
        last_name = fake.last_name_male()
        middle_name = fake.middle_name_male()
    else:
        name = fake.first_name_female()
        last_name = fake.last_name_female()
        middle_name = fake.middle_name_female()
    date_of_birth = fake.date_of_birth(minimum_age = 18, maximum_age = 70)
    age = 2021 - date_of_birth.year
    year = date_of_birth.year + randint(18, age)
    KP = choice(["А", "M"])
    try_value = randint(1, 5)
    return number, last_name, name, middle_name, date_of_birth, sex, year, KP, try_value

def generate_table_of_persons():
    region_data = generate_regions()
    school_list = generate_school()
    table = pd.DataFrame(columns=["Номер паспорта", "Фамилия", "Имя", "Отчество", "Дата рождения", "Пол", "Год получения прав", "КП во время учёбы", 
                              "Количество попыток сдачи эказмена", "Название автошколы","Код региона получения прав"])
    for i in range(20000):
        number, last_name, name, middle_name, date_of_birth, sex, year, KP, try_value = generate_person()
        region = region_data.loc[randint(0, 85)]["kladr_id"]
        name_school = choice(school_list)
        table.loc[i] = [number, last_name, name, middle_name, date_of_birth, sex, year, KP, try_value, name_school, region]
    return table

def generate_cars():
    main_url = "https://auto.ru/moskva/cars/all/"
    result = []
    for j in range(500):
        url = main_url + "?page=".format(j + 1)
        responce = requests.get(url)
        html = responce.content
        soup = bs4.BeautifulSoup(html,'html.parser')
        name_auto = soup.findAll(lambda tag: tag.name == "h3")
        auto = soup.findAll(lambda tag: tag.name == 'div' and tag.get('class') == ["ListingItemTechSummaryDesktop__cell"])
        N = len(auto)
        list_autos = []
        i = 0
        while (i + 5) < N:
            lst = []
            lst.extend(unicodedata.normalize("NFKC", auto[i].text.strip()).split(" / "))
            lst.append(unicodedata.normalize("NFKC", auto[i + 1].text))
            lst.append(unicodedata.normalize("NFKC", auto[i + 2].text))
            lst.append(unicodedata.normalize("NFKC", auto[i + 3].text))
            lst.append(unicodedata.normalize("NFKC", auto[i + 4].text))
            if (lst[len(lst) - 1] not in TABLE_COLORS):
                lst[6] = choice(TABLE_COLORS)
            lst[0] = str(lst[0].split()[0])
            lst[1] = str(lst[1].split()[0])
            lst[4] = str(lst[4].split()[0])
            if ("опции" in unicodedata.normalize("NFKC", auto[i + 5].text) or
                "опций" in unicodedata.normalize("NFKC", auto[i + 5].text) or
                "опция" in unicodedata.normalize("NFKC", auto[i + 5].text)):
                i += 1
            i += 5
            list_autos.append(lst)
        for i in range(len(list_autos)):
            list_autos[i].append(name_auto[i].a.text)
            number = choice(TABLE_LETTERS) + str(randint(0, 9)) + str(randint(0, 9)) + str(randint(0, 9)) + choice(TABLE_LETTERS) + \
                     choice(TABLE_LETTERS) + "_" + str(randint(0, 9)) + str(randint(0, 9))
            list_autos[i].append(number)
        result.extend(list_autos)
    return result

def generate_table_of_cars():
    auto = generate_cars()
    print(len(auto))
    date_cars = pd.DataFrame(columns=["Номер машины", "Название машины", "Тип машины", "Коробка передач", "Привод", "Мощность двигателя (в л.с.)", "Объём двигателя (в литрах)", 
                                      "Тип топлива", "Цвет"])
    for i in range(len(list(auto))):
        car = auto[i]
        date_cars.loc[i] = [car[8], car[7], car[4], car[3], car[5], car[1], car[0], car[2], car[6]]
    return date_cars

def generate_crash():   
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

    return date, time, N, type_street, type_cover, temp, bright, water

def generate_table_of_crash():
    data_crash = pd.DataFrame(columns=["Дата", "Время", "Количество участников", "Тип дороги", "Тип покрытия дороги", "Температура воздуха", 
                                        "Показатель освещённости", "Процент влажности дороги"])
    
    for i in range(1000):
        data_crash.loc[i] = generate_crash()
    
    return data_crash

def generate_table_of_details(persons, autos, crash):
    details = pd.DataFrame(columns=["person_id", "auto_id", "crash_id", "Уровень алкоголя в крови", "Степень повреждённости машины", 
                                    "Виновный в аварии", "Степень повреждений водителя", "Количество пассажиров"])
    N_person = persons.shape[0]
    N_auto = persons.shape[1]
    for i in range(crash.shape[0]):
        crash_id = i
        N = crash.loc[i]["Количество участников"]
        id = list(np.random.choice(range(N_person), size = N, replace= False))
        autos_id = list(np.random.choice(range(N_auto), size = N, replace= False))
        blame = choice(range(1, N + 1))
        for j in range(N):
            person_id = persons.loc[id[j]]["Номер паспорта"]
            auto_id = autos.loc[autos_id[j]]["Номер машины"]
            rv = stats.norm(loc = 0, scale = 0.6)
            promile = abs(rv.rvs(size = 1)[0])
            if (promile < 0.15):
              promile = 0
            if (blame - 1 == j):
                blame_id = 'Да'
            else:
                blame_id = "Нет"
            N_pas = randint(0, 3)
            rv1 = stats.norm(loc = 0, scale = 0.2)
            car_extent = abs(rv.rvs(size = 1)[0])
            person_extent = abs(rv.rvs(size = 1)[0])
            if (car_extent > 1):
              car_extent = randint(0, 1) / 100
            if (person_extent > 1):
              person_extent = randint(0, 1) / 100
            details.loc[details.shape[0]] = [person_id, auto_id, crash_id, promile, car_extent, blame_id, person_extent, N_pas]
    return details

table_regions = generate_regions()
table_persons = generate_table_of_persons()
table_autos = generate_table_of_cars()
table_crash = generate_table_of_crash()
table_details = generate_table_of_details(table_persons, table_autos, table_crash)
table_details.to_csv("data/table_details.csv", sep=",")
table_persons.to_csv("table_persons.csv", sep=",")
table_autos.to_csv("table_autos.csv", sep=",")
table_crash.to_csv("table_crash.csv", sep = ",")
table_regions.to_csv("table_regions.csv", sep = ",")