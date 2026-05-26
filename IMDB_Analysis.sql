--- converting tsv files to parquet file


COPY (
    SELECT *
    FROM read_csv_auto(
        'C:\Users\krris\OneDrive\Documents\Data Science\Projects\IMDB\tsv_files\name.basics.tsv',
        delim='\t'
    )
)
TO 'C:\Users\krris\OneDrive\Documents\Data Science\Projects\IMDB\parquet\name.basics.parquet'
(FORMAT PARQUET);


COPY (
    SELECT *
    FROM read_csv_auto(
        'C:\Users\krris\OneDrive\Documents\Data Science\Projects\IMDB\tsv_files\title.akas.tsv',
        delim='\t'
    )
)
TO 'C:\Users\krris\OneDrive\Documents\Data Science\Projects\IMDB\parquet\title.akas.parquet'
(FORMAT PARQUET);


COPY (
    SELECT *
    FROM read_csv_auto(
        'C:\Users\krris\OneDrive\Documents\Data Science\Projects\IMDB\tsv_files\title.basics.tsv',
        delim='\t'
    )
)
TO 'C:\Users\krris\OneDrive\Documents\Data Science\Projects\IMDB\parquet\title.basics.parquet'
(FORMAT PARQUET);


COPY (
    SELECT *
    FROM read_csv_auto(
        'C:\Users\krris\OneDrive\Documents\Data Science\Projects\IMDB\tsv_files\title.crew.tsv',
        delim='\t'
    )
)
TO 'C:\Users\krris\OneDrive\Documents\Data Science\Projects\IMDB\parquet\title.crew.parquet'
(FORMAT PARQUET);


COPY (
    SELECT *
    FROM read_csv_auto(
        'C:\Users\krris\OneDrive\Documents\Data Science\Projects\IMDB\tsv_files\title.episode.tsv',
        delim='\t'
    )
)
TO 'C:\Users\krris\OneDrive\Documents\Data Science\Projects\IMDB\parquet\title.episode.parquet'
(FORMAT PARQUET);


COPY (
    SELECT *
    FROM read_csv_auto(
        'C:\Users\krris\OneDrive\Documents\Data Science\Projects\IMDB\tsv_files\title.principals.tsv',
        delim='\t'
    )
)
TO 'C:\Users\krris\OneDrive\Documents\Data Science\Projects\IMDB\parquet\title.principals.parquet'
(FORMAT PARQUET);


COPY (
    SELECT *
    FROM read_csv_auto(
        'C:\Users\krris\OneDrive\Documents\Data Science\Projects\IMDB\tsv_files\title.ratings.tsv',
        delim='\t'
    )
)
TO 'C:\Users\krris\OneDrive\Documents\Data Science\Projects\IMDB\parquet\title.ratings.parquet'
(FORMAT PARQUET);




CREATE OR REPLACE TABLE name AS
SELECT
    nconst,
    primaryName,
    TRY_CAST(NULLIF(birthYear, '\N') AS INTEGER) AS birthYear,
    TRY_CAST(NULLIF(deathYear, '\N') AS INTEGER) AS deathYear,
    primaryProfession,
    knownForTitles
FROM name;

CREATE OR REPLACE TABLE title AS
SELECT
    NULLIF(tconst,'\N') AS tconst,
    NULLIF(titleType, '\N') AS titleType,
    NULLIF(primaryTitle, '\N') AS primaryTitle,
    NULLIF(originalTitle, '\N') AS originalTitle,
    TRY_CAST(isAdult AS integer) AS isAdult,
    TRY_CAST(NULLIF(startYear, '\N') AS INTEGER) AS startYear,
    TRY_CAST(NULLIF(endYear, '\N') AS INTEGER) AS endYear,
    TRY_CAST(NULLIF(runtimeMinutes, '\N') AS INTEGER) AS runtimeMinutes,
    NULLIF(genres, '\N') AS genres
FROM read_parquet(
	'C:/Users/krris/OneDrive/Documents/Data Science/Projects/IMDB/parquet/title.basics.parquet'
);


show tables;

select * from name;
select * from akas limit 200;
select * from title;
select * from crew;
select * from episode;
select * from principals limit 200;
select * from ratings;

describe name;

