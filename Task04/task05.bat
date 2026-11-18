::#!/bin/bash
chcp 65001

sqlite3 movies_rating.db < db_init.sql

echo "1. Ранг фильмов по убыванию среднего рейтинга (топ-10 с наибольшим рангом)."
echo ---------------------------------------------------------------------------------------------------------------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH movie_avg AS (SELECT m.title, m.year, AVG(r.rating) AS avg_rat FROM movies m JOIN ratings r ON m.id = r.movie_id GROUP BY m.id, m.title, m.year) SELECT title, year, ROUND(avg_rat, 2) AS avg_rating, DENSE_RANK() OVER (ORDER BY avg_rat DESC) AS rank_by_avg_rating FROM movie_avg ORDER BY rank_by_avg_rating ASC, year, title LIMIT 10;"
echo ""

echo "2. Средний рейтинг жанров и ранг жанра по убыванию среднего рейтинга (через рекурсивное CTE)."
echo ---------------------------------------------------------------------------------------------------------------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE split(id, title, genre, rest) AS (SELECT id, title, '', genres || '|' FROM movies UNION ALL SELECT id, title, SUBSTR(rest, 1, INSTR(rest, '|') - 1), SUBSTR(rest, INSTR(rest, '|') + 1) FROM split WHERE rest != ''), genre_avg AS (SELECT genre, AVG(r.rating) AS avg_rat FROM split s JOIN ratings r ON s.id = r.movie_id WHERE genre != '' GROUP BY genre) SELECT genre, ROUND(avg_rat, 2) AS avg_rating, RANK() OVER (ORDER BY avg_rat DESC) AS rank_by_avg_rating FROM genre_avg ORDER BY avg_rating DESC, genre;"
echo ""

echo "3. Количество фильмов в каждом жанре, отсортированное по убыванию."
echo ---------------------------------------------------------------------------------------------------------------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE split(id, genre, rest) AS (SELECT id, '', genres || '|' FROM movies UNION ALL SELECT id, SUBSTR(rest, 1, INSTR(rest, '|') - 1), SUBSTR(rest, INSTR(rest, '|') + 1) FROM split WHERE rest != '') SELECT genre, COUNT(DISTINCT id) AS movie_count FROM split WHERE genre != '' GROUP BY genre ORDER BY movie_count DESC, genre;"
echo ""

echo "4. Жанры, в которых чаще всего оставляют теги (количество тегов и доля в процентах tag_share)."
echo ---------------------------------------------------------------------------------------------------------------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE split(id, genre, rest) AS (SELECT id, '', genres || '|' FROM movies UNION ALL SELECT id, SUBSTR(rest, 1, INSTR(rest, '|') - 1), SUBSTR(rest, '|') + 1) FROM split WHERE rest != ''), genre_tags AS (SELECT s.genre, COUNT(t.tag) AS tag_count FROM split s JOIN tags t ON s.id = t.movie_id WHERE s.genre != '' GROUP BY s.genre), total AS (SELECT COUNT(*) AS total_t FROM tags) SELECT gt.genre, gt.tag_count, ROUND(CAST(gt.tag_count AS REAL) * 100 / (SELECT total_t FROM total), 2) AS tag_share FROM genre_tags gt ORDER BY tag_count DESC, genre;"
echo ""

echo "5. Статистика по пользователям: кол-во оценок, средний рейтинг, даты первой и последней оценки (топ-10)."
echo ---------------------------------------------------------------------------------------------------------------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT user_id, COUNT(rating) AS rating_count, ROUND(AVG(rating), 2) AS avg_rating, strftime('%Y-%m-%d', datetime(MIN(timestamp), 'unixepoch')) AS first_rating_date, strftime('%Y-%m-%d', datetime(MAX(timestamp), 'unixepoch')) AS last_rating_date FROM ratings GROUP BY user_id ORDER BY rating_count DESC LIMIT 10;"
echo ""

echo "6. Сегментация пользователей по типу поведения (Комментаторы, Оценщики, Активные, Пассивные)."
echo ---------------------------------------------------------------------------------------------------------------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH user_stats AS (SELECT u.id AS user_id, COUNT(DISTINCT r.timestamp) AS rating_count, COUNT(DISTINCT t.timestamp) AS tag_count FROM users u LEFT JOIN ratings r ON u.id = r.user_id LEFT JOIN tags t ON u.id = t.user_id GROUP BY u.id) SELECT user_id, rating_count, tag_count, CASE WHEN tag_count > rating_count THEN 'Комментаторы' WHEN rating_count > tag_count THEN 'Оценщики' WHEN rating_count >= 10 AND tag_count >= 10 THEN 'Активные' ELSE 'Пассивные' END AS behavior_type FROM user_stats ORDER BY user_id LIMIT 50;"
echo ""

echo "7. Последний оцененный фильм для каждого пользователя (с учетом пользователей без оценок через LEFT JOIN)."
echo ---------------------------------------------------------------------------------------------------------------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH ranked_ratings AS (SELECT user_id, movie_id, timestamp, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY timestamp DESC) AS rn FROM ratings) SELECT u.id AS user_id, u.name, m.title AS last_rated_movie_title, strftime('%Y-%m-%d', datetime(rr.timestamp, 'unixepoch')) AS last_rating_timestamp FROM users u LEFT JOIN ranked_ratings rr ON u.id = rr.user_id AND rr.rn = 1 LEFT JOIN movies m ON rr.movie_id = m.id ORDER BY u.id LIMIT 50;"
echo ""