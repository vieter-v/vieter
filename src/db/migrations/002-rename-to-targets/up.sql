ALTER TABLE GitRepo RENAME TO Target;
ALTER TABLE GitRepoArch RENAME TO TargetArch;

ALTER TABLE TargetArch RENAME COLUMN repo_id TO target_id;
ALTER TABLE BuildLog RENAME COLUMN repo_id TO target_id;
