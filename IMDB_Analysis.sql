-- ============================================================
--  IMDB DATA ANALYSIS — DuckDB SQL
--  Dataset : IMDB Non-Commercial Datasets (TSV → Parquet)
--  Tool    : DuckDB
--  Author  : Krrish_Rana
-- ============================================================


-- ============================================================
--  SECTION 0 — DATA INGESTION (TSV → PARQUET)
-- ============================================================

COPY (SELECT * FROM read_csv_auto('tsv_files/name.basics.tsv',      delim='\t'))
TO 'parquet/name.basics.parquet'       (FORMAT PARQUET);

COPY (SELECT * FROM read_csv_auto('tsv_files/title.akas.tsv',       delim='\t'))
TO 'parquet/title.akas.parquet'        (FORMAT PARQUET);

COPY (SELECT * FROM read_csv_auto('tsv_files/title.basics.tsv',     delim='\t'))
TO 'parquet/title.basics.parquet'      (FORMAT PARQUET);

COPY (SELECT * FROM read_csv_auto('tsv_files/title.crew.tsv',       delim='\t'))
TO 'parquet/title.crew.parquet'        (FORMAT PARQUET);

COPY (SELECT * FROM read_csv_auto('tsv_files/title.episode.tsv',    delim='\t'))
TO 'parquet/title.episode.parquet'     (FORMAT PARQUET);

COPY (SELECT * FROM read_csv_auto('tsv_files/title.principals.tsv', delim='\t'))
TO 'parquet/title.principals.parquet'  (FORMAT PARQUET);

COPY (SELECT * FROM read_csv_auto('tsv_files/title.ratings.tsv',    delim='\t'))
TO 'parquet/title.ratings.parquet'     (FORMAT PARQUET);


-- ============================================================
--  SECTION 1 — TABLE CREATION WITH CLEANING
-- ============================================================

-- Clean name table: cast year columns, replace '\N' with NULL
CREATE OR REPLACE TABLE name AS
SELECT
    nconst,
    primaryName,
    TRY_CAST(NULLIF(birthYear, '\N') AS INTEGER)  AS birthYear,
    TRY_CAST(NULLIF(deathYear, '\N') AS INTEGER)  AS deathYear,
    primaryProfession,
    knownForTitles
FROM read_parquet('parquet/name.basics.parquet');

-- Clean title table: replace '\N' sentinels, cast numeric fields
CREATE OR REPLACE TABLE title AS
SELECT
    NULLIF(tconst,          '\N') AS tconst,
    NULLIF(titleType,       '\N') AS titleType,
    NULLIF(primaryTitle,    '\N') AS primaryTitle,
    NULLIF(originalTitle,   '\N') AS originalTitle,
    TRY_CAST(isAdult AS INTEGER)  AS isAdult,
    TRY_CAST(NULLIF(startYear,       '\N') AS INTEGER) AS startYear,
    TRY_CAST(NULLIF(endYear,         '\N') AS INTEGER) AS endYear,
    TRY_CAST(NULLIF(runtimeMinutes,  '\N') AS INTEGER) AS runtimeMinutes,
    NULLIF(genres, '\N') AS genres
FROM read_parquet('parquet/title.basics.parquet');


-- ============================================================
--  LEVEL 1 — BASIC
-- ============================================================

-- Q1. Top 10 highest-rated movies
SELECT
    t.primaryTitle,
    t.originalTitle,
    t.titleType,
    t.genres,
    r.averageRating,
    r.numVotes
FROM title t
INNER JOIN ratings r ON t.tconst = r.tconst
WHERE t.titleType = 'movie'
ORDER BY r.averageRating DESC, r.numVotes DESC, t.primaryTitle ASC
LIMIT 10;


-- Q2. Movies with more than 1,000,000 votes
SELECT
    t.primaryTitle,
    r.numVotes
FROM title t
INNER JOIN ratings r ON t.tconst = r.tconst
WHERE r.numVotes > 1_000_000
AND t.titleType = 'movie';


