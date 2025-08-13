-- init.sql - Final Version

-- =====================================================================
-- PART 1: SETUP ROLES, TABLESPACE, AND DATABASE
-- =====================================================================

-- 01. Create the main administrator role if it doesn't exist
DO $$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'bootcamp_admin') THEN
    CREATE ROLE bootcamp_admin LOGIN PASSWORD 'secure_password';
  END IF;
END $$;

-- 03. Create the database if it doesn't exist
DO $$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'bootcamp_db') THEN
    CREATE DATABASE bootcamp_db
      OWNER bootcamp_admin
   ;
  END IF;
END $$;

-- =====================================================================
-- PART 2: CONNECT TO THE DATABASE AND DEFINE THE SCHEMA
-- =====================================================================

-- 04. Switch connection to the newly created database
\connect bootcamp_db

-- 05. Create the application schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS bootcamp_schema AUTHORIZATION bootcamp_admin;

-- 06. Define the squad_leaders table
CREATE TABLE IF NOT EXISTS bootcamp_schema.squad_leaders (id SERIAL PRIMARY KEY, firstname VARCHAR(50) NOT NULL, lastname VARCHAR(50) NOT NULL, email VARCHAR(50) NOT NULL UNIQUE);

-- 07. Define the squads table
CREATE TABLE IF NOT EXISTS bootcamp_schema.squads (id SERIAL PRIMARY KEY, name VARCHAR(10) NOT NULL UNIQUE, leader_id INTEGER NOT NULL UNIQUE REFERENCES bootcamp_schema.squad_leaders(id));

-- 08. Define the student table with an age constraint
CREATE TABLE IF NOT EXISTS bootcamp_schema.student (id SERIAL PRIMARY KEY, firstname VARCHAR(50) NOT NULL, lastname VARCHAR(50) NOT NULL, email VARCHAR(50) NOT NULL UNIQUE, birthdate DATE NOT NULL CHECK (birthdate <= CURRENT_DATE - INTERVAL '21 years' AND birthdate >= CURRENT_DATE - INTERVAL '35 years'), squad_name VARCHAR(10) NOT NULL REFERENCES bootcamp_schema.squads(name));

-- 09. Create an index on the foreign key for better performance
CREATE INDEX IF NOT EXISTS idx_student_squad_name ON bootcamp_schema.student(squad_name);

-- =====================================================================
-- PART 3: CONFIGURE A DEDICATED BACKUP USER
-- =====================================================================

-- 10. Create a role for backups if it doesn't exist
DO $$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'backup_user') THEN
    CREATE ROLE backup_user LOGIN PASSWORD 'another_secure_password';
  END IF;
END $$;

-- 11. Grant the minimum necessary privileges to the backup user
GRANT CONNECT ON DATABASE bootcamp_db TO backup_user;
GRANT USAGE ON SCHEMA bootcamp_schema TO backup_user;
GRANT SELECT ON ALL TABLES IN SCHEMA bootcamp_schema TO backup_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA bootcamp_schema TO backup_user; -- <-- Key fix for pg_dump

-- =====================================================================
-- PART 4: POPULATE TABLES WITH SAMPLE DATA
-- =====================================================================

-- 12. Insert data into squad_leaders, ignoring conflicts
INSERT INTO bootcamp_schema.squad_leaders (firstname, lastname, email) VALUES ('John', 'Doe', 'john.doe@example.com'), ('Jane', 'Smith', 'jane.smith@example.com'), ('Peter', 'Jones', 'peter.jones@example.com') ON CONFLICT (email) DO NOTHING;

-- 13. Insert data into squads, ignoring conflicts
INSERT INTO bootcamp_schema.squads (name, leader_id) VALUES ('Alpha', 1), ('Bravo', 2), ('Charlie', 3) ON CONFLICT (name) DO NOTHING;

-- 14. Insert data into student, ignoring conflicts
INSERT INTO bootcamp_schema.student (firstname, lastname, email, birthdate, squad_name) VALUES ('Alice', 'Williams', 'alice.w@example.com', CURRENT_DATE - INTERVAL '25 years', 'Alpha'), ('Bob', 'Brown', 'bob.b@example.com', CURRENT_DATE - INTERVAL '30 years', 'Alpha'), ('Charlie', 'Davis', 'charlie.d@example.com', CURRENT_DATE - INTERVAL '22 years', 'Bravo'), ('Diana', 'Miller', 'diana.m@example.com', CURRENT_DATE - INTERVAL '28 years', 'Bravo'), ('Eve', 'Wilson', 'eve.w@example.com', CURRENT_DATE - INTERVAL '34 years', 'Charlie') ON CONFLICT (email) DO NOTHING;