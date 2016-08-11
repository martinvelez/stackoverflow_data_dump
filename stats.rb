#!/usr/bin/env ruby 

require 'sqlite3'


def number_with_comma(number)
	number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
end

def top_words
	langs = {}
	langs['c'] = []
	langs['c#'] = []
	langs['c++'] = []
	langs['java'] = []
	langs['python'] = []

	s = ''	
	tags = langs.keys
	tags.each do |tag|
		s += " Word | #{tag} | % |"
	end
	s.chop!

	tags.each do |tag|
		db_s = SQLite3::Database.new("#{tag}_snippets.db")
		total = db_p.execute("SELECT count(*) FROM words")[0][0]
		langs[tag] << total 
		result = db_p.execute("SELECT word, c FROM (SELECT word_id, count(*) AS c FROM word_snippets GROUP BY word_id) AS WS join words ON WS.word_id=words.id order by c desc limit 10"
		langs[tag] << result[0][0] 
		langs[tag] << result[0][1] 
		langs[tag] << (result[0][1] / total.to_f) 
	end
	
end


def post_stats
	tags = ['c', 'c#', 'c++', 'java', 'python']
	s = 'Tag | All Posts | Posts with Snippets | Snippets | Snippets/Post'
	s += "\n"
	s += ':--- | ---: | ---: | ---: | ---:'
	tags.each do |tag|
		db_s = SQLite3::Database.new("#{tag}_snippets.db")
		db_p = SQLite3::Database.new("#{tag}_posts.db")

		result = db_p.execute("SELECT count(*) FROM posts")
		p_count = number_with_comma(result[0][0])

		result = db_p.execute("SELECT count(*) FROM posts WHERE has_snippet=1")
		p_count_s = number_with_comma(result[0][0])

		result = db_s.execute("SELECT count(*) FROM snippets")
		s_count = number_with_comma(result[0][0])

		result = db_s.execute("SELECT avg(c) FROM (SELECT post_id, count(*) AS c FROM post_snippets GROUP BY post_id)")
		avg = result[0][0]

		s += "\n"
		s += "#{tag} | #{p_count} | #{p_count_s } | #{s_count} | #{'%.02f' % avg}"
	end

	puts s
end


def word_stats
	tags = ['c', 'c#', 'c++', 'java', 'python']
	s = 'Tag | Words | Words/Post | Word-to-Snippet Edges | Mean Snippets/Word'
	s += "\n"
	s += ':------------- | -------------: | -------------: | -------------: | -------------:'
	tags.each do |tag|
		db_s = SQLite3::Database.new("#{tag}_snippets.db")
		db_p = SQLite3::Database.new("#{tag}_posts.db")

		result = db_s.execute("SELECT count(*) from words")
		word_count= number_with_comma(result[0][0])

		result = db_p.execute("SELECT avg(word_count) FROM posts")
		words_per_post = result[0][0]

		result = db_s.execute("SELECT count(*) FROM word_snippets")
		word_to_snippet = number_with_comma(result[0][0])

		result = db_s.execute("SELECT avg(c) FROM (SELECT word_id, count(*) as c FROM word_snippets GROUP BY word_id) AS t")
		avg_snippets_per_word = result[0][0]

		s += "\n"
		s += "#{tag} | #{word_count} | #{'%.02f' % words_per_post } | #{word_to_snippet} | #{'%.02f' % avg_snippets_per_word}"
	end
	puts s
end

choice = ARGV[0].to_i
case choice
when 0
	word_stats
when 1
	post_stats
end