-- Q3. Number of titles per titleType
SELECT
    titleType,
    COUNT(primaryTitle) AS titleCount
FROM title
GROUP BY titleType
ORDER BY titleCount DESC;


-- Q4. Actors born after 1990
SELECT
    primaryName,
    birthYear
FROM name n
INNER JOIN principals p
ON n.nconst = p.nconst
WHERE birthYear > 1990
AND p.category IN ('actor', 'actress');


-- Q5. Count people with 'actor' or 'actress' in primaryProfession
SELECT COUNT(*) AS total_actors
FROM name
WHERE primaryProfession LIKE '%actor%'
   OR primaryProfession LIKE '%actress%';


-- Q6. People with no recorded death year (likely still alive)
SELECT
    primaryName AS name,
    birthYear,
    deathYear
FROM name
WHERE deathYear IS NULL;


-- Q7. Movies released after 2015
SELECT
    primaryTitle AS movie,
    titleType,
    startYear
FROM title
WHERE startYear > 2015
  AND titleType = 'movie';


-- Q8. Movies with runtime greater than 120 minutes
SELECT
    primaryTitle AS movie,
    runtimeMinutes
FROM title
WHERE runtimeMinutes > 120;


-- Q9. Number of movies released per year
SELECT
    startYear,
    COUNT(primaryTitle) AS movie_count
FROM title
WHERE titleType = 'movie'
GROUP BY startYear
ORDER BY startYear;


-- ============================================================
--  LEVEL 2 — INTERMEDIATE JOINS
-- ============================================================

-- Q10. Top 20 movies: rating + more than 1M votes
SELECT
    t.primaryTitle,
    t.titleType,
    r.averageRating,
    r.numVotes
FROM title t
INNER JOIN ratings r ON t.tconst = r.tconst AND t.titleType = 'movie'
WHERE r.numVotes > 1_000_000
ORDER BY r.averageRating DESC
LIMIT 20;


-- Q11. Average movie rating per year
SELECT
    t.startYear,
    ROUND(AVG(r.averageRating), 2) AS avg_rating
FROM title t
INNER JOIN ratings r ON t.tconst = r.tconst
WHERE t.titleType = 'movie'
GROUP BY t.startYear
ORDER BY t.startYear;


-- Q12. Best-rated movie for each year (window function)
WITH ranked_movies AS (
    SELECT
        t.startYear,
        t.primaryTitle,
        r.averageRating,
        ROW_NUMBER() OVER (
            PARTITION BY t.startYear
            ORDER BY r.averageRating DESC
        ) AS rn
    FROM title t
    INNER JOIN ratings r ON t.tconst = r.tconst
    WHERE t.titleType = 'movie'
)
SELECT startYear, primaryTitle, averageRating
FROM ranked_movies
WHERE rn = 1
ORDER BY startYear;


-- Q13. List actors in a specific movie (example: 'Inception')
SELECT
    t.primaryTitle AS movie,
    n.primaryName  AS actor,
    p.category
FROM title t
INNER JOIN principals p ON t.tconst = p.tconst
INNER JOIN name n       ON p.nconst = n.nconst
WHERE p.category IN ('actor', 'actress')
  AND t.titleType = 'movie'
  AND t.primaryTitle = 'Inception';   -- replace with any movie


-- Q14. Number of actors per movie
SELECT
    t.primaryTitle   AS movie,
    COUNT(DISTINCT p.nconst) AS total_actors
FROM title t
INNER JOIN principals p ON t.tconst = p.tconst
WHERE p.category IN ('actor', 'actress')
  AND t.titleType = 'movie'
GROUP BY t.tconst, t.primaryTitle, t.startYear
ORDER BY total_actors DESC;


-- Q15. All movies featuring a specific actor (example: Leonardo DiCaprio)
SELECT
    t.primaryTitle AS movie,
    n.primaryName  AS actor,
    p.category
