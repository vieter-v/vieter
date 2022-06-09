# Cron schedule syntax

The Vieter cron daemon uses a subset of the cron expression syntax to schedule
builds.

## Format

`a b c d`

* `a`: minutes
* `b`: hours
* `c`: days
* `d`: months

An expression consists of two to four sections. If less than four sections are
provided, the parser will append `*` until there are four sections. This means
that `0 3` is the same as `0 3 * *`.

Each section consists of one or more parts, separated by a comma. Each of these
parts, in turn, can be one of the following (any letters are integers):

* `*`: allow all possible values.
* `a`: only this value is allowed.
* `*/n`: allow every n-th value.
* `a/n`: allow every n-th value, starting at a in the list.
* `a-b`: allow every value between a and b, bounds included.
* `a-b/n`: allow every n-th value inside the list of values between a and b,
  bounds included.

Each section can consist of as many of these parts as necessary.

## Examples

* `0 3`: every day at 03:00AM.
* `0 0 */7`: every 7th day of the month, at midnight.

## CLI tool

The Vieter binary contains a command that shows you the next matching times for
a given expression. This can be useful to understand the syntax. For more
information, see
[vieter-schedule(1)](https://rustybever.be/man/vieter/vieter-schedule.1.html).
