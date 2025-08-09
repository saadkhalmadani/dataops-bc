-- 01. Ensure role exists
DO
$$
BEGIN
  IF NOT EXISTS (
    SELECT FROM pg_roles WHERE rolname = 'bootcamp_admin'
  ) THEN
    CREATE ROLE bootcamp_admin LOGIN PASSWORD 'secure_password';
  END IF;
END
$$;

-- 02. Create tablespace (directory must exist outside PGDATA)
CREATE TABLESPACE ts_bootcamp
  OWNER bootcamp_admin
  LOCATION '/ts_bootcamp_data';

-- 03. Create database only if not exists
DO
$$
BEGIN
  IF NOT EXISTS (
    SELECT FROM pg_database WHERE datname = 'bootcamp_db'
  ) THEN
    CREATE DATABASE bootcamp_db
      OWNER bootcamp_admin
      TABLESPACE ts_bootcamp;
  END IF;
END
$$;

-- 04. Connect to bootcamp_db
\connect bootcamp_db

-- 05. Create schema
CREATE SCHEMA IF NOT EXISTS bootcamp_schema AUTHORIZATION bootcamp_admin;

-- 06. squad_leaders table
CREATE TABLE IF NOT EXISTS bootcamp_schema.squad_leaders (
  id SERIAL PRIMARY KEY,
  firstname VARCHAR(50) NOT NULL,
  lastname VARCHAR(50) NOT NULL,
  email VARCHAR(50) NOT NULL UNIQUE
)
TABLESPACE ts_bootcamp;

-- 07. squads table
CREATE TABLE IF NOT EXISTS bootcamp_schema.squads (
  id SERIAL PRIMARY KEY,
  name VARCHAR(10) NOT NULL UNIQUE,
  leader_id INTEGER NOT NULL UNIQUE REFERENCES bootcamp_schema.squad_leaders(id)
)
TABLESPACE ts_bootcamp;

-- 08. student table
CREATE TABLE IF NOT EXISTS bootcamp_schema.student (
  id SERIAL PRIMARY KEY,
  firstname VARCHAR(50) NOT NULL,
  lastname VARCHAR(50) NOT NULL,
  email VARCHAR(50) NOT NULL UNIQUE,
  birthdate DATE NOT NULL
    CHECK (
      birthdate <= CURRENT_DATE - INTERVAL '21 years'
      AND birthdate >= CURRENT_DATE - INTERVAL '35 years'
    ),
  squad_name VARCHAR(10) NOT NULL REFERENCES bootcamp_schema.squads(name)
)
TABLESPACE ts_bootcamp;


-- 09. Index for student foreign key
CREATE INDEX IF NOT EXISTS idx_student_squad_name
  ON bootcamp_schema.student(squad_name);
  