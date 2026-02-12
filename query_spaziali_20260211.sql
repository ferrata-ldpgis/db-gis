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
