-- I'm not sure whether I should remove any non-git targets here. Keeping them
-- will result in invalid targets, but removing them means losing data.
ALTER TABLE Target DROP COLUMN kind;