-- LEVEL 1 — BASIC
-- 
-- 1. Find top 10 highest-rated movies based on averageRating.

SELECT 
	t.PrimaryTitle,
	t.originalTitle,
	t.titleType,
	t.genres,
	r.averageRating,
	r.numVotes
FROM title t 
inner join ratings r
on 	t.tconst = r.tconst
order by 
	averageRating desc,
	numVotes desc,
	PrimaryTitle asc
limit 10;


-- 2. Find movies with more than 1,000,000 votes.

select
	t.PrimaryTitle,
	r.numVotes
from title t
inner join ratings r
on t.tconst = r.tconst
where r.numVotes > 1000000;

-- 3. Count number of titles per titleType.

SELECT 
	titleType,
	count(PrimaryTitle) as titleCount
from title
group by 
	titleType
order BY titleCount desc;

-- 4. List all actors born after 1990.

select
	primaryName,
	birthYear
from name
where birthYear > 1990;

-- 5. Count how many people have 'actor' in primaryProfession.

select 
	count(*) as Total_actors
FROM name
where regexp_matches(primaryProfession, '(^|,)actor(,|$)');

select 
	count(*) as Total_actors
FROM name
where primaryProfession like '%actor%' or primaryProfession like '%actress%';


-- 6. Find people with no deathYear.

select 
	PrimaryName as Name,
	birthYear,
	deathYear
from name
where deathYear isnull;

-- 7. List movies released after 2015.

select
	PrimaryTitle as Movie_Name,
	titleType,
	startYear
from title
where startYear > 2015 AND 
titleType = 'movie';

-- 8. Find movies with runtime greater than 120 minutes.

select
	PrimaryTitle as Movie_Name,
	runtimeMinutes
from title
where runtimeMinutes > 120;

-- 9. Count number of movies released per year.

SELECT
	startYear,
	count(PrimaryTitle) as Movie_count
FROM title
where titleType = 'movie'
group by tartYear;

select * from title
where startYear > 2026;

-- LEVEL 2 — INTERMEDIATE (JOINS)
-- 
-- 10. Find top 20 movies with highest rating and more than 100,000 votes.

SELECT 
	t.primaryTitle,
	t. titleType,
	r.averageRating,
	r.numvotes
from title t
inner join ratings r
on t.tconst = r.tconst and titleType = 'movie'
where r.numVotes > 1000000
order by r.averageRating desc
limit 20;


-- 11. Calculate average movie rating per year.

select
	startYear,
	round(avg(r.averageRating),2)
from title t
inner join ratings r
on 
	t.tconst = r.tconst
group by startYear;

-- 12. Find the best-rated movie for each year.

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
    INNER JOIN ratings r
    ON t.tconst = r.tconst
)

SELECT
    startYear,
    primaryTitle,
    averageRating
FROM ranked_movies
WHERE rn = 1
ORDER BY startYear;

-- 13. List actors in a given movie.

select 
	t.primaryTitle as MovieName,
	n.primaryName as Actors,
	p.category
from title t
inner join principals p
on t.tconst = p.tconst
inner join name n
on p.nconst = n.nconst
where p.category in ('actor', 'actress')
and t.titleType = 'movie'
and t.primaryTitle = 'Fine Gold';

-- 14. Count number of actors per movie.

select
	t.primaryTitle as movieName,
	count(distinct p.nconst) TotalActors
from title t
inner join principals p
on t.tconst = p.tconst
where p.category in ('actor', 'actress')
and t.titleType = 'movie'
group by 
	t.tconst,
	t.primaryTitle,
	t.startYear
order by TotalActors desc;


-- 15. Find all movies featuring a specific actor.

SELECT 
	t.primaryTitle as MovieName,
	n.primaryName as Actor_Name,
	category
from title t
inner join principals p
on t.tconst = p.tconst
inner join name n
on p.nconst = n.nconst
where p.category in ('actor', 'actress')
and n.primaryName = 'Leonardo DiCaprio';

-- 16. Find movies available in multiple regions.

select
	t.primaryTitle as movieName,
	count(distinct a.region) as totalRegions,
	string_agg(distinct a.region, ',') as regions
from title t
inner join akas a
on t.tconst = a.tconst
where t.titleType = 'movie'
and a.region is not null
group by
	t.tconst,
	t.primaryTitle
