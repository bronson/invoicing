# Invoicing

For the code monkey who wants to address the crushing tedium of invoicing
with the rigid hopelessness of a 70s-era batch processing system.


# Invoicing Sucks

Don't do it.


# Overview

- Clone this repo
- Change the config file to match your needs
- Collect some commit info.  Write some .hours files.
- Run `./run`.  Your invoices will appear.
- Change the .slim templates until your invoices look nice.
- Run `./run-pdf` to produce PDFs suitable for the suits.



First you drop a bunch of files with data in this folder.  The files can be:

* .hours file: a list of the time ranges you worked, with comments.  Hand-edited.

* .json file: an automated list of time ranges.  See the collect/collector scripts for how to dump these from a Git repo.

* .mbox file: a From-delimited mbox file containing emails from the project.

* TODO: other sensitive files are TOTALS, .lines, .emails, .csv, .txt

Now, run the ./run script.  This crunches all the data in the files down
into out.csv and out.txt.  Look at the report it prints...  Does it look
correct?  Especially when diff'd against last month's?

The invoice.slim template decides what your invoice will look like.

### To collect data from git repos:

  - cd into the git repo
  - run the ~/invoices/collect script

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


# History of nsame

These scripts started life in 2012 when I was generating timesheets with
a spreadsheet.  So, there I was, months into a contract without having
recorded my hours...  (on day five, I could work on catching up on my invoices, or I could work
on far more interesting stuff and deal with it on day 6, repeat for 50 days).

In a semi-panic, I whipped up some quick scripts to crunch data from
git commits, emails sent, and ad hoc notes dropped in random repos, and
show as best it could what I had done on that day.  It was originally named "NSA Me".

Things then started growing really poorly.  I got tired of copying from tables of
\t-formatted numbers, so I added CSV output.  Then HTML output.  Then,
why not format the HTML so it kind of paginates?  Eventually this clumsy
invoicing batch system started to be recognizable.

Yesterday, some friends asked how I invoice while freelancing.  Well, this
is how.  Now it's on github.  May you all suffer.
