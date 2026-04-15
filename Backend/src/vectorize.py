# vectorize facts from the facts table in the MM database
import os
from pathlib import Path
from dotenv import load_dotenv
import psycopg2
from openai import OpenAI


env_path = Path(__file__).parent.parent / ".env"
load_dotenv(dotenv_path=env_path)

db_pass = os.getenv("DB_PASS")
openai_key = os.getenv("OPENAI_API_KEY")

client = OpenAI()

def get_embedding(fact: str):
    return client.embeddings.create(input = [fact], model = "text-embedding-3-small").data[0].embedding

def start_connection():
    connection = psycopg2.connect(dbname='mminterrogation', user='kzminor22', password=db_pass, port='5432')
    cursor = connection.cursor()
    return connection, cursor

print("Connection Started:")

try:
    conn, cur = start_connection()
    cur.execute('SELECT id, content FROM facts WHERE embeddings IS NULL')
    for row in cur.fetchall():
        fact_id = row[0]
        content = row[1]

        print(f"fact #{fact_id}")
        embedding = get_embedding(content)
        print(embedding)
        
        cur.execute('Update Facts SET embeddings = %s WHERE id = %s',(embedding, fact_id))

except Exception as e:
    print("Vectorization failed: ", e)
    conn.rollback()
finally:
    conn.commit()
    cur.close()
    conn.close()
    print("Connection closed")



