--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5
-- Dumped by pg_dump version 17.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: bootcamp_schema; Type: SCHEMA; Schema: -; Owner: bootcamp_admin
--

CREATE SCHEMA bootcamp_schema;


ALTER SCHEMA bootcamp_schema OWNER TO bootcamp_admin;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: squad_leaders; Type: TABLE; Schema: bootcamp_schema; Owner: bootcamp_admin
--

CREATE TABLE bootcamp_schema.squad_leaders (
    id integer NOT NULL,
    firstname character varying(50) NOT NULL,
    lastname character varying(50) NOT NULL,
    email character varying(50) NOT NULL
);


ALTER TABLE bootcamp_schema.squad_leaders OWNER TO bootcamp_admin;

--
-- Name: squad_leaders_id_seq; Type: SEQUENCE; Schema: bootcamp_schema; Owner: bootcamp_admin
--

CREATE SEQUENCE bootcamp_schema.squad_leaders_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE bootcamp_schema.squad_leaders_id_seq OWNER TO bootcamp_admin;

--
-- Name: squad_leaders_id_seq; Type: SEQUENCE OWNED BY; Schema: bootcamp_schema; Owner: bootcamp_admin
--

ALTER SEQUENCE bootcamp_schema.squad_leaders_id_seq OWNED BY bootcamp_schema.squad_leaders.id;


--
-- Name: squads; Type: TABLE; Schema: bootcamp_schema; Owner: bootcamp_admin
--

CREATE TABLE bootcamp_schema.squads (
    id integer NOT NULL,
    name character varying(10) NOT NULL,
    leader_id integer NOT NULL
);


ALTER TABLE bootcamp_schema.squads OWNER TO bootcamp_admin;

--
-- Name: squads_id_seq; Type: SEQUENCE; Schema: bootcamp_schema; Owner: bootcamp_admin
--

CREATE SEQUENCE bootcamp_schema.squads_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE bootcamp_schema.squads_id_seq OWNER TO bootcamp_admin;

--
-- Name: squads_id_seq; Type: SEQUENCE OWNED BY; Schema: bootcamp_schema; Owner: bootcamp_admin
--

ALTER SEQUENCE bootcamp_schema.squads_id_seq OWNED BY bootcamp_schema.squads.id;


--
-- Name: student; Type: TABLE; Schema: bootcamp_schema; Owner: bootcamp_admin
--

CREATE TABLE bootcamp_schema.student (
    id integer NOT NULL,
    firstname character varying(50) NOT NULL,
    lastname character varying(50) NOT NULL,
    email character varying(50) NOT NULL,
    birthdate date NOT NULL,
    squad_name character varying(10) NOT NULL,
    CONSTRAINT student_birthdate_check CHECK (((birthdate <= (CURRENT_DATE - '21 years'::interval)) AND (birthdate >= (CURRENT_DATE - '35 years'::interval))))
);


ALTER TABLE bootcamp_schema.student OWNER TO bootcamp_admin;

--
-- Name: student_id_seq; Type: SEQUENCE; Schema: bootcamp_schema; Owner: bootcamp_admin
--

CREATE SEQUENCE bootcamp_schema.student_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE bootcamp_schema.student_id_seq OWNER TO bootcamp_admin;

--
-- Name: student_id_seq; Type: SEQUENCE OWNED BY; Schema: bootcamp_schema; Owner: bootcamp_admin
--

ALTER SEQUENCE bootcamp_schema.student_id_seq OWNED BY bootcamp_schema.student.id;


--
-- Name: squad_leaders id; Type: DEFAULT; Schema: bootcamp_schema; Owner: bootcamp_admin
--

ALTER TABLE ONLY bootcamp_schema.squad_leaders ALTER COLUMN id SET DEFAULT nextval('bootcamp_schema.squad_leaders_id_seq'::regclass);


--
-- Name: squads id; Type: DEFAULT; Schema: bootcamp_schema; Owner: bootcamp_admin
--

ALTER TABLE ONLY bootcamp_schema.squads ALTER COLUMN id SET DEFAULT nextval('bootcamp_schema.squads_id_seq'::regclass);


--
-- Name: student id; Type: DEFAULT; Schema: bootcamp_schema; Owner: bootcamp_admin
--

ALTER TABLE ONLY bootcamp_schema.student ALTER COLUMN id SET DEFAULT nextval('bootcamp_schema.student_id_seq'::regclass);


--
-- Data for Name: squad_leaders; Type: TABLE DATA; Schema: bootcamp_schema; Owner: bootcamp_admin
--

COPY bootcamp_schema.squad_leaders (id, firstname, lastname, email) FROM stdin;
1	John	Doe	john.doe@example.com
2	Jane	Smith	jane.smith@example.com
3	Peter	Jones	peter.jones@example.com
\.


--
-- Data for Name: squads; Type: TABLE DATA; Schema: bootcamp_schema; Owner: bootcamp_admin
--

COPY bootcamp_schema.squads (id, name, leader_id) FROM stdin;
1	Alpha	1
2	Bravo	2
3	Charlie	3
\.


--
-- Data for Name: student; Type: TABLE DATA; Schema: bootcamp_schema; Owner: bootcamp_admin
--

COPY bootcamp_schema.student (id, firstname, lastname, email, birthdate, squad_name) FROM stdin;
1	Alice	Williams	alice.w@example.com	2000-08-13	Alpha
2	Bob	Brown	bob.b@example.com	1995-08-13	Alpha
3	Charlie	Davis	charlie.d@example.com	2003-08-13	Bravo
4	Diana	Miller	diana.m@example.com	1997-08-13	Bravo
5	Eve	Wilson	eve.w@example.com	1991-08-13	Charlie
6	khalid	drayef	khalid_drayef@gmail.com	1995-08-13	Alpha
\.


