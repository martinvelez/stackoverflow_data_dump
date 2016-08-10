require 'nokogiri'


def tokenize(html_fragment, downcase = true, unique = true)
	text = ''
	doc = Nokogiri::HTML.fragment(html_fragment)
	doc.traverse do |node|
		text += node.text
	end			
	#words = text.split(' ') #tokenize
	words = text.split(/[^[[:word:]]]+/)
	words.map! { |w| w.downcase }
	words.uniq! if unique 

	return words
end


def word_count(html_fragment)
	text = ''
	doc = Nokogiri::HTML.fragment(html_fragment)
	doc.traverse do |node|
		text += node.text
	end			
	#words = text.split(' ') #tokenize
	words = text.split(/[^[[:word:]]]+/)

	return words.size
end
