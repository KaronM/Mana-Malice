
CREATE TABLE IF NOT EXISTS Facts(
    id INT PRIMARY KEY,
    Category category,
    content TEXT NOT NULL,
    embeddings vector(1536)
);

COPY facts (id, category, content)
FROM '/Users/kzminor22/Mana-Malice-clean/Godot/Episodes/E1-Petrification/facts.txt'
WITH (FORMAT csv, DELIMITER ',', QUOTE '''', HEADER false);

SELECT * FROM facts