#!/usr/bin/env ruby 

require 'sqlite3'

def number_with_comma(number)
	number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
end


def top_words
	tags = ['c', 'c#', 'c++', 'java', 'python']
	ls = {}
	tags.each { |tag| ls[tag] = [] }

	s = ''	
	tags.each { |tag| s += "Word (#{tag}) | Snippets | % |" }
	s.chop!

	s += "\n"
	tags.each { |tag| s += ":--- | ---: | ---: |" }
	s.chop!

	totals = {}
	tags.each do |tag|
		db = SQLite3::Database.new("#{tag}_snippets.db")
		total = db.get_first_value("SELECT count(*) FROM word_snippets")
		rs = db.execute("SELECT word, c FROM (SELECT word_id, count(*) AS c FROM word_snippets GROUP BY word_id) AS W join words ON W.word_id=words.id order by c desc limit 10")
		rs.each { |r| ls[tag] << [r[0], r[1], (r[1].to_f / total) * 100] }
	end

	for i in 0..9 do
		s += "\n"
		tags.each do |tag|
			s += "#{ls[tag][i][0]} | #{ls[tag][i][1]} | #{'%.02f' % ls[tag][i][2]} |"
		end
		s.chop! 	
	end

	puts s
end


def collection_stats 
	tags = ['c', 'c#', 'c++', 'java', 'python']
	
	s = []
	a = ['Symbol', '|', 'Statistic']
	b = [':---', '|', ':---']
	tags.each do |tag|
		a << '|'
		a << tag.capitalize 
		b << '|'
		b << '---:'
	end
	s << a
	s << b
	s << ['N', '|', 'Posts with Snippets (documents)']
	s << ['-', '|', 'all posts']
	s << ['S', '|', 'Code Snippets']
	s << ['-', '|', 'avg. # of snippets per post']
	s << ['-', '|', 'avg. # of snippets per term']
	s << ['M', '|', 'Terms (unique, case folding)']
	s << ['-', '|', 'avg. # of tokens (words) per post']


	ls = {}
	tags.each do |tag|
		ls[tag] = {}
		db_s = SQLite3::Database.new("#{tag}_snippets.db")
		db_p = SQLite3::Database.new("#{tag}_posts.db")
		ls[tag]['p'] = db_p.get_first_value("SELECT count(id) FROM posts WHERE has_snippet=1")
		ls[tag]['p_with_s'] = db_p.get_first_value("SELECT count(id) FROM posts")
		ls[tag]['s'] = db_s.get_first_value("SELECT count(id) FROM snippets")
		ls[tag]['avg_s_per_p'] = db_s.get_first_value("SELECT avg(c) FROM (SELECT post_id, count(*) AS c FROM post_snippets GROUP BY post_id)")
		ls[tag]['avg_s_per_t'] = db_s.get_first_value("SELECT avg(c) FROM (SELECT word_id, count(*) AS c FROM word_snippets GROUP BY word_id)")
		ls[tag]['t'] = db_s.get_first_value("SELECT count(*) FROM words")
		ls[tag]['avg_t_per_p'] = db_p.get_first_value("SELECT avg(word_count) FROM posts")
		db_s.close
		db_p.close
	end

	tags.each do |tag|
		ls[tag].each.with_index(2) do |p,i|
			s[i] << '|'
			if [2,3,4,7].include?(i)
				s[i] << number_with_comma(p[1])	
			else
				s[i] << p[1].round(2) 
			end
		end
	end

	s.each { |row| puts row.join(' ')}
end

choice = ARGV[0].to_i
case choice
when 0
	collection_stats	
when 1
	post_stats
when 2
	top_words
end
