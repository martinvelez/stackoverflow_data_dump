# get_posts.rb

def parse_tags_str(tags_str)
tags = []
	tags_str ||= ''
	tag = ''	
	tags_str.each_char do |c|
		if c == '<'
			tag = ''
		elsif c == '>'
			tags << tag	
		else
			tag += c
		end	
	end

	return tags
end


def get_posts(lang)
	# read large xml file
	fname = "Posts.xml"
	xml = Nokogiri::XML::Reader(File.open(fname))

	# open database
	db = SQLite3::Database.new("#{lang}_posts.db")
	db.execute("CREATE TABLE IF NOT EXISTS posts (id integer, body text, owner_display_name varchar(255), creation_date text, last_edit_date text, tags text, score integer, favorite_count integer)")


	# construct prepared statement, for efficiency
	sql = "INSERT INTO posts (id, body, owner_display_name, creation_date, last_edit_date, tags, score, favorite_count) VALUES (?, ?, ?, ?, ?, ?, ?, ?)"
	stmt = db.prepare(sql)

	trans_size = 50000
	post_count = 0
	lang_count = 0
	dirty = false
	xml.each do |posts|
		posts.each do |row|
			next if row.node_type == 14 # TYPE_SIGNIFICANT_WHITESPACE
			post_count += 1
			puts "post_count: #{post_count}" if post_count % 1000000 == 0
			id = row.attribute("Id").to_i
			tags_str = row.attribute("Tags")	
			tags = parse_tags_str(tags_str)
			#puts tags.inspect
			if tags.include?(lang)
				lang_count += 1
				puts "#{lang}_count: #{lang_count}" if lang_count % trans_size == 0
				#puts tags.inspect
				if lang_count % trans_size == 1
					db.transaction 
					dirty = true 
				end
				
				body = row.attribute("Body")
				owner = row.attribute("OwnerDisplayName")
				creation = row.attribute("CreationDate")
				edit = row.attribute("LastEditDate")
				score = row.attribute("Score")
				favorite_count = row.attribute("FavoriteCount")
				favorite_count = 0 if favorite_count.nil?
				stmt.execute(id, body, owner, creation, edit, tags_str, score, favorite_count)
				if lang_count % trans_size == 0
					db.commit 
					dirty = false
				end
			end
		end
	end

	if dirty == true
		db.commit 
		puts 'Final commit'
	end

	puts "post_count: #{post_count}"
	puts "#{lang}_count: #{lang_count}"
end #get_posts
