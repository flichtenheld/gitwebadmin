--
--  Copyright (C) 2009,2010 Astaro GmbH & Co. KG  www.astaro.com
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation; either version 2 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License along
--  with this program; if not, write to the Free Software Foundation, Inc.,
--  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
--
--  Author: Frank Lichtenheld <flichtenheld@astaro.com> 07.07.2009

DROP TABLE keys   CASCADE;
DROP TYPE  ssh_key_type;
DROP TABLE push_acl CASCADE;
DROP TYPE  push_action_type;
DROP TYPE  acl_result_type;
DROP TABLE users  CASCADE;
DROP TABLE groups CASCADE;
DROP TABLE repo_tags CASCADE;
DROP TABLE repos  CASCADE;
DROP TABLE writable CASCADE;
DROP TABLE readable CASCADE;
DROP TABLE members  CASCADE;
DROP TABLE subscriptions CASCADE;
DROP TABLE logs_push CASCADE;
DROP TABLE branches CASCADE;
DROP TABLE external_triggers CASCADE;
DROP TABLE repo_triggers CASCADE;
DROP TYPE  trigger_method_type;
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
       id    SERIAL PRIMARY KEY,
       uid   TEXT NOT NULL UNIQUE,
       name  TEXT,
       mail  TEXT,
       admin BOOLEAN NOT NULL DEFAULT FALSE,
       active BOOLEAN NOT NULL DEFAULT TRUE,
       directory TEXT NOT NULL DEFAULT 'local',

       CONSTRAINT users_admin_active CHECK (NOT (admin AND NOT active)),
       CONSTRAINT users_gitadm_active CHECK (NOT (uid='gitadm' AND NOT active))
);
CREATE INDEX users_name_idx ON users (name);
GRANT SELECT, UPDATE ON users TO gwa_webaccess;
GRANT SELECT ON users TO gwa_gitaccess;
GRANT ALL ON users TO gwa_admin;
GRANT ALL ON users_id_seq TO gwa_admin;

CREATE OR REPLACE FUNCTION user_id (text) RETURNS int AS $$
       SELECT id FROM users u WHERE u.uid = $1
$$ LANGUAGE SQL STABLE STRICT;
INSERT INTO users (uid, name) VALUES
       ('gitadm', 'Git Administrator');

CREATE TYPE ssh_key_type AS ENUM ('rsa', 'dsa');

