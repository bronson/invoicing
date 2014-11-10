# Invoicing Sucks

Don't do it.

## Usage

First you drop a bunch of files with data in this folder.  The files can be:

* .hours file: a list of the time ranges you worked, with comments.  Hand-edited.

* .json file: an automated list of time ranges.  See the collect/collector scripts for how to dump these from a Git repo.

* .mbox file: a From-delimited mbox file containing emails from the project.

Now, run the ./run script.  This crunches all the data in the files down
into out.csv and out.txt.  Look at the report it prints...  Does it look
correct?  Especially when diff'd against last month's?

The invoice.slim template decides what your invoice will look like.

### To collect data from git repos:

  - cd into the git repo
  - run the ~/invoices/collect script
  - copy the resulting JSON file into this folder.

### To collect data from email:
  - Just drop .mbox files into the folder.
  - If you're using gmail, you'll have to export using the Mac mail app I guess

You'll need to type in the other data manually.

## Fields

When writing your own data parser, this is the information you can supply:

* hash: git hash
* date: start date of task
* end: stop date of task  TODO
* duration: duration of task (if no end or duration given, assumes default task length)
* comment: reminder of what you did or git commit message
* src: where a particular item came from

