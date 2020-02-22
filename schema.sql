DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

CREATE TABLE users (
  gid  text PRIMARY KEY
, name text NOT NULL
, messaging_token text NOT NULL
);

CREATE TABLE groups (
  id          serial PRIMARY KEY
, name        text NOT NULL
, access_code text NOT NULL
);

CREATE TABLE user_groups (
  user_id  text
, group_id int
, FOREIGN KEY (user_id)  REFERENCES users (gid) ON UPDATE CASCADE ON DELETE CASCADE
, FOREIGN KEY (group_id) REFERENCES groups (id) ON UPDATE CASCADE ON DELETE CASCADE
, CONSTRAINT user_groups_pkey PRIMARY KEY (user_id, group_id)  -- explicit pk
);

CREATE TABLE obligations (
  id serial PRIMARY KEY
, user_id text
, day int
, hour int
, FOREIGN KEY (user_id) REFERENCES users(gid) ON UPDATE CASCADE ON DELETE CASCADE
);
