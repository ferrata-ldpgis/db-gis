--test_geo
CREATE EXTENSION postgis;
SELECT PostGIS_Version();
CREATE DATABASE test_geo;

CREATE TABLE luoghi (
    id SERIAL PRIMARY KEY,
    nome TEXT,
    coord GEOMETRY(Point, 4326)
);


INSERT INTO luoghi (nome, coord)
VALUES (
    'Duomo di Firenze',
    ST_SetSRID(ST_MakePoint(11.2558, 43.7731), 4326)
);

SELECT nome,ST_AsText(coord) FROM luoghi ;


--db_social
--creo colonna
ALTER TABLE posts
ADD COLUMN position GEOMETRY(Point, 4326);

--update colonna
UPDATE posts
SET position = ST_SetSRID(
    ST_MakePoint(
        random() * 360 - 180,  -- longitudine (-180, 180)
        random() * 180 - 90    -- latitudine (-90, 90)
    ),
    4326
);

--creazione indice
CREATE INDEX idx_posts_position_gist
ON posts
USING GIST (position);

--query varie
SELECT *
FROM posts
WHERE position && ST_MakeEnvelope(0, 0, 50, 50, 4326);


SELECT *
FROM posts
WHERE position && ST_MakeEnvelope(0, 0, 50, 50, 4326)
AND ST_Within(position, ST_MakeEnvelope(0, 0, 50, 50, 4326));

SELECT *
FROM posts
WHERE ST_Intersects(
    position,
    ST_MakeEnvelope(0, 0, 50, 50, 4326)
);

SELECT *
FROM posts
WHERE ST_DWithin(
    position::geography,
    ST_SetSRID(ST_MakePoint(11.25, 43.77), 4326)::geography,
    10000
);

--colonna geography
ALTER TABLE posts
ADD COLUMN geography geography(Point, 4326);

CREATE INDEX idx_posts_geography_gist
ON posts
USING GIST(geography)

UPDATE posts
SET geography = ST_SetSRID(
    ST_MakePoint(
        -180 + random() * 360,  -- lon
        -90  + random() * 180   -- lat
    ),
    4326
)::geography;


--punto
ST_SetSRID(ST_MakePoint(11.25, 43.77), 4326)
ST_SetSRID(ST_MakePoint(x, y), 4326)

--buffer
z = distanza in metri
ST_BUffer(ST_SetSRID(ST_MakePoint(x, y), 4326), z)

--ST_DWithin
ST_Dwithin(geom/geog, geom/geog/, distanza in metri)


--trovare i punti entro un raggio di 100 km da Firenze

--buffer
SELECT *,
	ST_Distance(
	   geography,
	   ST_SetSRID(ST_MakePoint(11.25, 43.77), 4326)
   ) AS distanza
FROM posts
WHERE ST_Intersects(
    geography::geography,
    ST_Buffer(ST_SetSRID(ST_MakePoint(11.25, 43.77), 4326)::geography, 100000)
);


SELECT *,
	ST_Distance(
	   geometry,
	   ST_SetSRID(ST_MakePoint(11.25, 43.77), 4326)
   ) AS distanza
FROM posts
WHERE ST_Intersects(
    geometry,
    ST_Buffer(ST_SetSRID(ST_MakePoint(11.25, 43.77), 4326), 100000)
);

--DWithin
SELECT *
FROM posts
WHERE ST_DWithin(
    geometry,
    ST_SetSRID(ST_MakePoint(11.25, 43.77), 4326),
    100000
);

SELECT *
FROM posts
WHERE ST_DWithin(
    geography::geography,
    ST_SetSRID(ST_MakePoint(11.25, 43.77), 4326)::geography,
    500000
);


SELECT *
FROM posts
WHERE ST_DWithin(
    geography::geography,
    ST_SetSRID(ST_MakePoint(11.25, 43.77), 4326)::geography,
    1000000
)
ORDER BY ST_Distance(
          geography::geography,
          ST_SetSRID(ST_MakePoint(11.25, 43.77), 4326)::geography
)
LIMIT 5;


SELECT *
FROM posts
ORDER BY geometry <-> ST_SetSRID(ST_MakePoint(11.25, 43.77), 4326)
LIMIT 5;


