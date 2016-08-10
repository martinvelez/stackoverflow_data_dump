require "sqlite3"


def create_index(lang, idx)
	db_name = "#{lang}_snippets.db"	
	
	case idx
	when 'posts_id_idx'
		db_name = "#{lang}_posts.db"	
		sql = "CREATE INDEX IF NOT EXISTS #{idx} ON posts (id)"
	when 'snippets_id_idx'
		sql = "CREATE INDEX IF NOT EXISTS #{idx} ON snippets (id)"
	when 'post_snippets_snippet_id_idx'
		sql = "CREATE INDEX IF NOT EXISTS #{idx} ON post_snippets (snippet_id)"
	when 'post_snippets_post_id_idx'
		sql = "CREATE INDEX IF NOT EXISTS #{idx} ON post_snippets (post_id)"
	when 'word_posts_post_id_idx'
		sql = "CREATE INDEX IF NOT EXISTS #{idx} ON word_posts (post_id)"	
	when 'word_posts_snippet_id_idx'
		sql = "CREATE INDEX IF NOT EXISTS #{idx} ON word_posts (word_id)"	
	when 'word_snippets_word_id_idx'
		sql = "CREATE INDEX IF NOT EXISTS #{idx} ON word_snippets (word_id)"	
	when 'word_snippets_snippet_id_idx'
		sql = "CREATE INDEX IF NOT EXISTS #{idx} ON word_snippets (snippet_id)"	
	end
	
	begin
		db = SQLite3::Database.new("#{lang}_snippets.db")
		result = db.execute(sql)
	rescue Exception => e
		result = e	
	end	

	puts result.inspect
end


def create_indices(lang)
	indices = []	
	indices.push 'snippets_id_idx'
	indices.push 'post_snippets_snippet_id_idx'
	indices.push 'post_snippets_post_id_idx'
	indices.push 'word_posts_post_id_idx'
	indices.push 'word_posts_snippet_id_idx'
	indices.push 'word_snippets_word_id_idx'
	indices.push 'word_snippets_snippet_id_idx'
	indices.each do |idx|
		puts "idx = #{idx}"
		create_index(lang, idx)	
	end
end