--
-- Name: squad_leaders_id_seq; Type: SEQUENCE SET; Schema: bootcamp_schema; Owner: bootcamp_admin
--

SELECT pg_catalog.setval('bootcamp_schema.squad_leaders_id_seq', 3, true);


--
-- Name: squads_id_seq; Type: SEQUENCE SET; Schema: bootcamp_schema; Owner: bootcamp_admin
--

SELECT pg_catalog.setval('bootcamp_schema.squads_id_seq', 3, true);


--
-- Name: student_id_seq; Type: SEQUENCE SET; Schema: bootcamp_schema; Owner: bootcamp_admin
--

SELECT pg_catalog.setval('bootcamp_schema.student_id_seq', 5, true);


--
-- Name: squad_leaders squad_leaders_email_key; Type: CONSTRAINT; Schema: bootcamp_schema; Owner: bootcamp_admin
--

ALTER TABLE ONLY bootcamp_schema.squad_leaders
    ADD CONSTRAINT squad_leaders_email_key UNIQUE (email);


--
-- Name: squad_leaders squad_leaders_pkey; Type: CONSTRAINT; Schema: bootcamp_schema; Owner: bootcamp_admin
--

ALTER TABLE ONLY bootcamp_schema.squad_leaders
    ADD CONSTRAINT squad_leaders_pkey PRIMARY KEY (id);


--
-- Name: squads squads_leader_id_key; Type: CONSTRAINT; Schema: bootcamp_schema; Owner: bootcamp_admin
--

ALTER TABLE ONLY bootcamp_schema.squads
    ADD CONSTRAINT squads_leader_id_key UNIQUE (leader_id);


--
-- Name: squads squads_name_key; Type: CONSTRAINT; Schema: bootcamp_schema; Owner: bootcamp_admin
--

ALTER TABLE ONLY bootcamp_schema.squads
    ADD CONSTRAINT squads_name_key UNIQUE (name);


--
-- Name: squads squads_pkey; Type: CONSTRAINT; Schema: bootcamp_schema; Owner: bootcamp_admin
--

ALTER TABLE ONLY bootcamp_schema.squads
    ADD CONSTRAINT squads_pkey PRIMARY KEY (id);


--
-- Name: student student_email_key; Type: CONSTRAINT; Schema: bootcamp_schema; Owner: bootcamp_admin
--

ALTER TABLE ONLY bootcamp_schema.student
    ADD CONSTRAINT student_email_key UNIQUE (email);


--
-- Name: student student_pkey; Type: CONSTRAINT; Schema: bootcamp_schema; Owner: bootcamp_admin
--

ALTER TABLE ONLY bootcamp_schema.student
    ADD CONSTRAINT student_pkey PRIMARY KEY (id);


--
-- Name: idx_student_squad_name; Type: INDEX; Schema: bootcamp_schema; Owner: bootcamp_admin
--

CREATE INDEX idx_student_squad_name ON bootcamp_schema.student USING btree (squad_name);


--
-- Name: squads squads_leader_id_fkey; Type: FK CONSTRAINT; Schema: bootcamp_schema; Owner: bootcamp_admin
--

ALTER TABLE ONLY bootcamp_schema.squads
    ADD CONSTRAINT squads_leader_id_fkey FOREIGN KEY (leader_id) REFERENCES bootcamp_schema.squad_leaders(id);


--
-- Name: student student_squad_name_fkey; Type: FK CONSTRAINT; Schema: bootcamp_schema; Owner: bootcamp_admin
--

ALTER TABLE ONLY bootcamp_schema.student
    ADD CONSTRAINT student_squad_name_fkey FOREIGN KEY (squad_name) REFERENCES bootcamp_schema.squads(name);


--
-- Name: SCHEMA bootcamp_schema; Type: ACL; Schema: -; Owner: bootcamp_admin
--

GRANT USAGE ON SCHEMA bootcamp_schema TO backup_user;


--
-- Name: TABLE squad_leaders; Type: ACL; Schema: bootcamp_schema; Owner: bootcamp_admin
--

GRANT SELECT ON TABLE bootcamp_schema.squad_leaders TO backup_user;


--
-- Name: SEQUENCE squad_leaders_id_seq; Type: ACL; Schema: bootcamp_schema; Owner: bootcamp_admin
--

GRANT SELECT,USAGE ON SEQUENCE bootcamp_schema.squad_leaders_id_seq TO backup_user;


--
-- Name: TABLE squads; Type: ACL; Schema: bootcamp_schema; Owner: bootcamp_admin
--

GRANT SELECT ON TABLE bootcamp_schema.squads TO backup_user;


--
-- Name: SEQUENCE squads_id_seq; Type: ACL; Schema: bootcamp_schema; Owner: bootcamp_admin
--

GRANT SELECT,USAGE ON SEQUENCE bootcamp_schema.squads_id_seq TO backup_user;


--
-- Name: TABLE student; Type: ACL; Schema: bootcamp_schema; Owner: bootcamp_admin
--

GRANT SELECT ON TABLE bootcamp_schema.student TO backup_user;


--
-- Name: SEQUENCE student_id_seq; Type: ACL; Schema: bootcamp_schema; Owner: bootcamp_admin
--

GRANT SELECT,USAGE ON SEQUENCE bootcamp_schema.student_id_seq TO backup_user;


--
-- PostgreSQL database dump complete
--

