import json
import pyodbc
from sentence_transformers import SentenceTransformer
from dotenv import load_dotenv
from tabulate import tabulate  # <--- Added import
import os

# Load environment variables from the .env file
load_dotenv()

# Initialize the embedding model (adjust model name if desired)
model = SentenceTransformer('sentence-transformers/all-MiniLM-L6-v2')

def get_connection():
    """
    Establish a connection to the SQL Server using credentials from the .env file.
    Returns:
        conn: A connection object.
    """
    server = os.getenv("SQL_SERVER")
    database = os.getenv("SQL_DATABASE")
    username = os.getenv("SQL_USERNAME")
    password = os.getenv("SQL_PASSWORD")

    conn_str = f'''
    DRIVER={{ODBC Driver 18 for SQL Server}};
    SERVER={server};
    DATABASE={database};
    UID={username};
    PWD={password};
    '''
    return pyodbc.connect(conn_str)


def vector_search_sql(search_query, conn, vector_column='FullNameVector', num_results=5):
    """
    Performs a vector search using cosine similarity (without binding the query parameters).
    Args:
        search_query (str): The query string to encode and search for.
        conn: The database connection object.
        vector_column (str): Which vector column to use (e.g. FullNameVector, FirstNameVector, etc.).
        num_results (int): Number of top results to fetch.
    Returns:
        A list of matching rows with similarity scores.
    """
    cursor = conn.cursor()

    # Generate the embedding for the query
    user_query_embedding = model.encode([search_query])[0].tolist()
    json_embedding = json.dumps(user_query_embedding)

    # Dynamically build the SQL string without parameterized queries
    sql_similarity_search = f"""
    SELECT TOP {num_results}
           p.PersonID,
           p.FirstName,
           p.MiddleName,
           p.LastName,
           p.Suffix,
           p.PreferredName,
           p.FullName,
           p.BirthDate,
           1 - vector_distance(
                'cosine',
                CAST(CAST('{json_embedding}' AS NVARCHAR(MAX)) AS VECTOR(384)),
                v.{vector_column}
            ) AS similarity_score,
           vector_distance(
                'cosine',
                CAST(CAST('{json_embedding}' AS NVARCHAR(MAX)) AS VECTOR(384)),
                v.{vector_column}
            ) AS distance_score
    FROM PersonVectors v
    JOIN Person p ON p.PersonID = v.PersonID
    ORDER BY distance_score;
    """

    cursor.execute(sql_similarity_search)
    results = cursor.fetchall()

    # Convert rows to a list of dictionaries for ease of manipulation
    return [
        {
            "PersonID": row.PersonID,
            "FirstName": row.FirstName,
            "MiddleName": row.MiddleName,
            "LastName": row.LastName,
            "Suffix": row.Suffix,
            "PreferredName": row.PreferredName,
            "FullName": row.FullName,
            "BirthDate": str(row.BirthDate) if row.BirthDate else None,
            "SimilarityScore": row.similarity_score,
            "DistanceScore": row.distance_score
        }
        for row in results
    ]


if __name__ == "__main__":
    # Get the database connection
    conn = get_connection()

    try:
        while True:
            # Prompt user for the name
            search_query = input("Enter the name to search (or QUIT to exit): ")
            if search_query.strip().upper() == "QUIT":
                break

            # Prompt user for the vector column
            column_name = input("Enter the vector column to search in (e.g. FullNameVector), or QUIT to exit: ")
            if column_name.strip().upper() == "QUIT":
                break

            print(f"Searching for '{search_query}' in column '{column_name}' ...")

            # Perform the search
            search_results = vector_search_sql(search_query, conn, vector_column=column_name, num_results=15)

            if not search_results:
                print("No matching results found.\n")
            else:
                # Build table data: each row is a list of values
                table_data = []
                # Prepare headers for readability
                headers = [
                    "#", 
                    "PersonID", 
                    "FirstName", 
                    "MiddleName", 
                    "LastName", 
                    "Suffix", 
                    "PreferredName", 
                    "FullName", 
                    "BirthDate", 
                    "Similarity", 
                    "Distance"
                ]
                for i, row in enumerate(search_results, start=1):
                    table_data.append([
                        i,
                        row["PersonID"],
                        row["FirstName"],
                        row["MiddleName"],
                        row["LastName"],
                        row["Suffix"],
                        row["PreferredName"],
                        row["FullName"],
                        row["BirthDate"],
                        round(row["SimilarityScore"], 4),
                        round(row["DistanceScore"], 4)
                    ])

                # Print the data in a tabular format
                print(tabulate(table_data, headers=headers, tablefmt="fancy_grid"))
                print()

    except Exception as ex:
        print("An error occurred:", ex)
    finally:
        conn.close()
        print("Connection closed.")
