# receive and handle requests requests,
import os
from pathlib import Path
from dotenv import load_dotenv
from fastapi import FastAPI 
from rag import run_agent
import psycopg2
from psycopg2 import pool
from contextlib import asynccontextmanager
from knn import getMood
import classes

env_path = Path(__file__).parent.parent / ".env"
load_dotenv(dotenv_path=env_path)

db_pass = os.getenv("DB_PASS")

def start_connection_pool(): 
    postgreSQL_pool = pool.ThreadedConnectionPool(
            minconn=1,
            maxconn=5,
            user="kzminor22",
            password=db_pass,
            host="localhost",
            port="5432",
            database="mminterrogation"
        )
    return postgreSQL_pool

postgresql_pool = start_connection_pool()

#for the lifespan of the server
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Code to run on startup
    print("Application Startup: Connecting to database")
    yield
    # Code to run on shutdown
    print("Application Shutdown: Closing connections,cleaning up...")
    postgresql_pool.closeall()

app = FastAPI(lifespan=lifespan)

#for godot to post a request to the api and get a response back
@app.get("/Interrogation/{suspect_id}/stats")
async def get_ac_stats(suspect_id: int):
    print("getting aggression and compliance stats")
    try:
        conn = postgresql_pool.getconn()

        cur = conn.cursor()
        cur.execute('SELECT base_aggression,base_compliance FROM suspect WHERE id = %s', (suspect_id,))
        
        acStats = cur.fetchone()
    
        mood = getMood(acStats[0], acStats[1])

        return [acStats[0], acStats[1], mood]
    except Exception as e:
        print("stat collection Failed: ", e)
    finally:
        postgresql_pool.putconn(conn)


@app.post("/Interrogation/{suspect_id}")
async def create_suspect(IRequest: classes.InterrogationRequest):
    print("Connection Started!")
    try:
        conn = postgresql_pool.getconn()

        cur = conn.cursor()
        cur.execute('SELECT * FROM suspect WHERE id = %s', (IRequest.suspect_id,))
        suspect = cur.fetchone()
        suspect_name = suspect[1]
        ac = [IRequest.aggression,IRequest.compliance]
        suspect_personality = suspect[4]
        suspect_speech_patterns = suspect[8]
        stubborness = suspect[9]
        guiltiness = suspect[5]

        suspect_object = classes.Suspect(suspect_id=IRequest.suspect_id, name=suspect_name, db_conn=conn, ac_stats=ac, is_guilty=guiltiness,personality = suspect_personality, current_focus=IRequest.current_focus, questions_asked=IRequest.questionsAsked, current_mood=IRequest.current_mood, unfocused_streak=IRequest.unfocused_streak, speech_pattern=suspect_speech_patterns, stubborness=stubborness)
        
        print("suspect info: ", suspect)

        response = await run_agent(suspect_object, IRequest)

        response["mood"] = getMood(response["updated aggression"], response["updated compliance"])

        return response 
    
    except Exception as e:
        print("Connection Failed: ", e)
    finally:
        postgresql_pool.putconn(conn)
