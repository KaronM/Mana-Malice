import os
import classes
import vectorize 
from pathlib import Path
from openai import OpenAI
from dotenv import load_dotenv
import psycopg2
import psycopg2.extensions
import logfire
from pydantic_ai import Agent, RunContext #for interacting with a LLM agent for the necessary responses
from pydantic_ai.models.openai import OpenAIResponsesModel

env_path = Path(__file__).parent.parent / ".env"
load_dotenv(dotenv_path=env_path)

db_pass = os.getenv("DB_PASS")

model = OpenAIResponsesModel("gpt-4o-mini")


#creating our AI agent
agent = Agent(model,
              deps_type = classes.Suspect, #data to inject in request to ai
              output_type=classes.InterrogationResponse,
              system_prompt="you are a suspect interrogated by the Magisterium of Arcane Affairs for a crime revolving alchemy"
              )

#Helper Functions

#for searching through embeddings in the facts database
def semantic_search(conn: psycopg2.extensions.connection, query, amount):
    print("Fact Search Started!")
    try:
        cur = conn.cursor()

        q_embedding = str(vectorize.get_embedding(query))

        cur.execute('''
                    SELECT id, Category, content, 1-(embeddings <=> %s) AS cosine_similarity
                    FROM Facts 
                    ORDER BY embeddings <=> %s
                    LIMIT %s''', (q_embedding,q_embedding, amount))

        return cur.fetchall()
    except Exception as e:
        print("Fact Search failed: ",e)
    finally:
        print("Fact Search Finished!")
    

#to search suspects through the database
def search_suspect(conn: psycopg2.extensions.connection, id):
    print("Suspect search started!")
    try:
        cur = conn.cursor()
        cur.execute('''SELECT id FROM suspect WHERE id = %s''', (id))
        return cur.fetchall()
    except Exception as e:
        print("Suspect search failed: " ,e)
    finally:
        print("Suspect Search Finished!")

#return fact is fact known
def search_knowledge(conn: psycopg2.extensions.connection, suspect_id, fact_id):
    print("Knowledge Search Started!")
    try:
        cur = conn.cursor()
        cur.execute('''SELECT %s FROM suspect_facts WHERE fact_id = %s''', (suspect_id, fact_id))
        if len(cur.fetchall()) != 0 :
            return fact_id
        else:
            return -1

    except Exception as e:
        print("Knowledge search failed:" ,e)
    finally:
        print("Knowledge Search Finished!")

def search_observations(conn: psycopg2.extensions.connection, suspect_id, observation_keyword):
    print("Knowledge Search Started!")
    try:
        cur = conn.cursor()
        cur.execute('''SELECT content FROM suspect_observation WHERE content LIKE '%s' ''', (suspect_id, observation_keyword))
        return cur.fetchone

    except Exception as e:
        print("Knowledge search failed:" ,e)
    finally:
        print("Knowledge Search Finished!")

#adds (suspect_id, fact_id) in suspect_facts if suspect doesn't know 
def add_observation(conn: psycopg2.extensions.connection, suspect_id, content):
    print("Knowledge being added!")
    try:
        cur = conn.cursor()
        cur.execute('''INSERT INTO suspect_observations (suspect_id, content) VALUES (%s, %s)''',(suspect_id, content))
    except Exception as e:
        print("Observation addition failure: ", e)
    finally:
        conn.commit()
        print("Observation successfully added!")

def search_evidence_from_fact(conn: psycopg2.extensions.connection, fact_id): 
    print("Evidence Search Started")
    try:
        cur = conn.cursor()
        cur.execute('''SELECT evidence_id FROM evidence_facts WHERE fact_id = %s''',(fact_id,))
        return cur.fetchall()
    except Exception as e:
        print("Evidence search failed: ", e)
    finally:
        print("Evidence Search Finished!")
    
def get_evidence_aggression_compliance(conn: psycopg2.extensions.connection, evidence_id):
    print("Aggression and compliance search started!")
    try:
        cur = conn.cursor()
        cur.execute('''SELECT aggression_impact, compliance_impact FROM evidence_facts WHERE evidence_id = %s''',(evidence_id,))
        return cur.fetchall()
    except Exception as e:
        print("Getting aggression and compliance failed: ", e)
    finally:
        print("Aggression and compliance success!")
    

#Ai agent tools
@agent.system_prompt
async def get_system_prompt(ctx: RunContext[classes.Suspect]):
    return f'''
            You are {ctx.deps.name}, a suspect in a petrification murder.
            Your guilty status is {ctx.deps.is_guilty}.
            Mood: Your aggression level is {ctx.deps.ac_stats[0]}, and your compliance level is {ctx.deps.ac_stats[1]}
            Your personality is {ctx.deps.personality}
            RULES:
            1. If the player asks a question, use 'recall_and_verify' immediately.
            2. If a fact is NOT known by you, you must act as if it is news to you. If you are guilty, you should Lie
            3. Use 'update_suspect_status' if the player's tone changes.
            4. Use evaluate_confession_criteria to see if the mood level dictates a confession
            5. ALWAYS run update_focus to see if the request is Relevant, If the request is Irrelevant, skip all steps and dismiss the request
            6. NEVER send an empty response or non-response. If so, use ... as a response.
            """
            '''

