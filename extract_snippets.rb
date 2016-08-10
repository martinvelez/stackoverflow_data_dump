# extract_snippets.rb

require 'digest'


# After removing all duplicate snippets, run this method.
def update_snippet_scores(lang)
	puts "update_snippet_scores(#{lang})"
	db = SQLite3::Database.new("#{lang}_snippets.db")

	#sql = "CREATE TABLE temp AS SELECT snippet_id, sum(score), sum(favorite_count) from post_snippets group by snippet_id order by snippet_id"
	#db.execute(sql)
	sql = "select snippet_id, sum(score), sum(favorite_count) from post_snippets group by snippet_id order by snippet_id"
	stmt_select = db.prepare(sql)
	sql = "UPDATE snippets SET score_total=?, favorite_count_total=? WHERE id=?"
	stmt_update = db.prepare(sql)
	rows = stmt_select.execute!
	puts "snippet_count = #{rows.size}"

	i = 0
	db.transaction
	rows.each do |row|
		puts "i = #{i}" if i % 10000  == 0
		i = i + 1	
		score = row[1]
		favorite_count = row[2]
		score = 0 if score.nil?
		favorite_count = 0 if favorite_count.nil?
		stmt_update.execute(score, favorite_count, row[0])
	end
	db.commit
end


# After getting posts, run this method.
# Find duplicate snippets.
# Update all Post-to-Snippet mappings.
# Delete duplicate snippets.
def delete_duplicate_snippets(lang)
	puts "delete_duplicates(#{lang})"
	db = SQLite3::Database.new("#{lang}_snippets.db")

	# Find sets of duplicates
	sql = "SELECT sha1, count(*) AS c, group_concat(id) FROM snippets GROUP BY sha1 HAVING c > 1"
	stmt_select = db.prepare(sql)
	rows = stmt_select.execute!
	puts "rows.size = duplicate sets count = #{rows.size}"

	# For each set, pick a representative snippet.
	# Update all post-to-snippet mappings with representative snippet id.
	# Delete duplicate snippets.
	i = 0
	db.transaction
	rows.each do |row|
		i = i + 1	
		puts "i = #{i}" if i % 100  == 0
		ids_str = row[2]
		# keep one representative
		rep = ids_str.slice!(0..ids_str.index(',')) 
		rep.chomp!(',')
		# Update all Post-to-Snippet mappings.
		db.execute("UPDATE post_snippets set snippet_id=#{rep} WHERE snippet_id IN (#{ids_str})")
		# Delete duplicate snippets from snippets table
		db.execute("DELETE FROM snippets WHERE id in (#{ids_str})")
	end	
	db.commit
	
	result = db.execute("SELECT count(*) from snippets")
	puts "Unique snippets = #{result.inspect}"
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
	# open database
	db_posts = SQLite3::Database.new("#{lang}_posts.db")
	db_snippets = SQLite3::Database.new("#{lang}_snippets.db")
	db_snippets.execute("CREATE TABLE IF NOT EXISTS snippets (id integer, snippet text, score_total integer, favorite_count_total, sha1 varchar(40))")
	db_snippets.execute("CREATE TABLE IF NOT EXISTS post_snippets (post_id integer, snippet_id integer, score integer, favorite_count integer)")

	trans_size = 10000

	# Construct prepared statement, for performance 
	sql = "INSERT INTO snippets (id, snippet, score_total, favorite_count_total, sha1) VALUES (?, ?, ?, ?, ?)"
	stmt_insert_snippet = db_snippets.prepare(sql)
	sql = "INSERT INTO post_snippets (post_id, snippet_id, score, favorite_count) VALUES (?, ?, ?, ?)" 
	stmt_insert_ps = db_snippets.prepare(sql)

	# Paginate, for low RAM
	sql = "SELECT * from posts where id > ? order by id LIMIT #{trans_size}" 
	stmt_select = db_posts.prepare(sql)

	# Parse each post
	id = 0
	last_id = 0
	rows = stmt_select.execute!(last_id)
	puts "rows.size = post count = #{rows.size}"
	while !rows.empty?
		db_snippets.transaction
		rows.each do |row|	
			#puts "row[0] = #{row[0]}"
			post_id = row[0]
			last_id = row[0]
			score = row[6]
			favorite_count = row[7]
			favorite_count = 0 if favorite_count.nil?
			snippets = post_to_snippets(row[1])
			snippets.each do |snippet|
				sha1 = Digest::SHA1.hexdigest(snippet)
				stmt_insert_snippet.execute(id, snippet, score, favorite_count, sha1)
				stmt_insert_ps.execute(post_id, id, score, favorite_count)
				id = id + 1
			end
		end
		db_snippets.commit	
		rows = stmt_select.execute!(last_id)
		puts "post_id: #{last_id}"
		puts "Snippet id: #{id}"
	end

	puts "last post_id: #{last_id}"
	puts "snippets: #{id}"
end # extract snippets