FROM title t
INNER JOIN principals p ON t.tconst = p.tconst
INNER JOIN name n       ON p.nconst = n.nconst
WHERE p.category IN ('actor', 'actress')
  AND n.primaryName = 'Leonardo DiCaprio';  -- replace with any actor


-- Q16. Movies available in multiple regions
SELECT
    t.primaryTitle               AS movie,
    COUNT(DISTINCT a.region)     AS total_regions,
    STRING_AGG(DISTINCT a.region, ', ') AS regions
FROM title t
INNER JOIN akas a ON t.tconst = a.tconst
WHERE t.titleType = 'movie'
  AND a.region IS NOT NULL
GROUP BY t.tconst, t.primaryTitle
HAVING COUNT(DISTINCT a.region) > 1
ORDER BY total_regions DESC;


-- Q17. Number of titles per region with average rating
SELECT
    a.region                          AS region,
    COUNT(DISTINCT t.primaryTitle)    AS total_titles,
    ROUND(AVG(r.averageRating), 2)    AS avg_rating
FROM title t
INNER JOIN akas a    ON t.tconst = a.tconst
INNER JOIN ratings r ON t.tconst = r.tconst
WHERE t.titleType = 'movie'
  AND a.region IS NOT NULL
GROUP BY a.region
ORDER BY total_titles DESC;


-- Q18. Movies with more than 3 alternate titles
SELECT
    t.primaryTitle            AS movie,
    COUNT(DISTINCT a.title)   AS alt_title_count
FROM title t
INNER JOIN akas a ON t.tconst = a.tconst
WHERE t.titleType = 'movie'
GROUP BY t.tconst, t.primaryTitle
HAVING COUNT(DISTINCT a.title) > 3
ORDER BY alt_title_count DESC;


-- ============================================================
--  LEVEL 3 — ADVANCED
-- ============================================================

-- Q19. Top 10 actors by average movie rating (min 5 movies, min 10K votes each)
SELECT
    n.nconst,
    n.primaryName                           AS actor,
    COUNT(DISTINCT p.tconst)                AS total_movies,
    STRING_AGG(DISTINCT t.primaryTitle, ', ') AS movies,
    ROUND(AVG(r.averageRating), 2)          AS avg_rating,
    SUM(r.numVotes)                         AS total_votes
FROM principals p
INNER JOIN name n    ON p.nconst = n.nconst
INNER JOIN ratings r ON p.tconst = r.tconst
INNER JOIN title t   ON t.tconst = p.tconst
WHERE p.category IN ('actor', 'actress')
  AND t.titleType = 'movie'
  AND r.numVotes >= 10_000
GROUP BY n.nconst, n.primaryName
HAVING COUNT(DISTINCT p.tconst) >= 5
ORDER BY avg_rating DESC, total_votes DESC
LIMIT 10;


-- Q20. Actors who appeared in at least 10 movies
SELECT
    n.nconst                     AS actor_id,
    n.primaryName                AS actor,
    COUNT(DISTINCT t.tconst)     AS total_movies
FROM name n
INNER JOIN principals p ON n.nconst = p.nconst
INNER JOIN title t      ON p.tconst = t.tconst
WHERE t.titleType = 'movie'
  AND p.category IN ('actor', 'actress')
  AND t.startYear IS NOT NULL
GROUP BY n.nconst, n.primaryName
HAVING COUNT(DISTINCT t.tconst) >= 10
ORDER BY total_movies DESC;


-- Q21. Most versatile actors (worked across 7+ genres)
WITH genre_split AS (
    SELECT
        n.nconst,
        n.primaryName,
        UNNEST(STRING_SPLIT(t.genres, ',')) AS genre
    FROM title t
    INNER JOIN principals p ON t.tconst = p.tconst
    INNER JOIN name n       ON p.nconst = n.nconst
    WHERE t.titleType = 'movie'
      AND p.category IN ('actor', 'actress')
)
SELECT
    nconst,
    primaryName,
    COUNT(DISTINCT genre) AS genre_count
