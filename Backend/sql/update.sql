
COPY suspect (id, name, base_aggression, base_compliance, current_aggression, current_compliance, personality, is_guilty)
FROM '/Users/kzminor22/Mana-Malice-clean/Godot/Episodes/E1-Petrification/suspects.txt'
WITH (FORMAT csv, DELIMITER ',', QUOTE '"', HEADER false);

SELECT * FROM Suspect;


COPY evidence (id, aggression_impact, compliance_impact, discovered, information)
FROM '/Users/kzminor22/Mana-Malice-clean/Godot/Episodes/E1-Petrification/evidence.txt'
WITH (FORMAT csv, DELIMITER ',', QUOTE '"', HEADER false);

SELECT * FROM Evidence;



COPY evidence_facts (evidence_id, fact_id)
FROM '/Users/kzminor22/Mana-Malice-clean/Godot/Episodes/E1-Petrification/evidence_facts.txt'
WITH (FORMAT csv, DELIMITER ',', QUOTE '"', HEADER false);

SELECT * FROM Evidence_facts;


COPY suspect_facts (suspect_id, fact_id, source_type)
FROM '/Users/kzminor22/Mana-Malice-clean/Godot/Episodes/E1-Petrification/suspect_knowledge.txt'
WITH (FORMAT csv, DELIMITER ',', QUOTE '"', HEADER false);

SELECT * FROM Suspect_facts;
