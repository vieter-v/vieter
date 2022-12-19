---
weight: 20
---

# Cleanup

Vieter stores the logs of every single package build. While this is great for
debugging why builds fail, it also causes an active or long-running Vieter
instance to accumulate thousands of logs.

To combat this, a log removal daemon can be enabled that periodically removes
old build logs. By starting your server with the `max_log_age` variable (see
[Configuration](/configuration#vieter-server)), a daemon will get enabled that
periodically removes logs older than this setting. By default, this will happen
every day at midnight, but this behavior can be changed using the
`log_removal_schedule` variable.

{{< hint info >}}
**Note**  
The daemon will always run a removal of logs on startup. Therefore, it's
possible the daemon will be *very* active when first enabling this setting.
After the initial surge of logs to remove, it'll calm down again.
{{< /hint >}}
