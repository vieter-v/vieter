PRAGMA foreign_keys=off;

BEGIN TRANSACTION;

ALTER TABLE Target RENAME TO _Target_old;

CREATE TABLE Target (
    id INTEGER PRIMARY KEY,
    url TEXT NOT NULL,
    branch TEXT,
    repo TEXT NOT NULL,
    schedule TEXT,
    kind TEXT NOT NULL DEFAULT 'git'
);

INSERT INTO Target (id, url, branch, repo, schedule, kind)
    SELECT id, url, branch, repo, schedule, kind FROM _Target_old;

DROP TABLE _Target_old;

COMMIT;

PRAGMA foreign_keys=on;
