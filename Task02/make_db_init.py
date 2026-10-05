import csv
import os

def escape_sql(val):
    if val is None:
        return "NULL"
    val_str = str(val).replace("'", "''")
    return f"'{val_str}'"

def main():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    sql_path = os.path.join(base_dir, "db_init.sql")
    sql_statements = []

    sql_statements.append("DROP TABLE IF EXISTS movies;")
    sql_statements.append("DROP TABLE IF EXISTS ratings;")
    sql_statements.append("DROP TABLE IF EXISTS tags;")
    sql_statements.append("DROP TABLE IF EXISTS users;\n")

    sql_statements.append("""CREATE TABLE movies (
    id INTEGER PRIMARY KEY,
    title TEXT,
    year INTEGER,
    genres TEXT
);""")

    sql_statements.append("""CREATE TABLE ratings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    movie_id INTEGER,
    rating REAL,
    timestamp INTEGER
);""")

    sql_statements.append("""CREATE TABLE tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    movie_id INTEGER,
    tag TEXT,
    timestamp INTEGER
);""")

    sql_statements.append("""CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT,
    email TEXT,
    gender TEXT,
    register_date TEXT,
    occupation TEXT
);\n""")

    movies_file = None
    for fname in ["movies.csv", "movies.txt", "movies.dat"]:
        p = os.path.join(base_dir, fname)
        if os.path.exists(p):
            movies_file = p
            break

    if movies_file:
        with open(movies_file, "r", encoding="utf-8", errors="ignore") as f:
            reader = csv.reader(f)
            header = next(reader, None)
            for row in reader:
                if not row or len(row) < 4:
                    continue
                m_id, title, year, genres = row[0], row[1], row[2], row[3]
                year_val = int(year) if year.isdigit() else "NULL"
                sql_statements.append(f"INSERT INTO movies (id, title, year, genres) VALUES ({m_id}, {escape_sql(title)}, {year_val}, {escape_sql(genres)});")

    ratings_file = None
    for fname in ["ratings.csv", "ratings.txt", "ratings.dat"]:
        p = os.path.join(base_dir, fname)
        if os.path.exists(p):
            ratings_file = p
            break

    if ratings_file:
        with open(ratings_file, "r", encoding="utf-8", errors="ignore") as f:
            reader = csv.reader(f)
            header = next(reader, None)
            for row in reader:
                if not row or len(row) < 4:
                    continue
                u_id, m_id, rating, ts = row[0], row[1], row[2], row[3]
                sql_statements.append(f"INSERT INTO ratings (user_id, movie_id, rating, timestamp) VALUES ({u_id}, {m_id}, {rating}, {ts});")

    tags_file = None
    for fname in ["tags.csv", "tags.txt", "tags.dat"]:
        p = os.path.join(base_dir, fname)
        if os.path.exists(p):
            tags_file = p
            break

    if tags_file:
        with open(tags_file, "r", encoding="utf-8", errors="ignore") as f:
            reader = csv.reader(f)
            header = next(reader, None)
            for row in reader:
                if not row or len(row) < 4:
                    continue
                u_id, m_id, tag, ts = row[0], row[1], row[2], row[3]
                sql_statements.append(f"INSERT INTO tags (user_id, movie_id, tag, timestamp) VALUES ({u_id}, {m_id}, {escape_sql(tag)}, {ts});")

    users_file = None
    for fname in ["users.txt", "users.csv", "users.dat"]:
        p = os.path.join(base_dir, fname)
        if os.path.exists(p):
            users_file = p
            break

    if users_file:
        with open(users_file, "r", encoding="utf-8", errors="ignore") as f:
            sample = f.read(2048)
            f.seek(0)
            delimiter = "|" if "|" in sample else ","
            reader = csv.reader(f, delimiter=delimiter)
            header = next(reader, None)
            for row in reader:
                if not row or len(row) < 6:
                    continue
                u_id, name, email, gender, reg_date, occupation = row[0], row[1], row[2], row[3], row[4], row[5]
                sql_statements.append(f"INSERT INTO users (id, name, email, gender, register_date, occupation) VALUES ({u_id}, {escape_sql(name)}, {escape_sql(email)}, {escape_sql(gender)}, {escape_sql(reg_date)}, {escape_sql(occupation)});")

    with open(sql_path, "w", encoding="utf-8") as f:
        f.write("\n".join(sql_statements) + "\n")

    print("db_init.sql успешно сгенерирован!")

if __name__ == "__main__":
    main()