@agent.tool
async def update_focus(ctx: RunContext[classes.Suspect], focus_delta: int):
    '''
    ALWAYS use this tool to quantify the relevancy of the interrogator's request
    create a focus_delta: -2 if completely irrelevant, 1 if relevant 
    Maximum focus is 8, minimum is 0
    '''

    new_focus = focus_delta + ctx.deps.current_focus

    return f"New focus is {new_focus}"


@agent.tool
async def memory_search(ctx: RunContext[classes.Suspect], query: str, limit: int ):
    '''
    A large memory search. Automatically checks if the suspect 
    knows the facts and if those facts are linked to physical evidence.
    if suspect does not know the number 1 fact, use the add_suspect_knowledge for the fact.
    Then use the update_aggression_compliance from the following.
    Pick the number of memories as the Limit necessary to search. 3 maximum, 1 minimum.
    Less memories should be searched when minimal information is provided.
    '''
    
    print("Memory Search Started!")
    #semantic search
    top_facts = semantic_search(ctx.deps.db_conn, query, limit) 
    
    verified_results = []
    try:
        for f_id, category, content, cosine_similarity in top_facts:
            #does the suspect know this?
            is_known = search_knowledge(ctx.deps.db_conn, ctx.deps.suspect_id, f_id)
            
            #is there physical evidence attached to it?
            evidence_id = search_evidence_from_fact(ctx.deps.db_conn, f_id)
            
            verified_results.append({
                "fact": content,
                "known_by_suspect": is_known != -1,
                "associated_evidence": evidence_id if len(evidence_id) != 0 else "None"
            })
    except Exception as e:
        print("Memory Search Failed: ", e)
    
    finally:
        print("Memory Search Success!")

    return verified_results


@agent.tool
async def add_suspect_observation(ctx: RunContext[classes.Suspect], content: str):
    '''
    use this tool to ALWAYS add observations from the interrogator's request with info that 
    you'll most likely need to remember in the interrogation.
    Use this for things like the interrogators name and other basic information
    '''
    return add_observation(ctx.deps.db_conn,ctx.deps.suspect_id, content)

@agent.tool
async def search_suspect_observation(ctx: RunContext[classes.Suspect], content: str):
    '''
    use this tool to ALWAYS add observations from the interrogator's request with info that 
    you'll most likely need to remember in the interrogation.
    Use this for things like the interrogators name and other basic information
    '''
    return search_observations(ctx.deps.db_conn,ctx.deps.suspect_id, content)

@agent.tool_plain
async def create_thoth_comment(comment:str):
    '''
    This tool is for a magic ancient book used by the police to guide them
    GENERATE a short comment guiding the interrogator
    ONLY use this if the request is deemed irrelevant
    DO NOT use this for every response
    '''

    return f"thoth says {comment}"

@agent.tool
async def update_suspect_status(
    ctx: RunContext[classes.Suspect], 
    aggression_delta: int, 
    compliance_delta: int, 
    reason: str
):
    """
    call this tool to adjust the suspect's internal state based on the conversation.
    - aggression_delta: change in anger/defensiveness (-20 to 20).
    - compliance_delta: change in willingness to help (-20 to 20).
    - reason: short explanation (ex. 'Player was insulting' or 'Player showed empathy').
    """
    a = ctx.deps.ac_stats[0]
    a += aggression_delta
    c = ctx.deps.ac_stats[1]
    c += compliance_delta
    
    print(f"Status Update: {reason}. Agg: {a}, Comp: {c}")
    return c

@agent.tool
async def evaluate_confession_criteria(ctx: RunContext[classes.Suspect]) -> str:
    """
    checks if the suspect's current emotional state warrants a confession.
    """

    agg = ctx.deps.ac_stats[0]
    comp = ctx.deps.ac_stats[1]
    
    # logic: high compliance and low aggression triggers a breakdown
    if ctx.deps.is_guilty:
        if comp > 80 and agg < 30:
            return "breaking: The suspect is ready to confess everything."
        elif comp > 60 and agg < 50:
            return "cracking: The suspect is starting to admit small details but holding back the main truth."
        else:
            return "defiance: The suspect will not confess yet."
    else:
        return "innocent: The suspect has nothing to confess regarding the murder."

async def run_agent(suspect: classes.Suspect, IRequest: classes.InterrogationRequest):
    result = await agent.run(
        IRequest.player_text,
        deps=suspect
    )

    print("Result Successful!")

    response = result.output

    #for testing purposes -> logfire.info(f'Here is the output: {response}')

    dict = {'output': response.dialogue, 
            'updated aggression': response.updated_aggression,
            'updated compliance': response.updated_compliance,
            'updated focus': response.updated_focus,
            'thoth comment': response.thoth_comment,
            'contradiction': response.is_contradiction_detected,
            'left interrogation': response.left_interrogation}

    return dict