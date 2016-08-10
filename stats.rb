require 'sqlite3'

def word_stats
	tags = ['c', 'c#', 'c++', 'java', 'python']
	s = 'Tag | Words | Words/Post | Word-to-Snippet Edges | Mean Snippets/Word'
	s += "\n"
	s += ':------------- | -------------: | -------------: | -------------: | -------------:'
	tags.each do |tag|
		db_p = SQLite3::Database.new("#{tag}_posts.db")
		db_s = SQLite3::Database.new("#{tag}_snippets.db")
		h = {}
		result = db_s.execute("SELECT count(*) from words")
		word_count = result[0][0]	
		result = db_p.execute("SELECT avg(word_count) from posts")
		words_per_post = result[0][0]
		result = db_s.execute("SELECT avg(c) FROM (SELECT word_id, count(*) as c FROM word_snippets GROUP BY word_id) AS t")
		avg_snippets_per_word = result[0][0]
		s += "\n"
		s += "#{tag} | #{word_count} | #{words_per_post} | #{word_to_snippet} | #{avg_snippets_per_word}"
	end
	puts s
end

word_stats
