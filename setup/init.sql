--
--  Copyright (C) 2009 Astaro AG  www.astaro.com
--  All rights reserved.
--
--  Author: Frank Lichtenheld <flichtenheld@astaro.com> 07.07.2009

DROP TABLE users  CASCADE;
DROP TABLE groups CASCADE;
DROP TABLE repos  CASCADE;
DROP TABLE writable CASCADE;
DROP TABLE readable CASCADE;
DROP TABLE members  CASCADE;
DROP TABLE subscriptions CASCADE;
DROP TABLE logs_push CASCADE;
DROP TABLE commit_to_branch CASCADE;
DROP TABLE commits CASCADE;
DROP TABLE branches CASCADE;
DROP ROLE gwa_webaccess;
DROP ROLE gwa_gitaccess;
DROP ROLE gwa_admin;

BEGIN;

CREATE ROLE gwa_webaccess LOGIN PASSWORD 'foobar';
CREATE ROLE gwa_gitaccess;
CREATE ROLE gwa_admin;
GRANT gwa_webaccess TO gwa_admin;
GRANT gwa_gitaccess TO gwa_admin;

CREATE TABLE users (
       uid   TEXT PRIMARY KEY,
       name  TEXT,
       mail  TEXT,
       admin BOOLEAN NOT NULL DEFAULT FALSE,
       active BOOLEAN NOT NULL DEFAULT TRUE,

       CONSTRAINT users_admin_active CHECK (NOT (admin AND NOT active)),
       CONSTRAINT users_gitadm_active CHECK (NOT (uid='gitadm' AND NOT active))
);
CREATE INDEX users_name_idx ON users (name);
GRANT SELECT, UPDATE ON users TO gwa_webaccess;
GRANT SELECT ON users TO gwa_gitaccess;
GRANT ALL ON users TO gwa_admin;

INSERT INTO users VALUES
       ('gitadm', 'Git Administrator');

CREATE TYPE ssh_key_type AS ENUM ('rsa', 'dsa');

CREATE TABLE keys (
       id    SERIAL PRIMARY KEY,
       uid   TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
       name  TEXT NOT NULL,
       bits  INT NOT NULL CHECK (floor(log(2,bits)) = log(2,bits)),
       type  ssh_key_type NOT NULL,
       fingerprint TEXT NOT NULL,
       key   TEXT NOT NULL,

       UNIQUE(uid, key),
       UNIQUE(uid, name)
);
GRANT ALL ON keys TO gwa_webaccess;
GRANT ALL ON SEQUENCE keys_id_seq TO gwa_webaccess;
GRANT SELECT ON keys TO gwa_gitaccess;

CREATE TABLE groups (
       gid   TEXT PRIMARY KEY,
       name  TEXT,
       descr  TEXT
);
GRANT ALL ON groups TO gwa_webaccess;

INSERT INTO groups VALUES
       ('gitosis-admin', 'Gitosis Adminstrators');

CREATE TABLE members (
       uid   TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
       gid   TEXT NOT NULL REFERENCES groups(gid) ON DELETE CASCADE,

       UNIQUE(uid,gid)
);
GRANT ALL ON members TO gwa_webaccess;

INSERT INTO members VALUES
       ('gitadm', 'gitosis-admin');

CREATE TABLE repos (
       id    SERIAL PRIMARY KEY,
       name  TEXT NOT NULL UNIQUE,
       descr  TEXT,
       branch TEXT NOT NULL DEFAULT 'master',
       private  BOOLEAN NOT NULL DEFAULT FALSE,
       daemon   BOOLEAN NOT NULL DEFAULT FALSE,
       gitweb   BOOLEAN NOT NULL DEFAULT FALSE,
       mantis   BOOLEAN NOT NULL DEFAULT FALSE,
       owner    TEXT NOT NULL REFERENCES users(uid) ON DELETE RESTRICT,
       forkof   INT REFERENCES repos(id) ON DELETE RESTRICT,
       mirrorof TEXT,
       deleted  BOOLEAN NOT NULL DEFAULT FALSE,

       CONSTRAINT repos_hidden_deleted CHECK (NOT (deleted AND (gitweb OR daemon))),
       CONSTRAINT repos_one_parent CHECK (NOT (forkof IS NOT NULL AND mirrorof IS NOT NULL)),
       CONSTRAINT repos_mantis_gitweb CHECK (NOT (mantis AND NOT gitweb))
);
CREATE INDEX repos_name_idx ON repos (name);
GRANT SELECT, INSERT, UPDATE ON repos TO gwa_webaccess;
GRANT ALL ON SEQUENCE repos_id_seq TO gwa_webaccess;
GRANT SELECT ON repos TO gwa_gitaccess;

