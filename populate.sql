DELETE FROM users;
DELETE FROM groups;
DELETE FROM user_groups;
DELETE FROM sessions;
DELETE FROM user_sessions;

ALTER SEQUENCE groups_id_seq RESTART;
ALTER SEQUENCE sessions_id_seq RESTART;

INSERT INTO users VALUES ('a', 'Alex', 'Token');
INSERT INTO users VALUES ('b', 'Beatrice', 'Token');
INSERT INTO users VALUES ('c', 'Charlie', 'Token');

INSERT INTO groups(name, access_code) VALUES ('Coffee Gang', 'AAACCC');
INSERT INTO groups(name, access_code) VALUES ('Big Nerds', 'AAABBB');
INSERT INTO groups(name, access_code) VALUES ('Caffine Feinds', 'AAAAAA');

INSERT INTO user_groups VALUES ('a', 1);
INSERT INTO user_groups VALUES ('b', 1);
INSERT INTO user_groups VALUES ('c', 1);

INSERT INTO obligations(user_id, day, hour) VALUES ('a', 0, 8);
INSERT INTO obligations(user_id, day, hour) VALUES ('a', 1, 8);
INSERT INTO obligations(user_id, day, hour) VALUES ('a', 2, 8);
INSERT INTO obligations(user_id, day, hour) VALUES ('a', 3, 8);
INSERT INTO obligations(user_id, day, hour) VALUES ('a', 4, 8);
INSERT INTO obligations(user_id, day, hour) VALUES ('a', 5, 8);
INSERT INTO obligations(user_id, day, hour) VALUES ('a', 6, 8);

--INSERT INTO sessions(day, hour, accepted, pending) VALUES (0, 8, false, true);
