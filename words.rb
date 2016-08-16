require  'nokogiri'
require "sqlite3"
require_relative 'parser'

def create_word_snippets(lang)
	puts "create_word_snippets(#{lang})"
	db_snippets = SQLite3::Database.new("#{lang}_snippets.db")
	sql = "CREATE TABLE IF NOT EXISTS word_snippets AS SELECT word_id, snippet_id FROM word_posts AS W INNER JOIN post_snippets AS S ON W.post_id=S.post_id GROUP by W.word_id, S.snippet_id"
	db_snippets.execute(sql)
	result = db_snippets.execute("SELECT count(*) FROM word_snippets")
	puts result.inspect
	create_indices(lang)
end


def create_term_frequency(lang)
	db = SQLite3::Database.new("#{lang}_snippets.db")
	sql = "CREATE TABLE IF NOT EXISTS term_frequency AS SELECT word_id, count(*) AS frequency FROM word_snippets group by word_id"
	db.execute(sql)
	sql = "SELECT count(*) FROM term_frequency"
	result = db.execute(sql)
	puts result.inspect
end

def update_word_counts(lang)
	puts "count_words(#{lang})"
	db = SQLite3::Database.new("#{lang}_posts.db")
	sql = "ALTER TABLE posts ADD COLUMN word_count integer" 
	begin
		db.execute(sql)
	rescue Exception => e
		puts e
	end
	sql = "SELECT * from posts order by id" 
	stmt_select = db.prepare(sql)
	sql = "UPDATE posts SET word_count=? WHERE id=?" 
	stmt_update = db.prepare(sql)
	rows = stmt_select.execute!
	puts "Posts = #{rows.size}"
	db.transaction
	i = 0
	rows.each do |row|
		post_id = row[0]
		word_count = word_count(row[1])
		stmt_update.execute(word_count, post_id) 
		i = i + 1
		puts "i = #{i}" if i % 100000 == 0
	end
	db.commit
end


def extract_words(lang)
	db_posts = SQLite3::Database.new("#{lang}_posts.db")
	db_snippets = SQLite3::Database.new("#{lang}_snippets.db")
	db_snippets.execute("CREATE TABLE IF NOT EXISTS words (id integer, word varchar(255))")
	db_snippets.execute("CREATE TABLE IF NOT EXISTS word_posts (word_id integer, post_id integer)")

	stmt_insert_word = db_snippets.prepare("INSERT INTO words (id, word) VALUES (?, ?)")
	stmt_insert_word_post = db_snippets.prepare("INSERT INTO word_posts (word_id, post_id) VALUES (?, ?)")

	words_hash = {}
	rows = db_posts.execute("SELECT id, body FROM posts WHERE has_snippet=1 order by id")
	puts "Posts with Snippets = #{rows.size}"
	rows.each do |row|	
		post_id = row[0]
		words = tokenize(row[1])
		words.each do |word|
			if words_hash.has_key?(word) 
				words_hash[word] << post_id 
			else
				words_hash[word] = [post_id]
			end
		end
	end
	puts "Unique Words = #{words_hash.keys.size}"
	
	puts 'Sorting and removing post_ids from word_id => post_ids'
	words_hash.update(words_hash) do |w,ps| 
		ps.sort!
		ps.uniq!
		ps
	end

	puts "Inserting words and word-to-post into database."
	w = 0
	total = words_hash.keys.size
	db_snippets.transaction
	words_hash.each do |word,ps|
		#(puts word; exit) if ps.empty? 
		w = w + 1
		puts "#{w} / #{total}" if w % 100000 == 0
		stmt_insert_word.execute(w, word)
		ps.each { |p| stmt_insert_word_post.execute(w, p) }	
	end
	db_snippets.commit	
	puts "#{w} / #{total}"
end
