CREATE TABLE IF NOT EXISTS GitRepo (
    id INTEGER PRIMARY KEY,
    url TEXT NOT NULL,
    branch TEXT NOT NULL,
    repo TEXT NOT NULL,
    schedule TEXT
);

CREATE TABLE IF NOT EXISTS GitRepoArch (
    id INTEGER PRIMARY KEY,
    repo_id INTEGER NOT NULL,
    value TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS BuildLog (
    id INTEGER PRIMARY KEY,
    repo_id INTEGER NOT NULL,
    start_time INTEGER NOT NULL,
    end_time iNTEGER NOT NULL,
    arch TEXT NOT NULL,
    exit_code INTEGER NOT NULL
);
