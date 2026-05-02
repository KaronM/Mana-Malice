CREATE TABLE IF NOT EXISTS Suspect(
    id INT PRIMARY KEY,
    name TEXT NOT NULL,
    base_aggression INT,
    base_compliance INT,
    current_aggression INT,
    current_compliance INT,
    personality TEXT,
    is_guilty boolean,
    speech_patterns TEXT,
    stubborness FLOAT
);

CREATE TYPE observation_type AS ENUM (
    'Seen',
    'Heard',
    'Research'
);

CREATE TABLE IF NOT EXISTS Evidence(
    id INT PRIMARY KEY,
    aggression_impact integer,
    compliance_impact integer,
    discovered boolean,
    information text
);

CREATE TABLE IF NOT EXISTS Suspect_observations(
    observation_id SERIAL PRIMARY KEY,
    suspect_id integer,
    content text
);

CREATE TABLE IF NOT EXISTS Suspect_facts(
    suspect_id INTEGER REFERENCES Suspect(id),
    fact_id INTEGER REFERENCES Facts(id),
    source_type observation_type
);

CREATE TABLE IF NOT EXISTS Evidence_facts(
    evidence_id INTEGER REFERENCES Evidence(id),
    fact_id INTEGER REFERENCES Facts(id)
);