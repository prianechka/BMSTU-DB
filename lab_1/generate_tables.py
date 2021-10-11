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
    region_data = pd.read_csv("region.csv", sep = ",")[["name", "type", "name_with_type", "federal_district", "kladr_id", "timezone"]]
    region_data["kladr_id"] //= 100000000000
    region_data["name_with_type"] = region_data["name_with_type"].str.replace("Респ", "Республика")
    region_data["name_with_type"] = region_data["name_with_type"].str.replace("обл", "область")
    region_data["name_with_type"] = region_data["name_with_type"].str.replace("г ", "")

    region_data["type"] = region_data["type"].str.replace("Респ", "Республика")
    region_data["type"] = region_data["type"].str.replace("обл", "область")
    region_data["type"] = region_data["type"].str.replace("г ", "")

    region_data["timezone"] = region_data["timezone"].apply(lambda x: x[4:]).astype(int)

    region_data = region_data[["kladr_id", "name", "type", "name_with_type", "federal_district", "timezone"]]
    region_data.columns = ["region_id", "name", "region_type", "full_name", "federal_district", "timezone"]
    return region_data

def generate_school():
    f = codecs.open("inc/base_schools.txt", "r", "utf_8_sig")
    text = f.read()
    school_list = text.split("\r\n")
    return school_list

def generate_passport():
    result = ""
    for i in range(10):
        result += str(randint(0, 9))
    return result

def generate_person():
    fake = Faker('ru_RU')
    fake.add_provider(person)
    fake.add_provider(date_time)
    fake.add_provider(company)
    sex = choice(['М', 'Ж'])
    number = generate_passport()
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
    KP = choice(["автомат", "механика"])
    try_value = randint(1, 5)
    return number, last_name, name, middle_name, date_of_birth, sex, year, KP, try_value

def generate_table_of_persons():
    region_data = generate_regions()
    school_list = generate_school()
    table = pd.DataFrame(columns=["driver_id", "passport_id", "surname", "name", "middle_name", "date_of_birth", 
                                  "sex", "year_of_get_license", "study_transmission", 
                              "attemps_of_pass", "autoschool", "region_id"])
    for i in range(20000):
        number, last_name, name, middle_name, date_of_birth, sex, year, KP, try_value = generate_person()
        region = region_data.loc[randint(0, 85)]["region_id"]
        name_school = choice(school_list)
        table.loc[i] = [i + 1, number, last_name, name, middle_name, date_of_birth, sex, int(year), KP, int(try_value), name_school, region]
    return table

def get_price(price):
    array = price.split()
    if array[-1] == '₽':
        array = array[:len(array) - 1]
    if array[0] in ["от", "до"]:
        array = array[1:]
    return int(''.join(array))

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
        price = soup.findAll(lambda tag: tag.name == 'div' and tag.get('class') == ["ListingItemPrice__content"])
        N = len(auto)
        list_autos = []
        i = 0
        while (i + 5) < N:
            lst = []
            if (unicodedata.normalize("NFKC", auto[i].text.strip()).split(" / ")[2] == "Электро"):
              i += 5
            else:
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
            list_autos[i].append(get_price(price[i].text))
        result.extend(list_autos)
    return result

def generate_table_of_cars():
    auto = generate_cars()
    date_cars = pd.DataFrame(columns=["car_id", "car_number", "car_model", "car_type", "transmission", "drive_unit", 
                                      "engine_capacity", "engine_volume", 
                                      "fuel_type", "car_color", "price"])
    for i in range(len(list(auto))):
        car = auto[i]
        date_cars.loc[i] = [i + 1, car[8], car[7], car[4], car[3], car[5], int(car[1]), float(car[0]), car[2].lower(), car[6], car[9]]
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
    data_crash = pd.DataFrame(columns=["accident_id", "accident_date", "accident_time", "number_members", 
                                       "road_type", "road_cover_type", "temperature", 
                                        "light_extent", "moisture_extent"])
    
    for i in range(1500):
      date, time, N, type_street, type_cover, temp, bright, water = generate_crash()
      data_crash.loc[i] = [i + 1, date, time,int(N), type_street, type_cover, int(temp), float(bright), float(water)]
    
    return data_crash

def generate_table_of_details(persons, autos, crash):
    details = pd.DataFrame(columns=["id", "accident_id", "car_id", "driver_id", "alcohol_level", 
                                    "is_blamed", "is_exited_crash", 
                                    "driver_damage", "n_passengers"])
    N_person = persons.shape[0]
    N_auto = autos.shape[0]
    for i in range(crash.shape[0]):
        crash_id = i + 1
        N = crash.loc[i]["number_members"]
        id = list(np.random.choice(range(N_person), size = N, replace= False))
        autos_id = list(np.random.choice(range(N_auto), size = N, replace= False))
        blame = choice(range(1, N + 1))
        for j in range(N):
            person_id = persons.loc[id[j]]["driver_id"]
            auto_id = autos.loc[autos_id[j]]["car_id"]
            rv = stats.norm(loc = 0, scale = 0.6)
            promile = abs(rv.rvs(size = 1)[0])
            if (promile < 0.15):
              promile = 0
            if (blame - 1 == j):
                is_blamed = True
            else:
                is_blamed = False
            N_pas = randint(0, 3)
            exited = randint(1, 20)
            if (exited >= 17):
              is_exited = True
            else:
              is_exited = False
            
            driver_damage = randint(1, 15)
            if (driver_damage < 8):
              driver_damage_extent = "Лёгкие"
            elif (driver_damage < 14):
              driver_damage_extent = "Средние"
            else:
              driver_damage_extent = "Тяжёлые"
            details.loc[details.shape[0]] = [i + 1, crash_id, auto_id, person_id, float(promile), bool(is_blamed), 
                                             bool(is_exited), driver_damage_extent,int(N_pas)]
    return details

table_persons = generate_table_of_persons()
table_crash = generate_table_of_crash()
table_autos = generate_table_of_cars()
table_details = generate_table_of_details(table_persons, table_autos, table_crash)

table_persons.to_csv("table_drivers.csv", sep=",", index = False)
table_autos.to_csv("table_cars.csv", sep=",", index = False)
table_crash.to_csv("table_crash.csv", sep = ",", index = False)
table_details.to_csv("table_details.csv", sep=",", index = False)

table_regions = generate_regions()
table_regions.to_csv("table_regions.csv", sep = ",", index = False)