FROM genre_split
GROUP BY nconst, primaryName
HAVING COUNT(DISTINCT genre) > 7
ORDER BY genre_count DESC;


-- Q22. Top directors by average movie rating (min 5 movies, min 10K votes each)
SELECT
    n.primaryName                 AS director,
    COUNT(DISTINCT t.tconst)      AS movies_directed,
    ROUND(AVG(r.averageRating), 2) AS avg_rating,
    SUM(r.numVotes)               AS total_votes
FROM name n
INNER JOIN principals p ON n.nconst = p.nconst
INNER JOIN ratings r    ON p.tconst = r.tconst
INNER JOIN title t      ON p.tconst = t.tconst
WHERE t.titleType = 'movie'
  AND p.category = 'director'
  AND r.numVotes >= 10_000
GROUP BY n.nconst, n.primaryName
HAVING COUNT(DISTINCT t.tconst) >= 5
ORDER BY avg_rating DESC, total_votes DESC;


-- Q23. Directors with the most movies
SELECT
    n.primaryName             AS director,
    COUNT(DISTINCT t.tconst)  AS total_movies
FROM name n
INNER JOIN principals p ON n.nconst = p.nconst
INNER JOIN title t      ON p.tconst = t.tconst
WHERE t.titleType = 'movie'
  AND p.category = 'director'
GROUP BY n.nconst, n.primaryName
ORDER BY total_movies DESC;


-- Q24. Directors with highest total votes
SELECT
    n.primaryName                                          AS director,
    COUNT(DISTINCT p.tconst)                               AS total_movies,
    SUM(r.numVotes)                                        AS total_votes,
    ROUND(SUM(r.numVotes) / COUNT(DISTINCT p.tconst), 0)  AS avg_votes_per_movie
FROM name n
INNER JOIN principals p ON n.nconst = p.nconst
INNER JOIN ratings r    ON p.tconst = r.tconst
WHERE p.category = 'director'
GROUP BY n.nconst, n.primaryName
ORDER BY total_votes DESC;


-- Q25. Do higher-voted movies get better ratings? (vote bucket analysis)
SELECT
    CASE
        WHEN r.numVotes < 1_000     THEN '< 1K'
        WHEN r.numVotes < 10_000    THEN '1K – 10K'
        WHEN r.numVotes < 100_000   THEN '10K – 100K'
        WHEN r.numVotes < 1_000_000 THEN '100K – 1M'
        ELSE '1M+'
    END                           AS vote_bucket,
    COUNT(*)                      AS total_movies,
    ROUND(AVG(r.averageRating), 2) AS avg_rating
FROM ratings r
INNER JOIN title t ON t.tconst = r.tconst
WHERE t.titleType = 'movie'
GROUP BY vote_bucket
ORDER BY MIN(r.numVotes);


-- Q26. Correlation between numVotes and averageRating
SELECT CORR(r.numVotes, r.averageRating) AS correlation
FROM ratings r
INNER JOIN title t ON r.tconst = t.tconst
WHERE t.titleType = 'movie';


-- ============================================================
--  LEVEL 4 — ADVANCED JOINS (ALL TABLES)
-- ============================================================

-- Q27. Rating > 8 movies available in multiple regions with lead actors
WITH movie_summary AS (
    SELECT
        t.tconst,
        t.primaryTitle                            AS movie,
        COUNT(DISTINCT a.region)                  AS total_regions,
        STRING_AGG(DISTINCT n.primaryName, ', ')  AS lead_actors,
        MAX(r.averageRating)                      AS avg_rating,
        MAX(r.numVotes)                           AS total_votes
    FROM name n
    INNER JOIN principals p ON n.nconst = p.nconst
    INNER JOIN title t      ON p.tconst = t.tconst
    INNER JOIN akas a       ON t.tconst = a.tconst
    INNER JOIN ratings r    ON t.tconst = r.tconst
    WHERE r.averageRating > 8
      AND t.titleType = 'movie'
      AND p.category IN ('actor', 'actress')
      AND p.ordering <= 3
      AND r.numVotes > 10_000
    GROUP BY t.tconst, t.primaryTitle
    HAVING COUNT(DISTINCT a.region) >= 2
)
SELECT * FROM movie_summary
ORDER BY avg_rating DESC, total_votes DESC;


