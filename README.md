# Invoicing

For the code monkey who wants to address the crushing tedium of invoicing
with the rigid hopelessness of a 70s-era batch processing system.


# Warning

I wouldn't bother trying to figure this out until there are some examples.


# Abandoned

And, until I start freelancing again, this repo won't see any activity.


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


# License

MIT for great freedom.


# History

So there I was, months into a contract without having recorded any hours...
I had notes scribbled, emails sent, and commits committed, but it was going to
take days to assemble all this into an invoice.  I whipped
up some scripts to crunch the data down and produce a calendar of what I had
done and when.  It worked, and reconciled the metadata trail I had left
behind, so it was called "NSA Me".

Then things then started growing poorly.  I got tired of copying from
tables of \t-formatted numbers so I added CSV output.  Then HTML output.
Then I formatted the HTML so it kind of paginates.  A clumsy
invoicing batch system started to become recognizable.

Yesterday, some friends asked how I invoice while freelancing.  Well, this
is how.  And now it's on github.  May you all suffer.
