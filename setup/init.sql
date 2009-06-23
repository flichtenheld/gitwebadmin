
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
       key   TEXT
);
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
       uid   TEXT NOT NULL REFERENCES users(uid),
       gid   TEXT NOT NULL REFERENCES groups(gid),

       UNIQUE(uid,gid)
);
GRANT SELECT ON members TO gwa_webaccess;

INSERT INTO members VALUES
       ('gitadm', 'gitosis-admin');

CREATE TABLE repos (
       id    SERIAL PRIMARY KEY,
       name  TEXT NOT NULL UNIQUE,
       descr  TEXT,
       private  BOOLEAN NOT NULL DEFAULT FALSE,
       daemon   BOOLEAN NOT NULL DEFAULT FALSE,
       gitweb   BOOLEAN NOT NULL DEFAULT FALSE,
       owner    TEXT NOT NULL REFERENCES users(uid),
       forkof   INT REFERENCES repos(id)
);
CREATE INDEX repos_name_idx ON repos (name);
GRANT ALL ON repos TO gwa_webaccess;

CREATE OR REPLACE FUNCTION repo_id (text) RETURNS int AS $$
       SELECT id FROM repos r WHERE r.name = $1
$$ LANGUAGE SQL STABLE STRICT;
INSERT INTO repos (name, owner) VALUES
       ('gitosis-admin.git', 'gitadm');

CREATE TABLE writable (
       gid   TEXT NOT NULL REFERENCES groups(gid),
       rid   INT NOT NULL REFERENCES repos(id),

       UNIQUE (gid, rid)
);
GRANT ALL ON writable TO gwa_webaccess;
INSERT INTO writable VALUES
       ('gitosis-admin', repo_id('gitosis-admin.git'));

CREATE TABLE readable (
       gid   TEXT NOT NULL REFERENCES groups(gid),
       rid   INT NOT NULL REFERENCES repos(id),

       UNIQUE (gid, rid)
);
GRANT ALL ON readable TO gwa_webaccess;

COMMIT;