CREATE VIEW active_repos AS
       SELECT * FROM repos WHERE NOT deleted;
GRANT SELECT ON active_repos TO gwa_webaccess;
GRANT SELECT ON active_repos TO gwa_gitaccess;

CREATE OR REPLACE FUNCTION repo_id (text) RETURNS int AS $$
       SELECT id FROM repos r WHERE r.name = $1
$$ LANGUAGE SQL STABLE STRICT;
INSERT INTO repos (name, owner) VALUES
       ('gitosis-admin.git', 'gitadm');

--
-- ### BEGIN MANTIS INTEGRATION ###
--

--
-- Save a list of branches for each repository
--
CREATE TABLE branches (
       id   SERIAL PRIMARY KEY,
       rid   INT NOT NULL REFERENCES repos(id) ON DELETE CASCADE,
       branch TEXT NOT NULL,
       commit TEXT NOT NULL CHECK (char_length(commit) = 40),

       UNIQUE (rid, branch)
);
GRANT ALL ON branches TO gwa_gitaccess;
GRANT ALL ON branches_id_seq TO gwa_gitaccess;

--
-- Save a list of commits in each repository
-- (we will probably only save commits with a mantis reference for now)
--
CREATE TABLE commits (
       id BIGSERIAL PRIMARY KEY,
       rid   INT NOT NULL REFERENCES repos(id) ON DELETE CASCADE,
       commit TEXT NOT NULL CHECK (char_length(commit) = 40),

       UNIQUE (rid, commit)
);
GRANT ALL ON commits TO gwa_gitaccess;
GRANT ALL ON commits_id_seq TO gwa_gitaccess;

--
-- Map commits to branches (n<-->n)
--
CREATE TABLE commit_to_branch (
       cid BIGINT NOT NULL REFERENCES commits(id) ON DELETE CASCADE,
       bid BIGINT NOT NULL REFERENCES branches(id) ON DELETE CASCADE,

       UNIQUE (cid, bid)
);
GRANT ALL ON commit_to_branch TO gwa_gitaccess;

CREATE VIEW mantis_repos AS
       SELECT r.id, r.name, r.descr,
              array_to_string(ARRAY(SELECT branch FROM branches AS b WHERE b.rid = r.id), ',') AS branches
       FROM repos AS r
       WHERE r.mantis IS TRUE;
GRANT SELECT ON mantis_repos TO gwa_gitaccess;

--
-- ### END MANTIS INTEGRATION ###
--

CREATE TABLE writable (
       gid   TEXT NOT NULL REFERENCES groups(gid) ON DELETE CASCADE,
       rid   INT NOT NULL REFERENCES repos(id) ON DELETE CASCADE,

       UNIQUE (gid, rid)
);
GRANT ALL ON writable TO gwa_webaccess;
INSERT INTO writable VALUES
       ('gitosis-admin', repo_id('gitosis-admin.git'));

CREATE TABLE readable (
       gid   TEXT NOT NULL REFERENCES groups(gid) ON DELETE CASCADE,
       rid   INT NOT NULL REFERENCES repos(id) ON DELETE CASCADE,

       UNIQUE (gid, rid)
);
GRANT ALL ON readable TO gwa_webaccess;

CREATE TABLE subscriptions (
       rid   INT NOT NULL REFERENCES repos(id) ON DELETE CASCADE,
       uid   TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,

       UNIQUE (rid, uid)
);
GRANT ALL ON subscriptions TO gwa_webaccess;
GRANT SELECT ON subscriptions TO gwa_gitaccess;

CREATE TABLE logs_push (
       logid BIGSERIAL PRIMARY KEY,
       rid   INT NOT NULL REFERENCES repos(id) ON DELETE RESTRICT,
       uid   TEXT NOT NULL REFERENCES users(uid) ON DELETE RESTRICT,
       date  TIMESTAMP NOT NULL DEFAULT now(),
       old_id TEXT NOT NULL CHECK (char_length(old_id) = 40),
       new_id TEXT NOT NULL CHECK (char_length(new_id) = 40),
       ref   TEXT NOT NULL,
       notified BOOLEAN NOT NULL DEFAULT FALSE
);
GRANT SELECT, INSERT, UPDATE ON logs_push TO gwa_gitaccess;
GRANT ALL ON logs_push_logid_seq TO gwa_gitaccess;
GRANT ALL ON logs_push TO gwa_admin;
CREATE INDEX logs_push_uid_idx ON logs_push (uid);
CREATE INDEX logs_push_ref_idx ON logs_push (ref);

COMMIT;
