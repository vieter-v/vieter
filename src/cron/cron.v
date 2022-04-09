module cron

import git

pub fn cron(conf Config) ? {
	repos_map := git.get_repos(conf.address, conf.api_key) ?
}
