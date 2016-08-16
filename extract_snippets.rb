# extract_snippets.rb

require 'digest'


def update_has_snippet(lang)
	puts "update_has_snippet(#{lang})"
	db_posts = SQLite3::Database.new("#{lang}_posts.db")
	db_snippets = SQLite3::Database.new("#{lang}_snippets.db")
	rows = db_snippets.execute("SELECT post_id FROM post_snippets GROUP BY post_id")
	row_str = rows.to_s.gsub('[','').gsub(']','')
	db_snippets.close

	begin
		sql = "ALTER TABLE posts ADD COLUMN has_snippet boolean"	
		db_posts.execute(sql)
	rescue Exception => e
		puts e
	end

	db_posts.execute("UPDATE posts SET has_snippet=0")
	db_posts.execute("UPDATE posts SET has_snippet=1 WHERE id IN (#{row_str})")
	result = db_posts.execute("SELECT count(id) FROM posts WHERE has_snippet=1")

	puts "Post with Snippets = #{result[0][0]}"
end



# After removing all duplicate snippets, run this method.
def update_snippet_scores(lang)
	puts "update_snippet_scores(#{lang})"
	db = SQLite3::Database.new("#{lang}_snippets.db")

	sql = "UPDATE snippets SET score_total=?, favorite_count_total=? WHERE id=?"
	stmt_update = db.prepare(sql)

	sql = "SELECT snippet_id, sum(score), sum(favorite_count) from post_snippets group by snippet_id order by snippet_id"
	rows = db.execute(sql)
	puts "snippet_count = #{rows.size}"
	i = 0
	db.transaction
	rows.each do |row|
		i = i + 1	
		score = row[1]
		favorite_count = row[2]
		score = 0 if score.nil?
		favorite_count = 0 if favorite_count.nil?
		stmt_update.execute(score, favorite_count, row[0])
	end
	db.commit
end


def post_to_snippets(text)
	snippets = []
	doc = Nokogiri::HTML.parse(text)
	codeSnippets = doc.css('pre').to_a
	codeSnippets.each do |s|
		snippet = s.inner_text
		if snippet.size > 0 # don't include empty strings
			snippets << snippet
		end
	end

	return snippets
end



# extract snippets from posts
# create snippets table
# create post_snippets table
def extract_snippets(lang)
	db_posts = SQLite3::Database.new("#{lang}_posts.db")
	db_snippets = SQLite3::Database.new("#{lang}_snippets.db")
	db_snippets.execute("CREATE TABLE IF NOT EXISTS snippets (id integer, snippet text, sha1 varchar(40), so_post_id, so_score integer, so_favorite_count_total)")

	# Construct prepared statement, for performance 
	sql = "INSERT INTO snippets (id, snippet, score_total, favorite_count_total, sha1) VALUES (?, ?, ?, ?, ?)"
	stmt_insert_snippet = db_snippets.prepare(sql)
	#sql = "INSERT INTO post_snippets (post_id, snippet_id, score, favorite_count) VALUES (?, ?, ?, ?)" 
	#stmt_insert_ps = db_snippets.prepare(sql)

	# Parse each post
	id = 0
	rows = db_posts.execute("SELECT * from posts ORDER BY id")
	puts "Posts = #{rows.size}"
	db_snippets.transaction
	rows.each do |row|	
		post_id = row[0]
		score = row[6]
		favorite_count = row[7]
		favorite_count = 0 if favorite_count.nil?
		snippets = post_to_snippets(row[1])
		snippets.each do |snippet|
			stmt_insert_snippet.execute(id, snippet, Digest::SHA1.hexdigest(snippet), post_id, score, favorite_count)
			#stmt_insert_ps.execute(post_id, id, score, favorite_count)
			id = id + 1
		end
	end
	db_snippets.commit

	puts "Snippets = #{id}"
end # extract snippets
