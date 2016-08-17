# stackoverflow_data_dump

Stack Exchange, the company that owns Stack Overflow, made a data dump available on http://archive.org.
I downloaded the stackoverflow.com-Posts.7z file from https://archive.org/details/stackexchange. 
I wrote these scripts to get the posts by tag, extract the code snippets, and index the snippets by word.  


## Requirements

My Ruby:

* ruby 2.2.1p85

My Gems:

* sqlite3 (1.3.11)