HAVING count(distinct a.region) > 1
order by totalRegions desc;

-- 17. Count number of titles per region.

SELECT
	a.region as Region,
	count(distinct t.primaryTitle) as totalTitles,
	round(avg(r.averageRating), 2) as avgRating
FROM title t
inner join akas a
on t.tconst = a.tconst
inner join ratings r
on t.tconst = r.tconst
where t.titleType = 'movie'
and a.region is not null
GROUP BY a.region
order by totalTitles desc;

-- 18. Find movies with more than 3 alternate titles.

SELECT 
	t.primaryTitle as movieName,
	count(distinct a.title) as titleCount
from title t
inner join akas a
on t.tconst = a.tconst
where t.titleType = 'movie'
group by 
	t.tconst,
	t.primaryTitle
having count(distinct a.title) > 3
order by titleCount desc;

-- 
-- LEVEL 3 — ADVANCED
-- 
-- 19. Find top 10 actors with highest average movie rating.


select
	n.nconst,
	n.primaryName as actorName,
	count(distinct p.tconst) as totalMovies,
	string_agg(distinct t.primaryTitle, ', ') as Movies,
	round(avg(r.averageRating),2) as averageRating,
	sum(r.numVotes) as totalVotes
from principals p
inner join name n
on p.nconst = n.nconst
inner join ratings r
on p.tconst = r.tconst
inner join title t
on t.tconst = p.tconst
where p.category in ('actor', 'actress')
and t.titleType = 'movie'
and r.numvotes >= 10000
group by 
	n.nconst,
	n.primaryName
having count(distinct p.tconst) >= 5
order by 
	averageRating desc,
	totalVotes desc
limit 10;


-- 20. Find actors who have worked in at least 10 movies.

SELECT 
	n.nconst as actorID,
	n.primaryName as actorName,
	count(distinct t.tconst) as totalMovies
from name n
inner join principals p
on n.nconst = p.nconst
inner join title t
on p.tconst = t.tconst
where t.titleType = 'movie'
and p.category in ('actor', 'actress')
and t.startYear is not null
group by 
	n.nconst,
	n.primaryName
having count(distinct t.tconst) >= 10
order by totalMovies desc;

-- 21. Find most versatile actors (working across multiple genres).

with genre_split as (
	SELECT 
		n.nconst,
		n.primaryName,
		unnest(string_split(t.genres, ',')) as genre
	from title t
	inner join principals p
	on t.tconst = p.tconst
	inner join name n
	on p.nconst = n.nconst
	where
		t.titleType = 'movie'
		and p.category in ('actor', 'actress')
)
select 
	nconst,
	primaryName,
	count(distinct genre) as genreCount
from genre_split
group by nconst, primaryName
having count(distinct genre) > 7
order by genreCount desc, primaryName desc;



select count(distinct genre) from (SELECT unnest(string_split(genres, ',')) as genre from title); -- total genres


-- 22. Find top directors based on average movie rating.

select 
	n.primaryName as directorName,
	count(distinct t.tconst) as movieDirected,
	round(avg(r.averageRating), 2) as avgRatings,
	sum(r.numvotes) as totalVotes
from name n
inner join principals p
on n.nconst = p.nconst
inner join ratings r
on p.tconst = r.tconst
inner join title t
on p.tconst = t.tconst
where t.titleType = 'movie'
and p.category = 'director'
and r.numVotes >= 10000
group by  
	n.nconst,
	n.primaryName
having count(distinct t.primaryTitle) >= 5
order by 
	avgRatings desc,
	totalVotes desc;

-- 23. Find directors with most movies.

select
	n.primaryName as directorName,
	count(distinct t.tconst) as totalMovies
from name n
inner join principals p
on n.nconst = p.nconst
inner join title t
on p.tconst = t.tconst
where t.titleType = 'movie'
and p.category = 'director'
group by 
	n.nconst,
	n.primaryName 
order by totalMovies desc;

-- 24. Find directors with highest total votes.

SELECT 
	n.primaryName as directorName,
	count(distinct p.tconst) as totalMovies,
	sum(r.numVotes) as totalVotes,
	round(sum(r.numvotes)/count(distinct p.tconst), 0) as avgVotesPerMovie
