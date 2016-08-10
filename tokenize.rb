require 'nokogiri'

def tokenize(html_fragment)
	text = ''
	doc = Nokogiri::HTML.fragment(html_fragment)
	doc.traverse do |node|
		text += node.text
	end			
	#words = text.split(' ') #tokenize
	words = text.split(/[^[[:word:]]]+/)
	words.map! { |w| w.downcase }

	return words
end
