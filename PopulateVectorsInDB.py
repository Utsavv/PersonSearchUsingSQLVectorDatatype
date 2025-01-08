import pyodbc
from sentence_transformers import SentenceTransformer
import numpy as np
from dotenv import load_dotenv
import os

# Load environment variables from the .env file
load_dotenv()

# SQL Server connection details from .env file
server = os.getenv("SQL_SERVER")
database = os.getenv("SQL_DATABASE")
username = os.getenv("SQL_USERNAME")
password = os.getenv("SQL_PASSWORD")

# Connection string for SQL Server authentication
conn_str = f'''
DRIVER={{ODBC Driver 17 for SQL Server}};
SERVER={server};
DATABASE={database};
UID={username};
PWD={password};
'''

# Connect to SQL Server
conn = pyodbc.connect(conn_str)
cursor = conn.cursor()

# Fetch data from the Person table
cursor.execute("SELECT PersonID, FirstName, MiddleName, LastName, Suffix, PreferredName, FullName, BirthDate FROM Person")
persons = cursor.fetchall()

# Prepare the insert query for the PersonVectors table
insert_query = '''
INSERT INTO PersonVectors (PersonID, FullNameVector, FirstNameVector, MiddleNameVector, LastNameVector, SuffixVector, PreferredNameVector, BirthDateVector)
VALUES (?, ?, ?, ?, ?, ?, ?, ?)
'''

# Batch process to insert vector values
batch_size = 100
batch_data = []

for person in persons:
    person_id = person.PersonID
    first_name = person.FirstName
    middle_name = person.MiddleName if person.MiddleName else ""
    last_name = person.LastName
    suffix = person.Suffix if person.Suffix else ""
    preferred_name = person.PreferredName if person.PreferredName else ""
    full_name = person.FullName
    birth_date = str(person.BirthDate) if person.BirthDate else ""

    # Generate vectors for each column
    full_name_vector = model.encode([full_name])[0].tolist()
    first_name_vector = model.encode([first_name])[0].tolist()
    middle_name_vector = model.encode([middle_name])[0].tolist()
    last_name_vector = model.encode([last_name])[0].tolist()
    suffix_vector = model.encode([suffix])[0].tolist()
    preferred_name_vector = model.encode([preferred_name])[0].tolist()
    birth_date_vector = model.encode([birth_date])[0].tolist()

    # Add to batch
    batch_data.append((
        person_id,
        np.array(full_name_vector).tolist(),
        np.array(first_name_vector).tolist(),
        np.array(middle_name_vector).tolist(),
        np.array(last_name_vector).tolist(),
        np.array(suffix_vector).tolist(),
        np.array(preferred_name_vector).tolist(),
        np.array(birth_date_vector).tolist()
    ))

    # Insert data in batches
    if len(batch_data) >= batch_size:
        cursor.executemany(insert_query, batch_data)
        conn.commit()
        batch_data = []

# Insert remaining records in the batch
if batch_data:
    cursor.executemany(insert_query, batch_data)
    conn.commit()

print("Vector values inserted into PersonVectors table successfully.")

# Close connection
cursor.close()
conn.close()
