ALTER TABLE Target RENAME TO GitRepo;
ALTER TABLE TargetArch RENAME TO GitRepoArch;

ALTER TABLE GitRepoArch RENAME COLUMN target_id TO repo_id;
ALTER TABLE BuildLog RENAME COLUMN target_id TO repo_id;
