#!/usr/bin/env ruby


require_relative 'get_posts'
require_relative 'extract_snippets'
require_relative 'words'
require_relative 'indices'


def print_usage(langs, tbls)
	puts "#{__FILE__} LANGUAGE TABLE"
	puts "Languages = #{langs.inspect}"
	puts "Tables = #{tbls.inspect}"
end


langs = ["python", "c", "c#", "c++", "java"]
tbls = ["posts", "snippets", "words", "create_indices"]

# Process command line argument
lang = ARGV[0]
if langs.nil? or !langs.include?(lang)
	print_usage
	exit
end

tbl = ARGV[1]
if tbl.nil? or !tbls.include?(tbl)
	print_usage
	exit
end
	

# Which Table?
case tbl
when 'posts'
	get_posts(lang)
	create_indices(lang)
when "snippets"
	extract_snippets(lang)
	create_indices(lang)
when 'words'
	extract_words(lang)	
	#create_indices(lang)
when "create_indices"
	create_indices(lang)
end

