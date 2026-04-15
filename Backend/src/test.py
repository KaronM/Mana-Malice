import asyncio
import logfire #for tracking of llm responses
import main
import classes

from rag import run_agent

logfire.configure()
logfire.instrument_pydantic_ai()

conn = main.postgresql_pool.getconn()
cur = conn.cursor()

content = "Hi, I would like to know what you have ate from breakfast this morning."
suspect_id = 1

cur.execute('SELECT name FROM suspect WHERE id = %s', (suspect_id,))
suspect_name = cur.fetchone()

cur.execute('SELECT personality FROM suspect WHERE id = %s', (suspect_id,))
personality = cur.fetchone()

currentFocus = 6


cur.execute('SELECT is_guilty FROM suspect WHERE id = %s', (suspect_id,))
is_guilty = cur.fetchone()
aggression = 20
compliance = 60


suspect = classes.Suspect(suspect_id,suspect_name,conn,[aggression,compliance],is_guilty,personality,currentFocus)
request = classes.InterrogationRequest(player_text=content,suspect_id=suspect_id,aggression=aggression,compliance=compliance,current_focus=currentFocus,questionsAsked=20)

async def run():
    await run_agent(suspect, request)

asyncio.run(run())
