require_relative 'parser'


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
	db = SQLite3::Database.new("#{lang}_snippets.db")
	begin
		db.execute(sql)
	rescue Exception => e
		puts e
	end
	sql = "SELECT * from snippets order by id" 
	stmt_select = db.prepare(sql)
	sql = "UPDATE snippets SET word_count=? WHERE id=?" 
	stmt_update = db.prepare(sql)
	rows = stmt_select.execute!
	puts "Snippets = #{rows.size}"
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
	rows = db_posts.execute("SELECT id, body FROM posts")
	posts = {}
	rows.each { |row| posts[row[0]] = row[1] }
	db_posts.close
	
	db_snippets = SQLite3::Database.new("#{lang}_snippets.db")
	db_snippets.execute("CREATE TABLE IF NOT EXISTS words (id integer, word varchar(255))")
	db_snippets.execute("CREATE TABLE IF NOT EXISTS word_snippets (word_id integer, snippet_id integer)")

	stmt_insert_word = db_snippets.prepare("INSERT INTO words (id, word) VALUES (?, ?)")
	stmt_insert_word_snippet = db_snippets.prepare("INSERT INTO word_snippets (word_id, snippet_id) VALUES (?, ?)")

	words_hash = {}
	rows = db_snippets.execute("SELECT id, so_post_id FROM snippets ORDER BY id")
	puts "Snippets = #{rows.size}"
	rows.each do |row|	
		id = row[0]
		post_id = row[1]
		words = tokenize(posts[post_id])
		words.each do |word|
			if words_hash.has_key?(word) 
				words_hash[word] << id 
			else
				words_hash[word] = [id]
			end
		end
	end
	puts "Unique Words = #{words_hash.keys.size}"
	
	puts 'Sorting and removing snippet_ids from word_id => snippet_ids'
	words_hash.update(words_hash) do |w,ss| 
		ss.sort!
		ss.uniq!
		ss
	end

	puts "Inserting words and word-to-snippet into database."
	w = 0
	total = words_hash.keys.size
	db_snippets.transaction
		words_hash.each do |word,ss|
			#(puts word; exit) if ps.empty? 
			w = w + 1
			puts "#{w} / #{total}" if w % 100000 == 0
			stmt_insert_word.execute(w, word)
			ss.each { |s| stmt_insert_word_snippet.execute(w, s) }	
		end
	db_snippets.commit	
	puts "#{w} / #{total}"
	ws = db_snippets.get_first_value("SELECT count(*) from word_snippets")
	puts "word_snippets = #{ws}"
end
