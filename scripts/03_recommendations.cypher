// Dado um track_id de referência, recomenda músicas com mais tags em comum e energia próxima
MATCH (seed:Track {track_id: 'TRGREBT128F92F4835'})-[:HAS_TAG]->(tag:Tag)<-[:HAS_TAG]-(rec:Track)
WHERE rec <> seed
  AND seed.energy IS NOT NULL AND rec.energy IS NOT NULL
OPTIONAL MATCH (rec)-[:PERFORMED_BY]->(artist:Artist)
WITH seed, rec, artist,
     count(DISTINCT tag) AS shared_tags,
     abs(seed.energy - rec.energy) AS energy_diff
RETURN rec.track_id AS track_id,
       rec.name AS musica,
       artist.name AS artista,
       shared_tags,
       round(energy_diff * 1000) / 1000 AS dif_energia,
       rec.valence AS valence,
       rec.tempo AS tempo
ORDER BY shared_tags DESC, energy_diff ASC, rec.name ASC
LIMIT 10;