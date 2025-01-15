import json
import pyodbc
from sentence_transformers import SentenceTransformer
import numpy as np
from dotenv import load_dotenv
import os

# Load environment variables from the .env file
load_dotenv()

# Initialize the embedding model
model = SentenceTransformer('sentence-transformers/all-MiniLM-L6-v2')


def get_connection():
    """
    Establishes a connection to the SQL Server using credentials from the .env file.
    Returns:
        conn: A connection object.
    """
    server = os.getenv("SQL_SERVER")
    database = os.getenv("SQL_DATABASE")
    username = os.getenv("SQL_USERNAME")
    password = os.getenv("SQL_PASSWORD")

    # Connection string for SQL Server authentication
    conn_str = f'''
    DRIVER={{ODBC Driver 18 for SQL Server}};
    SERVER={server};
    DATABASE={database};
    UID={username};
    PWD={password};
    '''
    return pyodbc.connect(conn_str)


def fetch_person_data(conn):
    """
    Fetches data from the Person table.
    Args:
        conn: The database connection object.
    Returns:
        List of persons fetched from the Person table.
    """
    cursor = conn.cursor()
    cursor.execute("SELECT PersonID, FirstName, MiddleName, LastName, Suffix, PreferredName, FullName, BirthDate FROM Person")
    return cursor.fetchall()


def generate_vectors(person):
    """
    Generates vectors for all relevant columns of a person.
    Args:
        person: A tuple containing person data.
    Returns:
        A tuple of generated vectors.
    """
    person_id = person.PersonID
    first_name = person.FirstName
    middle_name = person.MiddleName if person.MiddleName else ""
    last_name = person.LastName
    suffix = person.Suffix if person.Suffix else ""
    preferred_name = person.PreferredName if person.PreferredName else ""
    full_name = person.FullName
    birth_date = str(person.BirthDate) if person.BirthDate else ""

    # Generate vectors
    full_name_vector = model.encode([full_name])[0].tolist()
    first_name_vector = model.encode([first_name])[0].tolist()
    middle_name_vector = model.encode([middle_name])[0].tolist()
    last_name_vector = model.encode([last_name])[0].tolist()
    suffix_vector = model.encode([suffix])[0].tolist()
    preferred_name_vector = model.encode([preferred_name])[0].tolist()
    birth_date_vector = model.encode([birth_date])[0].tolist()

    return (
        person_id,
        np.array(full_name_vector).tolist(),
        np.array(first_name_vector).tolist(),
        np.array(middle_name_vector).tolist(),
        np.array(last_name_vector).tolist(),
        np.array(suffix_vector).tolist(),
        np.array(preferred_name_vector).tolist(),
        np.array(birth_date_vector).tolist()
    )


def insert_vectors(conn, persons, batch_size=100):
    """
    Inserts vector values into the PersonVectors table in batches using a single INSERT INTO ... VALUES query.
    Each vector value is converted to NVARCHAR(MAX).
    Args:
        conn: The database connection object.
        persons: A list of person records.
        batch_size: The size of each batch for insertion.
    """
    cursor = conn.cursor()

    # Prepare batch data
    batch_data = []

    for person in persons:
        vectors = generate_vectors(person)

        # Format each row as a SQL-compatible string with vectors converted to NVARCHAR(MAX)
        formatted_row = f"({vectors[0]}, " \
                        f"CAST(CAST('{json.dumps(vectors[1])}'as NVARCHAR(MAX)) AS VECTOR(384)), " \
                        f"CAST(CAST('{json.dumps(vectors[2])}'as NVARCHAR(MAX)) AS VECTOR(384)), " \
                        f"CAST(CAST('{json.dumps(vectors[3])}'as NVARCHAR(MAX)) AS VECTOR(384)), " \
                        f"CAST(CAST('{json.dumps(vectors[4])}'as NVARCHAR(MAX)) AS VECTOR(384)), " \
                        f"CAST(CAST('{json.dumps(vectors[5])}'as NVARCHAR(MAX)) AS VECTOR(384)), " \
                        f"CAST(CAST('{json.dumps(vectors[6])}'as NVARCHAR(MAX)) AS VECTOR(384)), " \
                        f"CAST(CAST('{json.dumps(vectors[7])}'as NVARCHAR(MAX)) AS VECTOR(384)))"
        batch_data.append(formatted_row)

        # Insert data in batches
        if len(batch_data) >= batch_size:
            # Combine all rows into a single INSERT query
            insert_query = f"""
            INSERT INTO PersonVectors (PersonID, FullNameVector, FirstNameVector, MiddleNameVector, LastNameVector, SuffixVector, PreferredNameVector, BirthDateVector)
            VALUES {', '.join(batch_data)};
            """
            cursor.execute(insert_query)
            conn.commit()
            batch_data = []

    # Insert remaining records
    if batch_data:
        insert_query = f"""
        INSERT INTO PersonVectors (PersonID, FullNameVector, FirstNameVector, MiddleNameVector, LastNameVector, SuffixVector, PreferredNameVector, BirthDateVector)
        VALUES {', '.join(batch_data)};
        """
        cursor.execute(insert_query)
        conn.commit()

    print("Vector values inserted into PersonVectors table successfully.")


if __name__ == "__main__":
    # Establish connection
    conn = get_connection()

    # Fetch person data
    persons = fetch_person_data(conn)

    # Insert vector values
    insert_vectors(conn, persons)
    
    Print(f"Vector table has been popu;ated.")

    # Close the connection
    conn.close()