from name n
inner join principals p
on n.nconst = p.nconst
inner join ratings r
on p.tconst = r.tconst
where p.category = 'director'
group by
	n.nconst,
	n.primaryName
order by 
	totalVotes desc,
	avgVotesPerMovie desc;

-- 25. Analyze if movies with higher votes have higher ratings.

SELECT 
	case
		when r.numVotes < 1000 then '<1K'
		when r.numVotes < 10000 then '1K-10K'
		when r.numVotes < 100000 then '10K-100K'
		when r.numVotes < 1000000 then '100K-1M'
		else '1M+'
	end as voteBucket,
	count(*) as totalMovies,
	round(avg(r.averageRating), 2) as avgRating 
from ratings r
inner join title t
on t.tconst = r.tconst
where t.titleType = 'movie'
group by voteBucket
order by min(r.numVotes);	


-- 26. Find correlation between numVotes and averageRating.

select
	corr(r.numVotes, r.averageRating) as correlation
from ratings r 
inner join title t
on r.tconst = t.tconst
where t.titleType = 'movie';


WITH stats AS (
    SELECT
        COUNT(*) AS n,
        SUM(numVotes) AS sum_x,
        SUM(averageRating) AS sum_y,
        SUM(numVotes * averageRating) AS sum_xy,
        SUM(POW(numVotes, 2)) AS sum_x2,
        SUM(POW(averageRating, 2)) AS sum_y2
    FROM ratings r
    JOIN title t
        ON r.tconst = t.tconst
    WHERE t.titleType = 'movie'
)
SELECT
(
    n * sum_xy - sum_x * sum_y
)
/
SQRT(
    (n * sum_x2 - POW(sum_x, 2))
    *
    (n * sum_y2 - POW(sum_y, 2))
) AS correlation
FROM stats;
-- 
-- LEVEL 4 — ADVANCED JOINS (ALL TABLES)
-- 
-- 27. Find top movies with rating > 8 that are available in multiple languages and list their main actors.

with movie_summary as (
	select
		t.tconst as titleID,
		t.primaryTitle as movieName,
		count(distinct a.region) as totalRegions,
		string_agg(distinct n.primaryName, ', ') as Actors,
		max(r.averageRating) as avgRating,
		max(numVotes) as totalVotes
	from name n
	inner join principals p
	on n.nconst = p.nconst
	inner join title t
	on p.tconst = t.tconst
	inner join akas a
	on t.tconst = a.tconst
	inner join ratings r
	on t.tconst = r.tconst
	where r.averageRating > 8
	and t.titleType = 'movie'
	and p.category in ('actor', 'actress')
	and p.ordering <= 3   -- lower the order the more prominent the cast member
	and r.numVotes > 10000
	group by
		t.tconst,
		t.primaryTitle
	having count(distinct a.region) >= 2
)
select 
	*
from movie_summary
order by 
	avgRating desc,
	totalVotes desc;

-- 28. For each actor, calculate total movies, average rating, and best movie.

with actor_movies as (
	SELECT 
		n.nconst,
		n.primaryName,
		t.primaryTitle,
		r.averageRating,
		count(distinct t.tconst) over (
			partition by n.nconst
		) as totalMovies,
		row_number() over (
			partition by n.nconst
			order by
				r.averageRating desc,
				r.numVotes desc
		) as rn,
		round(
			avg(averageRating) over (
			partition by n.nconst
			),
			2
		) as avgRating
	from name n
	inner join principals p
	on p.nconst = n.nconst
	inner join title t
	on p.tconst = t.tconst
	inner join ratings r
	on t.tconst = r.tconst
	where t.titleType = 'movie'
	and p.category in ('actor', 'actress')
)
select
	nconst,
	primaryName as actorName,
	totalMovies,
	avgRating,
	primaryTitle as bestMovieTitle,
	averageRating as bestMovieRating
from actor_movies
where rn = 1;


-- 29. Find movies released in the highest number of countries.
SELECT
    t.tconst,
    t.primaryTitle,
    COUNT(DISTINCT a.region) AS totalCountries
FROM title t
JOIN akas a
    ON t.tconst = a.tconst
WHERE t.titleType = 'movie'
  AND a.region IS NOT NULL
GROUP BY
    t.tconst,
    t.primaryTitle
ORDER BY totalCountries DESC;