-- Q28. Per-actor: total movies, average rating, and best movie
WITH actor_movies AS (
    SELECT
        n.nconst,
        n.primaryName,
        t.primaryTitle,
        r.averageRating,
        COUNT(DISTINCT t.tconst) OVER (PARTITION BY n.nconst)           AS total_movies,
        ROUND(AVG(r.averageRating) OVER (PARTITION BY n.nconst), 2)     AS avg_rating,
        ROW_NUMBER() OVER (
            PARTITION BY n.nconst
            ORDER BY r.averageRating DESC, r.numVotes DESC
        ) AS rn
    FROM name n
    INNER JOIN principals p ON p.nconst = n.nconst
    INNER JOIN title t      ON p.tconst = t.tconst
    INNER JOIN ratings r    ON t.tconst = r.tconst
    WHERE t.titleType = 'movie'
      AND p.category IN ('actor', 'actress')
)
SELECT
    nconst,
    primaryName     AS actor,
    total_movies,
    avg_rating,
    primaryTitle    AS best_movie,
    averageRating   AS best_movie_rating
FROM actor_movies
WHERE rn = 1;


-- Q29. Movies released in the highest number of countries
SELECT
    t.tconst,
    t.primaryTitle,
    COUNT(DISTINCT a.region) AS total_countries
FROM title t
JOIN akas a ON t.tconst = a.tconst
WHERE t.titleType = 'movie'
  AND a.region IS NOT NULL
GROUP BY t.tconst, t.primaryTitle
ORDER BY total_countries DESC;


-- Q30. Globally released movies (10+ regions) with full cast
WITH global_movies AS (
    SELECT
        t.tconst,
        t.primaryTitle,
        COUNT(DISTINCT a.region) AS region_count
    FROM akas a
    INNER JOIN title t ON t.tconst = a.tconst
    WHERE t.titleType = 'movie'
      AND a.region IS NOT NULL
    GROUP BY t.tconst, t.primaryTitle
    HAVING COUNT(DISTINCT a.region) >= 10
)
SELECT
    g.tconst,
    g.primaryTitle               AS movie,
    g.region_count,
    STRING_AGG(DISTINCT n.primaryName, ', ') AS cast
FROM global_movies g
INNER JOIN principals p ON g.tconst = p.tconst
INNER JOIN name n       ON p.nconst = n.nconst
WHERE p.category IN ('actor', 'actress')
GROUP BY g.tconst, g.primaryTitle, g.region_count
ORDER BY g.region_count DESC;


-- Q31. Actors who appear in globally released movies (10+ regions)
WITH global_movies AS (
    SELECT
        t.tconst,
        t.primaryTitle,
        COUNT(DISTINCT a.region) AS region_count
    FROM akas a
    INNER JOIN title t ON t.tconst = a.tconst
    WHERE t.titleType = 'movie'
      AND a.region IS NOT NULL
    GROUP BY t.tconst, t.primaryTitle
    HAVING COUNT(DISTINCT a.region) >= 10
)
SELECT
    n.primaryName                                    AS actor,
    COUNT(DISTINCT g.tconst)                         AS global_movie_count,
    STRING_AGG(DISTINCT g.primaryTitle, ', ')        AS movies
FROM global_movies g
INNER JOIN principals p ON g.tconst = p.tconst
INNER JOIN name n       ON p.nconst = n.nconst
WHERE p.category IN ('actor', 'actress')
GROUP BY n.nconst, n.primaryName
ORDER BY global_movie_count DESC;


-- ============================================================
--  LEVEL 5 — PORTFOLIO LEVEL
-- ============================================================

