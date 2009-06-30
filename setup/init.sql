DROP TABLE users  CASCADE;
DROP TABLE groups CASCADE;
DROP TABLE repos  CASCADE;
DROP TABLE writable CASCADE;
DROP TABLE readable CASCADE;
DROP TABLE members  CASCADE;
DROP ROLE gwa_webaccess;

BEGIN;

CREATE ROLE gwa_webaccess LOGIN PASSWORD 'foobar';

CREATE TABLE users (
       uid   TEXT PRIMARY KEY,
       name  TEXT,
       mail  TEXT,
       key   TEXT,
       admin BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE INDEX users_name_idx ON users (name);
GRANT SELECT, UPDATE ON users TO gwa_webaccess;

INSERT INTO users VALUES
       ('gitadm', 'Git Administrator');

CREATE TABLE groups (
       gid   TEXT PRIMARY KEY,
       name  TEXT,
       descr  TEXT
);
GRANT SELECT, UPDATE ON groups TO gwa_webaccess;

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
       private  BOOLEAN NOT NULL DEFAULT FALSE,
       daemon   BOOLEAN NOT NULL DEFAULT FALSE,
       gitweb   BOOLEAN NOT NULL DEFAULT FALSE,
       owner    TEXT NOT NULL REFERENCES users(uid) ON DELETE RESTRICT,
       forkof   INT REFERENCES repos(id) ON DELETE SET NULL
);
CREATE INDEX repos_name_idx ON repos (name);
GRANT ALL ON repos TO gwa_webaccess;
GRANT ALL ON SEQUENCE repos_id_seq TO gwa_webaccess;

CREATE OR REPLACE FUNCTION repo_id (text) RETURNS int AS $$
       SELECT id FROM repos r WHERE r.name = $1
$$ LANGUAGE SQL STABLE STRICT;
INSERT INTO repos (name, owner) VALUES
       ('gitosis-admin.git', 'gitadm');

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

COMMIT;
