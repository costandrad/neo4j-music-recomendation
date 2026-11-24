LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/costandrad/neo4j-music-recomendation/refs/heads/main/data/sample-music-info.csv' AS row
WITH row
WHERE row.track_id IS NOT NULL AND trim(row.track_id) <> ''

MERGE (t:Track {track_id: trim(row.track_id)})
SET
  t.name = trim(row.name),
  t.spotify_id = CASE WHEN row.spotify_id IS NOT NULL AND trim(row.spotify_id) <> '' THEN trim(row.spotify_id) ELSE null END,
  t.year = CASE WHEN row.year IS NOT NULL AND trim(row.year) =~ '^-?[0-9]+$' THEN toInteger(trim(row.year)) ELSE null END,
  t.danceability = CASE WHEN row.danceability IS NOT NULL AND trim(row.danceability) <> '' THEN toFloat(trim(row.danceability)) ELSE null END,
  t.energy = CASE WHEN row.energy IS NOT NULL AND trim(row.energy) <> '' THEN toFloat(trim(row.energy)) ELSE null END,
  t.valence = CASE WHEN row.valence IS NOT NULL AND trim(row.valence) <> '' THEN toFloat(trim(row.valence)) ELSE null END,
  t.tempo = CASE WHEN row.tempo IS NOT NULL AND trim(row.tempo) <> '' THEN toFloat(trim(row.tempo)) ELSE null END

FOREACH (_ IN CASE WHEN row.artist IS NOT NULL AND trim(row.artist) <> '' THEN [1] ELSE [] END |
  MERGE (a:Artist {name: trim(row.artist)})
  MERGE (t)-[:PERFORMED_BY]->(a)
)

WITH t, row
WHERE row.tags IS NOT NULL AND trim(row.tags) <> ''
UNWIND split(row.tags, ',') AS rawTag
WITH t, toLower(trim(rawTag)) AS cleanTag
WHERE cleanTag <> ''
MERGE (tag:Tag {name: cleanTag})
MERGE (t)-[:HAS_TAG]->(tag);



LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/costandrad/neo4j-music-recomendation/refs/heads/main/data/sample-user-listening-history.csv' AS row
WITH row
WHERE row.user_id IS NOT NULL AND trim(row.user_id) <> ''
  AND row.track_id IS NOT NULL AND trim(row.track_id) <> ''

MERGE (u:User {user_id: trim(row.user_id)})
MERGE (t:Track {track_id: trim(row.track_id)})
MERGE (u)-[r:LISTENED]->(t)
SET r.playcount = CASE
  WHEN row.playcount IS NOT NULL AND trim(row.playcount) =~ '^-?[0-9]+$'
  THEN toInteger(trim(row.playcount))
  ELSE 0
END;