-- Q32. Actor career score = avg_rating × log(total_votes) × movie_count
WITH career AS (
    SELECT
        n.nconst,
        n.primaryName                      AS actor,
        COUNT(DISTINCT t.tconst)           AS movie_count,
        ROUND(AVG(r.averageRating), 2)     AS avg_rating,
        SUM(r.numVotes)                    AS total_votes
    FROM name n
    INNER JOIN principals p ON p.nconst = n.nconst
    INNER JOIN title t      ON t.tconst = p.tconst
    INNER JOIN ratings r    ON t.tconst = r.tconst
    WHERE t.titleType = 'movie'
      AND p.category IN ('actor', 'actress')
    GROUP BY n.nconst, n.primaryName
)
SELECT
    *,
    ROUND(avg_rating * LOG(total_votes) * movie_count, 2) AS career_score,
    DENSE_RANK() OVER (ORDER BY avg_rating * LOG(total_votes) * movie_count DESC) AS rank
FROM career
ORDER BY career_score DESC;


-- Q33. Underrated movies (high rating, very few votes)
SELECT
    t.primaryTitle   AS movie,
    r.averageRating,
    r.numVotes
FROM ratings r
INNER JOIN title t ON t.tconst = r.tconst
WHERE t.titleType = 'movie'
  AND r.averageRating >= 8
  AND r.numVotes BETWEEN 100 AND 5_000
ORDER BY r.averageRating DESC, r.numVotes ASC;


-- Q34. Most influential movies (high rating + high votes + wide release)
SELECT
    t.primaryTitle            AS movie,
    r.averageRating           AS avg_rating,
    r.numVotes                AS votes,
    COUNT(DISTINCT a.region)  AS region_count
FROM title t
INNER JOIN ratings r ON t.tconst = r.tconst
INNER JOIN akas a    ON t.tconst = a.tconst
WHERE t.titleType = 'movie'
  AND r.averageRating >= 8
  AND r.numVotes >= 10_000
  AND a.region IS NOT NULL
GROUP BY t.tconst, t.primaryTitle, r.averageRating, r.numVotes
HAVING COUNT(DISTINCT a.region) >= 4
ORDER BY avg_rating DESC, votes DESC;


-- Q35. Actor career growth: first movie rating vs latest movie rating
WITH actor_movies AS (
    SELECT
        n.nconst,
        n.primaryName               AS actor,
        t.tconst,
        t.primaryTitle,
        t.startYear,
        r.averageRating,
        ROW_NUMBER() OVER (
            PARTITION BY n.nconst
            ORDER BY t.startYear ASC,  r.numVotes DESC
        ) AS first_rank,
        ROW_NUMBER() OVER (
            PARTITION BY n.nconst
            ORDER BY t.startYear DESC, r.numVotes DESC
        ) AS latest_rank
    FROM name n
    JOIN principals p ON n.nconst = p.nconst
    JOIN title t      ON p.tconst = t.tconst
    JOIN ratings r    ON t.tconst = r.tconst
    WHERE t.titleType = 'movie'
      AND p.category IN ('actor', 'actress')
      AND t.startYear IS NOT NULL
)
SELECT
    f.actor,
    f.primaryTitle    AS first_movie,
    f.startYear       AS first_year,
    f.averageRating   AS first_rating,
    l.primaryTitle    AS latest_movie,
    l.startYear       AS latest_year,
    l.averageRating   AS latest_rating,
    ROUND(l.averageRating - f.averageRating, 2) AS rating_change
FROM actor_movies f
JOIN actor_movies l ON f.nconst = l.nconst
WHERE f.first_rank = 1
  AND l.latest_rank = 1
ORDER BY rating_change DESC;


