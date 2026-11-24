# Sistema de recomendação de músicas com base em grafos Neo4j

* Contexto do desafio: Criação de um sistema de recomendação musical baseada em grafos combinando metadados do [Million Song Dataset](https://www.kaggle.com/datasets/undefinenull/million-song-dataset-spotify-lastfm?select=User+Listening+History.csv);
+ Justificativa: Descoberta de similaridades entre usuários, artistas, tags e características de áudio;
+ Estratégia: amostragem de 1.000 registros de cada arquivo csv do dataset original.

## Modelagem do grafo

Para simplificar a modelagem do banco de dados e facilitar as consultas no **Neo4j Aura**, o modelo foi estruturado com **4 tipos de nós** e **3 tipos de relacionamentos**. A figura abaixo, criada usando [arrows.app](arrows.app) ilustra a modelagem:

![Modelo do Grafo](docs/graph-schema.png)

### Nós (Labels):

* **`(:User)`**: representa os ouvintes do histórico de reprodução, identificado unicamente por `user_id` (`String`)[cite: 1].
* **`(:Track)`**: entidade central do catálogo musical, identificada por `track_id` (`String`), contendo metadados (`name`, `year`, `spotify_id`) e as quatro principais *audio features* (`danceability`, `energy`, `valence`, `tempo`)[cite: 1].
* **`(:Artist)`**: representa o artista ou banda responsável pela faixa, identificado por `name` (`String`)[cite: 1].
* **`(:Tag)`**: representa estilos, subgêneros e descritores temáticos extraídos das tags das músicas, identificado por `name` (`String`)[cite: 1].

### Relacionamentos (Relationship Types)

* **`(:User)-[:LISTENED {playcount: Integer}]->(:Track)`**: liga o usuário à música ouvida e registra a quantidade de reproduções (`playcount`)[cite: 1].
* **`(:Track)-[:PERFORMED_BY]->(:Artist)`**: conecta cada faixa ao seu respectivo artista[cite: 1].
* **`(:Track)-[:HAS_TAG]->(:Tag)`**: associa cada faixa às tags que descrevem seu estilo ou contexto[cite: 1].

### Representação do padrão em Cypher

O padrão abaixo ilustra a estrutura conceitual do grafo (com os tipos esperados como referência de modelagem):

```cypher
CREATE (:User {user_id: "String"})-[:LISTENED {playcount: "Integer"}]->(n0:Track {
  track_id: "String",
  name: "String",
  year: "Integer",
  spotify_id: "String",
  danceability: "Float",
  energy: "Float",
  valence: "Float",
  tempo: "Float"
})-[:HAS_TAG]->(:Tag {name: "String"}),
(n0)-[:PERFORMED_BY]->(:Artist {name: "String"})

## Constraints, Índices e Carga de Dados no Neo4j Aura

Nesta etapa, preparamos o banco no Neo4j Aura para receber suas amostras ('sample-music-info.csv' e 'sample-user-listening-history.csv') com segurança, sem duplicidades e com conversão correta de tipos.

### constraints de unicidade no Neo4j Aura

```cypher
CREATE CONSTRAINT track_id_unique IF NOT EXISTS
FOR (t:Track) REQUIRE t.track_id IS UNIQUE;

CREATE CONSTRAINT artist_name_unique IF NOT EXISTS
FOR (a:Artist) REQUIRE a.name IS UNIQUE;

CREATE CONSTRAINT user_id_unique IF NOT EXISTS
FOR (u:User) REQUIRE u.user_id IS UNIQUE;

CREATE CONSTRAINT tag_name_unique IF NOT EXISTS
FOR (g:Tag) REQUIRE g.name IS UNIQUE;
```

### Carga das músicas, artitas e tags

``cypher
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
```

### Carga de uauários

```cypher
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
```

### Validação dos volumes carregados e o esquema real no banco:

```cypher
MATCH (n)
RETURN labels(n) AS label, count(*) AS total
ORDER BY total DESC;
```

![Validação de volumes carregados](assets/validacao.png)

### Conferência visual do esquema de dados

```cypher
CALL db.schema.visualization()
```

![Visualização do esquema de dados](assets/visualisation.png)
