First you drop a bunch of files with data in this folder:

.hours file: a list of the time ranges you worked, with comments.  Hand-edited.

.json file: an automated list of time ranges.  See the collect/collector scripts for how to dump these from a Git repo.

.emails file: a From-delimited mbox file containing emails from the project.


Now, run the ./run script.  This crunches all the data in the files down
into out.csv and out.txt.  Look at the report it prints...  Does it look
correct?  Especially when diff'd against last month's?


If so, run the ./bill script.  This reads the TOTALS file, generates any
new invoices, and ensures old invoices are still correct.


The invoice.slim template decides what your invoice will look like.