SELECT *
FROM posts
ORDER BY geography <-> ST_SetSRID(ST_MakePoint(11.25, 43.77), 4326)::geography
LIMIT 5;


--3003
CREATE TABLE luoghi (
    id SERIAL PRIMARY KEY,
    nome TEXT,
    posizione GEOMETRY(POINT, 3003)
);


CREATE TABLE aree (
    id SERIAL PRIMARY KEY,
    nome TEXT,
    posizione GEOMETRY(POLYGON, 3003)
);

CREATE INDEX idx_luoghi_posizione
ON luoghi
USING GIST(posizione);

CREATE INDEX idx_aree_posizione
ON aree
USING GIST(posizione);

INSERT INTO luoghi (nome, posizione)
SELECT 'Luogo ' || i,
       ST_SetSRID(ST_MakePoint(
           random() * (1600000 - 1200000) + 1200000,  -- X
           random() * (5200000 - 4600000) + 4600000   -- Y
       ), 3003)
FROM generate_series(1, 100) AS s(i);


INSERT INTO aree (nome, posizione)
SELECT 'Area ' || i,
       ST_SetSRID(
           ST_MakePolygon(
               ST_MakeLine(ARRAY[
                   ST_MakePoint(x, y),
                   ST_MakePoint(x + 10000, y),
                   ST_MakePoint(x + 10000, y + 10000),
                   ST_MakePoint(x, y + 10000),
                   ST_MakePoint(x, y)
               ])
           ), 3003)
FROM (
    SELECT i,
           random() * (1600000 - 1200000) + 1200000 AS x,
           random() * (5200000 - 4600000) + 4600000 AS y
    FROM generate_series(1, 100) AS s(i)
) t;

CREATE OR REPLACE VIEW v_luoghi AS
SELECT 
    id,
    nome,
    posizione,
    
    -- Coordinate come testo
    ST_AsText(posizione) AS posizione_testo,
    
    -- Coordinate in lat/lon (SRID 4326)
    ST_AsText(ST_Transform(posizione, 4326)) AS posizione_latlon,
    
    -- Distanza da Torino (coordinate centro approssimativo 1500000, 5100000 in 3003)
    ST_Distance(
        posizione,
        ST_SetSRID(ST_MakePoint(1500000, 5100000), 3003)
    ) AS distanza_da_torino_m
FROM luoghi;

-- Oggetti entro 500 m da un punto
SELECT *
FROM luoghi
WHERE ST_DWithin(
    posizione,
    ST_SetSRID(ST_MakePoint(1500000, 5000000), 3003),
    500
);

--2b. Intersezione
--ST_Intersects(a, b) → verifica topologica (indice-friendly).

SELECT a.*
FROM luoghi a, aree b
WHERE ST_Intersects(a.posizione, b.posizione);

--2c. Buffer
--ST_Buffer(posizione, distanza) → crea area attorno a un oggetto.
--Da usare solo se necessario (non indicizzabile).

SELECT ST_Buffer(posizione, 100) FROM luoghi;

--2d. Nearest Neighbor (KNN)
--Ricerca più vicini con GiST.

SELECT *
FROM luoghi
ORDER BY posizione <-> ST_SetSRID(ST_MakePoint(1500000, 5000000), 3003)
LIMIT 5;

-- Controlla punti COMPLETAMENTE DENTRO il poligono con id=1
SELECT *
FROM luoghi
WHERE ST_Contains(
    (SELECT posizione FROM aree WHERE id = 1),
    posizione
);

-- Punti che TOCCANO il poligono id=1
SELECT *
FROM luoghi
WHERE ST_Intersects(posizione, (SELECT posizione FROM aree WHERE id = 1));


-- Poligoni che intersecano il poligono con id=1
SELECT *
FROM aree
WHERE ST_Intersects(
    posizione,
    (SELECT posizione FROM aree WHERE id = 1)
);

-- calcola geometria = Sovrapposizione geometrica con poligono id=1
SELECT ST_Intersection(posizione, (SELECT posizione FROM aree WHERE id = 1))
FROM aree
WHERE ST_Intersects(posizione, (SELECT posizione FROM aree WHERE id = 1));

-- Controlla punti che ricadono dentro le aree
SELECT aree.nome, luoghi.nome
FROM luoghi
JOIN aree
ON ST_Contains(
    aree.posizione,
    luoghi.posizione
);