-- 30 Show globally released movies and their cast.

with global_movies as(
	select
		t.tconst,
		t.primaryTitle,
		count(distinct a.region) as regionCount
	from akas a
	inner join title t
	on t.tconst = a.tconst
	where t.titleType = 'movie'
	and a.region is not null
	group by 
		t.tconst,
		t.primaryTitle
	having count(distinct a.region) >= 10
)
select 
	g.tconst as movieID,
	g.primaryTitle as movie,
	g.regionCount,
	string_agg(distinct n.primaryName, ' ,') as Cast
from global_movies g
inner join principals p
on g.tconst = p.tconst
inner join name n
on p.nconst = n.nconst
where p.category in ('actor', 'actress')
group by 
	g.tconst,
	g.primaryTitle,
	g.regionCount
order by 
	regionCount desc,
	movieID desc;

-- 31. Find actors who appear in globally released movies.
with global_movies as(
	select
		t.tconst,
		t.primaryTitle,
		count(distinct a.region) as regionCount
	from akas a
	inner join title t
	on t.tconst = a.tconst
	where t.titleType = 'movie'
	and a.region is not null
	group by 
		t.tconst,
		t.primaryTitle
	having count(distinct a.region) >= 10
)
select 
	n.primaryName as actorName,
	count(distinct g.tconst) as globalMovieCount,
	string_agg(distinct g.primaryTitle, ' ,') as appearedIN
from global_movies g
inner join principals p
on g.tconst = p.tconst
inner join name n
on p.nconst = n.nconst
where p.category in ('actor', 'actress')
group by 
	n.nconst,
	n.primaryName
order by 
	globalMovieCount desc;

-- 
-- LEVEL 5 — PORTFOLIO LEVEL
-- 
-- 32. Rank actors using score = avg_rating * log(num_votes) * movie_count.

with carrer as (
	select
		n.primaryName as actor,
		count(distinct t.tconst) as movie_count,
		round(avg(r.averageRating),2) as avg_Rating,
		sum(numVotes) as totalVotes
	from name n
	inner join principals p
	on p.nconst = n.nconst
	inner join title t
	on t.tconst = p.tconst
	inner join ratings r
	on t.tconst = r.tconst
	where t.titleType = 'movie'
	and p.category in ('actor', 'actress')
	group by
		n.nconst,
		n.primaryName
)
select
	*,
	avg_rating * log(totalVotes) * movie_count as score,
	dense_rank() over (
		order by score desc
	) rn
from carrer;

-- 33. Find underrated movies (high rating but low votes).

select
	t.primaryTitle as movie,
	r.averageRating,
	numVotes
from ratings r
inner join title t
on t.tconst = r.tconst
where t.titleType = 'movie'
and r.averageRating >= 8
and r.numVotes BETWEEN 100 and 5000
order by
	averageRating desc,
	numVotes asc;

-- 34. Find most influential movies (high rating, high votes, wide release).

select
	t.primaryTitle as movieName,
	r.averageRating as avgRating,
	r.numVotes as Votes,
	count(distinct a.region) as region_count
from title t
inner join ratings r
on t.tconst = r.tconst
inner join akas a
on t.tconst = a.tconst
where t.titleType = 'movie'
and r.averageRating >= 8
and r.numVotes >= 10000
and a.region is not null
group by 
	t.tconst,
	t.primaryTitle,
	r.averageRating,
	r.numVotes
having count(distinct a.region) >= 4
order by
	avgRating desc,
	Votes desc;

-- 35. Analyze actor career growth (compare first movie vs latest movie ratings).

WITH actor_movies AS (
    SELECT
        n.nconst,
        n.primaryName AS actor,
        t.tconst,
        t.primaryTitle,
        t.startYear,
        r.averageRating,

        ROW_NUMBER() OVER (
            PARTITION BY n.nconst
            ORDER BY t.startYear ASC, r.numVotes DESC
        ) AS first_movie,

        ROW_NUMBER() OVER (
            PARTITION BY n.nconst
            ORDER BY t.startYear DESC, r.numVotes DESC
        ) AS latest_movie
    FROM name n
    JOIN principals p
        ON n.nconst = p.nconst
    JOIN title t
        ON p.tconst = t.tconst
    JOIN ratings r
        ON t.tconst = r.tconst
    WHERE t.titleType = 'movie'
      AND p.category IN ('actor','actress')
      AND t.startYear IS NOT NULL
)
SELECT
    f.actor,
    f.primaryTitle AS firstMovie,
    f.startYear AS firstYear,
    f.averageRating AS firstRating,
    l.primaryTitle AS latestMovie,
    l.startYear AS latestYear,
    l.averageRating AS latestRating,
    ROUND(
        l.averageRating - f.averageRating,
        2
    ) AS ratingChange