CREATE TABLE keys (
       id    SERIAL PRIMARY KEY,
       uid   INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
       name  TEXT NOT NULL,
       bits  INT NOT NULL CHECK (floor(log(2,bits)) = log(2,bits)),
       type  ssh_key_type,
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
GRANT SELECT ON groups TO gwa_gitaccess;

INSERT INTO groups VALUES
       ('gitosis-admin', 'Gitosis Adminstrators');

CREATE TABLE members (
       uid   INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
       gid   TEXT NOT NULL REFERENCES groups(gid) ON DELETE CASCADE,

       PRIMARY KEY(uid,gid)
);
GRANT ALL ON members TO gwa_webaccess;
GRANT SELECT ON members TO gwa_gitaccess;

INSERT INTO members VALUES
       (user_id('gitadm'), 'gitosis-admin');

CREATE TABLE repos (
       id    SERIAL PRIMARY KEY,
       name  TEXT NOT NULL UNIQUE,
       descr  TEXT,
       branch TEXT NOT NULL DEFAULT 'master',
       private  BOOLEAN NOT NULL DEFAULT FALSE,
       daemon   BOOLEAN NOT NULL DEFAULT FALSE,
       gitweb   BOOLEAN NOT NULL DEFAULT FALSE,
       owner    INT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
       forkof   INT REFERENCES repos(id) ON DELETE RESTRICT,
       mirrorof TEXT,
       mirrorupd INT DEFAULT 86400 CHECK ((mirrorupd >= 600) AND (mirrorupd <= 604800)),
       deleted  BOOLEAN NOT NULL DEFAULT FALSE,

       CONSTRAINT repos_hidden_deleted CHECK (NOT (deleted AND (gitweb OR daemon))),
       CONSTRAINT repos_one_parent CHECK (NOT (forkof IS NOT NULL AND mirrorof IS NOT NULL))
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
       ('gitosis-admin.git', user_id('gitadm'));

CREATE TABLE repo_tags (
       rid   INT REFERENCES repos(id) ON DELETE CASCADE,
       tag   TEXT NOT NULL,

       PRIMARY KEY (rid, tag)
);
GRANT ALL ON repo_tags TO gwa_webaccess;
GRANT SELECT ON repo_tags TO gwa_gitaccess;

CREATE TYPE push_action_type AS ENUM ('create', 'update', 'replace', 'delete');
CREATE TYPE acl_result_type  AS ENUM ('allow', 'deny');

CREATE TABLE push_acl (
       id       SERIAL PRIMARY KEY,
       priority INT UNIQUE NOT NULL,
       "user"   INT REFERENCES users(id) ON DELETE CASCADE,
       "group"  TEXT REFERENCES groups(gid) ON DELETE CASCADE,
       repo     INT REFERENCES repos(id) ON DELETE CASCADE,
       user_flags   TEXT,
       repo_flags   TEXT,
       ref          TEXT,
       action       push_action_type,
       result       acl_result_type NOT NULL DEFAULT 'deny',
       comment      TEXT
);
GRANT SELECT ON push_acl TO gwa_webaccess;
GRANT SELECT ON push_acl TO gwa_gitaccess;

INSERT INTO push_acl
       (priority, "user", repo, user_flags, repo_flags, action,  result, comment)
VALUES
       (1000,       NULL, NULL,    'admin',      NULL,    NULL, 'allow', 'admin can do everything'),
       (2000,       NULL, NULL,  '!active',      NULL,    NULL,  'deny', 'deny everything to inactive users'),
       (3000,       NULL, NULL,       NULL, 'deleted',    NULL,  'deny', 'deleted repositories cannot be changed'),
       (4000,       NULL, NULL,       NULL,'mirrorof',    NULL,  'deny', 'only local pushes to mirror repositories'),
       (5000,       NULL, NULL,       NULL, 'private',    NULL, 'allow', 'allow everything in private repositories'),
       (6000,       NULL, NULL,       NULL,      NULL,'delete',  'deny', 'cannot delete references in public repositories'),
       (6010,       NULL, NULL,       NULL,      NULL,'replace', 'deny', 'cannot replace references in public repositories');

CREATE VIEW show_push_acl AS
       SELECT push_acl.id, priority, "user", "group", repos.name AS repository, user_flags, repo_flags, ref, action, result, comment
       FROM push_acl LEFT OUTER JOIN repos ON repo = repos.id ORDER BY priority;

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
GRANT SELECT ON branches TO gwa_webaccess;
GRANT ALL ON branches_id_seq TO gwa_gitaccess;

--
-- ### END MANTIS INTEGRATION ###
--

CREATE TABLE writable (
       gid   TEXT NOT NULL REFERENCES groups(gid) ON DELETE CASCADE,
       rid   INT NOT NULL REFERENCES repos(id) ON DELETE CASCADE,

       PRIMARY KEY (gid, rid)
);
GRANT ALL ON writable TO gwa_webaccess;
INSERT INTO writable VALUES
       ('gitosis-admin', repo_id('gitosis-admin.git'));

CREATE TABLE readable (
       gid   TEXT NOT NULL REFERENCES groups(gid) ON DELETE CASCADE,
       rid   INT NOT NULL REFERENCES repos(id) ON DELETE CASCADE,

       PRIMARY KEY (gid, rid)
);
GRANT ALL ON readable TO gwa_webaccess;

CREATE TABLE subscriptions (
       rid   INT NOT NULL REFERENCES repos(id) ON DELETE CASCADE,
       uid   INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

       PRIMARY KEY (rid, uid)
);
GRANT ALL ON subscriptions TO gwa_webaccess;
GRANT SELECT ON subscriptions TO gwa_gitaccess;

CREATE TABLE logs_push (
       logid BIGSERIAL PRIMARY KEY,
       rid   INT NOT NULL REFERENCES repos(id) ON DELETE RESTRICT,
       uid   INT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
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

CREATE TYPE trigger_method_type AS ENUM('ssh', 'http', 'local');

CREATE TABLE external_triggers (
	id   SERIAL PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        method trigger_method_type NOT NULL DEFAULT 'ssh',
        uri  TEXT NOT NULL UNIQUE
);
GRANT ALL ON external_triggers TO gwa_webaccess;
GRANT ALL ON external_triggers_id_seq TO gwa_webaccess;
GRANT SELECT ON external_triggers TO gwa_gitaccess;

CREATE TABLE repo_triggers (
	rid  INT NOT NULL REFERENCES repos(id) ON DELETE CASCADE,
        tid  INT NOT NULL REFERENCES external_triggers(id) ON DELETE CASCADE,

        PRIMARY KEY(rid, tid)
);
GRANT ALL ON repo_triggers TO gwa_webaccess;
GRANT SELECT ON repo_triggers TO gwa_gitaccess;

COMMIT;
