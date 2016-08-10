#!/usr/bin/env ruby


require_relative 'get_posts'
require_relative 'extract_snippets'
require_relative 'extract_words'
require_relative 'indices'


# Process command line argument
langs = ["python", "c", "c#", "c++", "java"]
tbls = ["posts", "posts_index", "snippets", "delete_duplicate_snippets", "create_indices", "update_snippet_scores", "words", "word_snippets"]

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
when 'posts_index'
	create_posts_index(lang)
when "snippets"
	extract_snippets(lang)
when "delete_duplicate_snippets"
	delete_duplicate_snippets(lang)
when "update_snippet_scores"
	update_snippet_scores(lang)
when 'words'
	extract_words(lang)	
when "create_indices"
	create_indices(lang)
when "word_snippets"
	# open database
	db_snippets = SQLite3::Database.new("#{lang}_snippets.db")
	sql = "CREATE TABLE IF NOT EXISTS #{tbl} AS SELECT word_id, snippet_id FROM word_posts AS W INNER JOIN post_snippets AS S ON W.post_id=S.post_id;"
	db_snippets.execute(sql)
	result = db_snippets.execute("SELECT count(*) FROM #{tbl}")
	puts result.inspect
	puts "Finished!"
end
