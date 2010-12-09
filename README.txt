General Hawk
=========================

This is the commander for CI Joe.  It allows you to run multiple CI Joe instances
and aggregate the results of each of them.  It contains custom build-failed and
build-worked scripts that you can drop in your CI Joe instances to have them tell
General Hawk what they've been up to.

General Hawk is meant to sit somewhere neutral like a Heroku instance and listen
to CI Joes that authenticate with a token.  It also has a script you can put in
the cron of your CI Joe machines that allow them to poll their Git repositories
and automatically run when they see an update, so if you have a number of build
agents on different architectures sitting behind a firewall that can't recieve 
post-receive POSTs the system will still work.

General Hawk is simply set up to receive a JSON post of the following format:

POST /update/TOKEN
---
{
  "agent":"windows-agent-msvc",
  "description":"library testing on windows MSVC",
  "branch":"master",
  "sha":"7f4150e324bb5e47f5c740c08628b7210c379bfa",
  "status":"pass", # or 'fail' or 'building',
  "url":"http://github.com/schacon/lib/commit/7f4150e324bb5e47f5c740c08628b7210c379bfa",
  "short_message":"Build 7f4150e of lib was successful (389s).",
  "full_message":"Full output of the run" # optional, generally on fail
}

General Hawk will keep track of what the agents last status per branch was and
display a summary.
