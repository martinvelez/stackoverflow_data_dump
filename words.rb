require  'nokogiri'
require "sqlite3"
require_relative 'parser'


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
	# open database
	puts "extract_words(#{lang})"
	db_posts = SQLite3::Database.new("#{lang}_posts.db")
	db_snippets = SQLite3::Database.new("#{lang}_snippets.db")
	db_snippets.execute("CREATE TABLE IF NOT EXISTS words (id integer, word varchar(255) unique)")
	db_snippets.execute("CREATE TABLE IF NOT EXISTS word_posts (post_id integer, word_id varchar(255))")

	trans_size = 100000

	sql = "SELECT * from posts where id > ? order by id LIMIT #{trans_size}" 
	stmt_select = db_posts.prepare(sql)
	sql = "INSERT INTO words (id, word) VALUES (?, ?)"
	stmt_insert_word = db_snippets.prepare(sql)
	sql = "INSERT INTO word_posts (word_id, post_id) VALUES (?, ?)"
	stmt_insert_post_word = db_snippets.prepare(sql)

	words_hash = {}
	last_id = 0
	rows = stmt_select.execute!(last_id)
	puts "rows.size = #{rows.size}"
	while !rows.empty?
		rows.each do |row|	
			#puts "row[0] = #{row[0]}"
			post_id = row[0]
			last_id = row[0]
			words = tokenize(row[1])
			#puts words.inspect
			words.each do |word|
				if words_hash.has_key?(word)
					words_hash[word] << post_id
				else
					words_hash[word] = []
				end
			end
		end
		rows = stmt_select.execute!(last_id)
		puts "last_id: #{last_id}"
	end

	puts 'Sorting and removing duplicate snippets from word->snippet'
	words_hash.update(words_hash) do |w,ps|
		ps.uniq!
		ps.sort!	
	end

	word_count = 0
	dirty = false
	puts "Found #{words_hash.keys.size} unique words."
	puts "Inserting words and word-to-post into database.  This may take a while."
	words_hash.each do |w,ps|
		word_count = word_count + 1
		if word_count % trans_size == 1
			db_snippets.transaction
			dirty = true
		end

		stmt_insert_word.execute(word_count, w)
		ps.each do |p|
			stmt_insert_post_word.execute(word_count, p)
		end
			
		if word_count % trans_size == 0
			db_snippets.commit	
			dirty = false
		end
	end

	if dirty == true
		puts 'final commit'
		db_snippets.commit	
	end

	puts "word_count = #{word_count}"
	puts "Finished!"
end
