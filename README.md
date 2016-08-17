# stackoverflow_data_dump

Stack Exchange, the company that owns Stack Overflow, made a data dump available on http://archive.org.
I downloaded the stackoverflow.com-Posts.7z file from https://archive.org/details/stackexchange. 
I wrote these scripts to get the posts by tag, extract the code snippets, and index the snippets by word.  


## Requirements

My Ruby:

* ruby 2.2.1p85

My Gems:

* nokogiri (1.6.7)
* sqlite3 (1.3.11)

## Usage

````
./create_tables.rb LANG TABLE
````

Example 1: Get the posts, snippets, and words used in posts tagged with `c`.
````bash
$ ./create_tables.rb c posts 
$ ./create_tables.rb c snippets
$ ./create_tables.rb c words 
````

* The first command creates the `c_posts.db` database file and a `posts` table.
* The second command creates the `c_snippets.db` database file and a `snippets` table.
* The third command creates the `words` and `word_snippets` tables in the `c_snippets.db` database.

