# 🎬 IMDB SQL Analysis

> End-to-end SQL analysis of the IMDB Non-Commercial Dataset using **DuckDB** — covering data ingestion, cleaning, and 41 queries ranging from basic aggregations to portfolio-level analytics.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Dataset](#dataset)
- [Schema / ERD](#schema--erd)
- [Query Breakdown](#query-breakdown)
- [Sample Outputs](#sample-outputs)
- [Tech Stack](#tech-stack)
- [How to Run](#how-to-run)
- [Key Learnings](#key-learnings)

---

## Overview

This project explores the IMDB dataset with 41 SQL queries across 5 difficulty levels. The goal was to practice real-world SQL skills — joins across multiple tables, window functions, CTEs, and building composite scoring metrics — all against a large, messy, real-world dataset.

The dataset spans **7 TSV files**, converted to **Parquet** for efficient querying with DuckDB.

---

## Dataset

Source: [IMDB Non-Commercial Datasets](https://developer.imdb.com/non-commercial-datasets/)

| File | Table | Description |
|---|---|---|
| `name.basics.tsv` | `name` | People — actors, directors, writers |
| `title.basics.tsv` | `title` | All titles — movies, series, episodes |
| `title.akas.tsv` | `akas` | Alternate titles per region/language |
| `title.crew.tsv` | `crew` | Directors and writers per title |
| `title.episode.tsv` | `episode` | Episode ↔ parent series mapping |
| `title.principals.tsv` | `principals` | Top cast/crew per title |
| `title.ratings.tsv` | `ratings` | Average rating and vote count |

> **Note:** IMDB uses `\N` as a null sentinel — all tables are cleaned on load using `NULLIF` and `TRY_CAST`.

---

## Schema / ERD

![ERD](schema/erd.svg)

The `title` table is the central hub. `ratings` and `crew` have a 1-to-1 relationship with it. `akas`, `episode`, and `principals` are 1-to-many. `principals` acts as a bridge table connecting `title` and `name`.

---

## Query Breakdown

### Level 1 — Basic (Q1–Q9)
Filtering, aggregation, and `GROUP BY` fundamentals.

| # | Question |
|---|---|
| Q1 | Top 10 highest-rated movies |
| Q2 | Movies with more than 1M votes |
| Q3 | Count of titles per `titleType` |
| Q4 | Actors born after 1990 |
| Q5 | Count people with 'actor' in their profession |
| Q6 | People with no recorded death year |
| Q7 | Movies released after 2015 |
| Q8 | Movies with runtime > 120 minutes |
| Q9 | Movies released per year |

---

### Level 2 — Intermediate Joins (Q10–Q18)
Multi-table joins, `HAVING`, and string aggregation.

| # | Question |
|---|---|
| Q10 | Top 20 movies: high rating + 1M+ votes |
| Q11 | Average movie rating per year |
| Q12 | Best-rated movie per year (`ROW_NUMBER`) |
| Q13 | Actors in a given movie |
| Q14 | Actor count per movie |
| Q15 | All movies featuring a specific actor |
| Q16 | Movies available in multiple regions |
| Q17 | Title count and avg rating per region |
| Q18 | Movies with more than 3 alternate titles |

---

### Level 3 — Advanced (Q19–Q26)
Window functions, complex filtering, and statistical analysis.

| # | Question |
|---|---|
| Q19 | Top 10 actors by average movie rating |
| Q20 | Actors who appeared in 10+ movies |
| Q21 | Most versatile actors (7+ genres) |
| Q22 | Top directors by average rating |
| Q23 | Directors with the most movies |
| Q24 | Directors with highest total votes |
| Q25 | Vote bucket analysis (do more votes → higher ratings?) |
| Q26 | Pearson correlation: `numVotes` vs `averageRating` |

---

### Level 4 — Advanced Joins: All Tables (Q27–Q31)
Queries that join all 7 tables simultaneously.

| # | Question |
|---|---|
| Q27 | Highly rated movies across multiple regions with lead actors |
| Q28 | Per-actor summary: total movies, avg rating, best movie |
| Q29 | Movies released in the most countries |
| Q30 | Globally released movies (10+ regions) with full cast |
| Q31 | Actors who appear in globally released movies |

---

### Level 5 — Portfolio Level (Q32–Q37)
Composite scoring, career analytics, and genre dominance.

| # | Question |
|---|---|
| Q32 | Actor career score = `avg_rating × log(total_votes) × movie_count` |
| Q33 | Underrated movies: high rating, very few votes |
| Q34 | Most influential movies: high rating + high votes + wide release |
| Q35 | Actor career growth: first movie rating vs latest movie rating |
| Q36 | Which actor dominates which genre? |
| Q37 | Highest-rated genre overall |

---

### Bonus — Interview / Window Functions (Q38–Q41)

| # | Question |
|---|---|
| Q38 | Rank all movies within each year |
| Q39 | Top 3 movies per year |
| Q40 | Normalize `primaryProfession` into individual rows (`UNNEST`) |
| Q41 | Netflix acquisition score: `avg_rating × log(votes) × region_count` |

---

## Sample Outputs

### Q1 — Top 10 Highest-Rated Movies

<img width="1669" height="889" alt="q1_top_rated png" src="https://github.com/user-attachments/assets/556c1378-93dc-4e5c-84d2-950bf7f6d3e6" />

---

### Q25 — Vote Bucket Analysis

<img width="1913" height="924" alt="q25_vote_buckets png" src="https://github.com/user-attachments/assets/1078a50c-7d9d-4a7c-806d-6d6424accc09" />

---

### Q32 — Actor Career Score Rankings

<img width="1913" height="924" alt="q25_vote_buckets png" src="https://github.com/user-attachments/assets/297fa63b-a6ed-44e3-947a-85da51478a65" />


---

### Q41 — Netflix Acquisition Score

<img width="1690" height="904" alt="q41_netflix png" src="https://github.com/user-attachments/assets/9320dd09-c010-4806-b0ef-60d6dcc44f75" />

---


## Tech Stack

| Tool | Purpose |
|---|---|
| **DuckDB** | In-process SQL engine for fast Parquet querying |
| **IMDB TSV files** | Raw source data (converted to Parquet) |
| **SQL** | Window functions, CTEs, unnesting, string aggregation |

No Python, no Pandas. Pure SQL end-to-end.

---

## How to Run

**1. Download the dataset**

Go to [https://developer.imdb.com/non-commercial-datasets/](https://developer.imdb.com/non-commercial-datasets/) and download all 7 `.tsv.gz` files. Extract them into a `tsv_files/` folder.

**2. Install DuckDB**

```bash
# macOS
brew install duckdb

# Windows — download from https://duckdb.org/docs/installation/
```

**3. Open DuckDB and run the queries**

```bash
duckdb
```

```sql
-- Inside DuckDB shell
.read sql/imdb_analysis.sql
```

Or run specific sections by copying queries directly into the DuckDB CLI or DBeaver.

**4. Update file paths**

The ingestion queries at the top of `imdb_analysis.sql` use relative paths. Make sure your `tsv_files/` and `parquet/` folders exist at the same level as the SQL file, or update the paths to match your setup.

---

## Key Learnings

- **`NULLIF` + `TRY_CAST`** — essential pattern for cleaning messy raw datasets with sentinel null values
- **`UNNEST(STRING_SPLIT(...))`** — normalizing delimited columns like `genres` and `primaryProfession` into rows
- **Window functions** — `ROW_NUMBER`, `DENSE_RANK`, `AVG() OVER (PARTITION BY ...)` for per-group analytics without collapsing rows
- **Composite scoring** — combining rating, vote count, and reach into a single interpretable score
- **DuckDB** — incredibly fast for analytical queries on Parquet files, with a clean SQL dialect and no setup overhead

---

## Files included:

    imdb-sql-analysis/
    ├── README.md
    ├── sql/
    │   └── imdb_analysis.sql
    └── schema/
        └── erd.svg

## Author

**Krrish_rana**
data analyst | SQL · Python · DuckDB

