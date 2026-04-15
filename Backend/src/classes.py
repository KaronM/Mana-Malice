from pydantic import BaseModel #for json data schemas between responses and requests 
from dataclasses import dataclass #for defining llm output dependencies 
import psycopg2
import psycopg2.extensions

#dependencies for suspect
@dataclass
class Suspect():
    suspect_id : int
    name: str
    db_conn : psycopg2.extensions.connection #connection to database
    ac_stats : tuple[int,int] #tuple with aggression and compliance stats
    is_guilty : bool
    personality: str
    current_focus: int

#json data schemas for interrogation models responses and requests
class InterrogationRequest(BaseModel):
    player_text: str 
    suspect_id: int
    aggression: float 
    compliance: float
    current_focus: int
    questionsAsked : int
 #current_focus: int 

class InterrogationResponse(BaseModel):
    dialogue: str
    updated_aggression: float
    updated_compliance: float
    updated_focus: int
    thoth_comment: str | None = None 
    is_contradiction_detected: bool
    left_interrogation : bool
    
 