-- Q36. Which actor dominates which genre?
WITH popularity AS (
    SELECT
        t.genres                       AS genre,
        n.nconst,
        n.primaryName                  AS actor,
        ROUND(AVG(r.averageRating), 2) AS avg_rating,
        SUM(r.numVotes)                AS votes
    FROM title t
    INNER JOIN ratings r    ON t.tconst = r.tconst
    INNER JOIN principals p ON t.tconst = p.tconst
    INNER JOIN name n       ON p.nconst = n.nconst   -- fixed: was p.nconst = p.nconst
    WHERE t.titleType = 'movie'
      AND p.category IN ('actor', 'actress')
      AND r.numVotes >= 1000
      AND t.genres IS NOT NULL
    GROUP BY t.genres, n.nconst, n.primaryName
    HAVING COUNT(DISTINCT t.tconst) >= 7
),
ranked AS (
    SELECT
        *,
        DENSE_RANK() OVER (
            PARTITION BY genre
            ORDER BY avg_rating DESC, votes DESC
        ) AS rn
    FROM popularity
)
SELECT * FROM ranked WHERE rn = 1;


-- Q37. Highest-rated genre overall
WITH genre_split AS (
    SELECT
        t.tconst,
        UNNEST(STRING_SPLIT(t.genres, ',')) AS genre,
        r.averageRating,
        r.numVotes                          AS votes
    FROM title t
    INNER JOIN ratings r ON t.tconst = r.tconst
    WHERE t.titleType = 'movie'
      AND t.genres IS NOT NULL
      AND r.numVotes > 1000
)
SELECT
    genre,
    ROUND(AVG(averageRating), 2)  AS avg_rating,
    SUM(votes)                    AS total_votes,
    COUNT(DISTINCT tconst)        AS movie_count
FROM genre_split
GROUP BY genre
HAVING COUNT(DISTINCT tconst) > 50
ORDER BY avg_rating DESC, total_votes DESC;


-- ============================================================
--  BONUS — INTERVIEW / WINDOW FUNCTIONS
-- ============================================================

-- Q38. Rank all movies within each year
SELECT
    t.startYear,
    t.tconst,
    t.primaryTitle    AS movie,
    r.averageRating,
    r.numVotes,
    DENSE_RANK() OVER (
        PARTITION BY t.startYear
        ORDER BY r.averageRating DESC, r.numVotes DESC
    ) AS year_rank
FROM title t
INNER JOIN ratings r ON t.tconst = r.tconst
WHERE t.titleType = 'movie'
  AND t.startYear IS NOT NULL
ORDER BY t.startYear;


-- Q39. Top 3 movies per year
WITH movie_ranked AS (
    SELECT
        t.startYear,
        t.tconst,
        t.primaryTitle    AS movie,
        r.averageRating,
        r.numVotes,
        DENSE_RANK() OVER (
            PARTITION BY t.startYear
            ORDER BY r.averageRating DESC, r.numVotes DESC
        ) AS rn
    FROM title t
    INNER JOIN ratings r ON t.tconst = r.tconst
    WHERE t.titleType = 'movie'
      AND t.startYear IS NOT NULL
)
SELECT * FROM movie_ranked
WHERE rn <= 3
ORDER BY startYear, rn;


-- Q40. Normalize primaryProfession into individual rows
SELECT
    nconst,
    primaryName                                      AS name,
    UNNEST(STRING_SPLIT(primaryProfession, ','))     AS profession
FROM name;


-- Q41. Top movies for Netflix acquisition
--      Score = avg_rating × log(votes) × region_count
WITH movie_popularity AS (
    SELECT
        t.tconst,
        t.primaryTitle           AS movie,
        r.averageRating,
        r.numVotes               AS votes,
        COUNT(DISTINCT a.region) AS region_count
    FROM title t
    INNER JOIN ratings r ON t.tconst = r.tconst
    INNER JOIN akas a    ON t.tconst = a.tconst
    WHERE t.titleType = 'movie'
      AND a.region IS NOT NULL
    GROUP BY t.tconst, t.primaryTitle, r.averageRating, r.numVotes
)
SELECT
    *,
    ROUND(averageRating * LOG(votes) * region_count, 2) AS acquisition_score
FROM movie_popularity
WHERE averageRating >= 7
  AND votes > 10_000
ORDER BY acquisition_score DESC;