FROM actor_movies f
JOIN actor_movies l
    ON f.nconst = l.nconst
WHERE f.first_movie = 1
  AND l.latest_movie = 1
ORDER BY ratingChange DESC;


-- 36. Find which actor dominates which genre.

with popularity as (
	select
		t.genres as genre,
		n.primaryName as actor,
		round(avg(averageRating),2) as avgRating,
		sum(numVotes) as votes
	from title t
	inner join ratings r
	on t.tconst = r.tconst
	inner join principals p
	on t.tconst = p.tconst
	inner join name n
	on p.nconst = p.nconst
	where t.titleType = 'movie' 
	and p.category in ('actor', 'actress')
	and r.numVotes >= 1000,
	and t.genres is not null
	group by
		t.genres,
		n.nconst,
		n.primaryName
	having count(distinct t.tconst) >= 7
),
ranked as (
	select
		*,
		dense_rank() over (
			partition by genre
			order by
				avgRating desc,
				votes desc
		) as rn
	from popularity 
)
select 
	*
from ranked
where rn = 1;

-- 37. Find highest-rated genre overall.

with genre_split as (
	SELECT 
		t.tconst,
		unnest(string_split(t.genres, ',')) as genre,
		r.averageRating,
		r.numVotes as votes
	from title t
	inner join ratings r
	on t.tconst = r.tconst
	where t.titleType = 'movie'
	and t.genres is not null
	and r.numVotes > 1000
)
SELECT 
	genre,
	round(avg(averageRating)) as avgRating,
	sum(votes) as totalVotes,
	count(distinct tconst) as movieCount
from genre_split
group by genre
having count(distinct tconst) > 50
order by 
	avgRating desc,
	totalVotes desc;


-- BONUS (INTERVIEW LEVEL)
-- 
-- 38. Rank movies within each year using window functions.

select 
	t.startYear,
	t.tconst,
	t.primaryTitle as movie,
	r.averageRating as avgRating,
	r.numVotes as Votes,
	dense_rank() over (
		partition by t.startYear
		order by 
			r.averageRating desc,
			r.numVotes desc		
	) rn
from title t
inner join ratings r
on t.tconst = r.tconst
where t.titleType = 'movie'
and t.startYear is not null
order by t.startYear;



-- 39. Find top 3 movies per year.

with movie_ranked as (
	select 
		t.startYear,
		t.tconst,
		t.primaryTitle as movie,
		r.averageRating as avgRating,
		r.numVotes as Votes,
		dense_rank() over (
			partition by t.startYear
			order by 
				r.averageRating desc,
				r.numVotes desc		
		) rn
	from title t
	inner join ratings r
	on t.tconst = r.tconst
	where t.titleType = 'movie'
	and t.startYear is not null
)
select *
from movie_ranked 
where rn < 4
order BY startYear, rn;


-- 40. Normalize primaryProfession column.

select
	nconst,
 	primaryName as Name,
 	unnest(string_split(primaryProfession, ','))  as profession
from name;

-- 41. Suggest top movies for Netflix acquisition based on rating, votes, and region availability.

with movie_popularity as (
	select
		t.tconst,
		t.primaryTitle as movie,
		r.averageRating as avgRating,
		r.numVotes as votes,
		count(distinct a.region) as regionCount
	from title t
	inner join ratings r
	on t.tconst = r.tconst
	inner join akas a
	on t.tconst = a.tconst
	where t.titleType = 'movie'
	and a.region is not null
	group by
		t.tconst,
		t.primaryTitle,
		r.averageRating,
		r.numVotes
)
select
	*,
	round(
		avgRating *
		log(votes) *
		regionCount,
		2
	) as acquisitionScore
from movie_popularity
where avgRating >= 7
and votes > 10000
order by acquisitionScore desc;


