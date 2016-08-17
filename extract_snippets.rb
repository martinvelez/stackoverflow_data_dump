# extract_snippets.rb

require 'digest'


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
	db_snippets.execute("CREATE TABLE IF NOT EXISTS snippets (id integer, snippet text, sha1 varchar(40), so_post_id, so_score integer, so_favorite_count, word_count integer)")

	# Construct prepared statement, for performance 
	sql = "INSERT INTO snippets (id, snippet, sha1, so_post_id, so_score, so_favorite_count) VALUES (?, ?, ?, ?, ?, ?)"
	stmt_insert_snippet = db_snippets.prepare(sql)

	# Parse each post
	id = 1 
	rows = db_posts.execute("SELECT * from posts ORDER BY id")
	puts "Posts = #{rows.size}"
	db_snippets.transaction
	rows.each do |row|	
		#puts row.inspect
		post_id = row[0]
		score = row[6]
		favorite_count = row[7]
		favorite_count = 0 if favorite_count.nil?
		snippets = post_to_snippets(row[1])
		snippets.each do |snippet|
			stmt_insert_snippet.execute(id, snippet, Digest::SHA1.hexdigest(snippet), post_id, score, favorite_count)
			id = id + 1
		end
	end
	db_snippets.commit

	puts "Snippets = #{id}"
end # extract snippets
