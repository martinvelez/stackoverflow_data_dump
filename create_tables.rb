#!/usr/bin/env ruby


require_relative 'get_posts'
require_relative 'extract_snippets'
require_relative 'words'
require_relative 'indices'


# Process command line argument
langs = ["python", "c", "c#", "c++", "java"]
tbls = ["posts", "snippets", "create_indices", "words", "word_snippets", "update_word_counts"]

lang = ARGV[0]
if langs.nil? or !langs.include?(lang)
	puts "#{__FILE__} LANGUAGE TABLE"
	puts "Languages = #{langs.inspect}"
	puts "Tables = #{tbls.inspect}"
	exit
end

tbl = ARGV[1]
if tbl.nil? or !tbls.include?(tbl)
	puts "./#{__FILE__} LANGUAGE TABLE"
	puts "Languages = #{langs.inspect}"
	puts "Tables = #{tbls.inspect}"
	exit
end
	
# Which Table?
case tbl
when 'posts'
	get_posts(lang)
	create_indices(lang)
	update_word_counts(lang)	
when 'update_word_counts' 
	update_word_counts(lang)	
when "snippets"
	extract_snippets(lang)
	create_indices(lang)
	delete_duplicate_snippets(lang)
	update_snippet_scores(lang)
	update_has_snippet(lang)
when 'words'
	extract_words(lang)	
	create_indices(lang)
when "word_snippets"
	# open database
	db_snippets = SQLite3::Database.new("#{lang}_snippets.db")
	sql = "CREATE TABLE IF NOT EXISTS #{tbl} AS SELECT word_id, snippet_id FROM word_posts AS W INNER JOIN post_snippets AS S ON W.post_id=S.post_id GROUP by W.word_id, S.snippet_id"
	db_snippets.execute(sql)
	result = db_snippets.execute("SELECT count(*) FROM #{tbl}")
	puts result.inspect
	puts "Finished!"
	create_indices(lang)
when "create_indices"
	create_indices(lang)
else
	create_indices(lang)
end

