# Parse CSV, write to structured object
def csvReader(file)
	csvTable = CSV.read(file, {col_sep:"\t", quote_char:"¬", headers:true})
	parsedObj = OpenStruct.new()
	parsedObj.rowArray = []
	parsedObj.belArray = []
	csvTable.each do |row|
		current = OpenStruct.new()
		current.bel_id = row[0]
		current.bel = row[1]
		current.sentence = row[3]
		current.sentence_id = row[4]
		current.pmid = row[5]
		parsedObj.rowArray << current
		parsedObj.belArray << row[1]
	end
	return parsedObj
end

# Generate minimal BEL document on-the-fly as bel.rb parser input
def belBuilder(pObj)
	documentString = ""
	documentString << 'SET DOCUMENT Name = "BEL document generated for parsing purposes by bel2bioc"'
	breakln(documentString)
	documentString << 'SET DOCUMENT Description = "Note: This is an automatically created BEL document with dummy definitions. It\'s not intended for usage outside of bel2bioc conversion."'
	
	emptyln(documentString)
	
	nameSpaces = File.open("namespaces")
	nameSpaces.each do |ns|
		documentString << "#{DF} #{ns.chomp!} #{URL}"
		breakln(documentString)
	end
	emptyln(documentString)
	pObj.belArray.each do |bel|
		if bel
			documentString << bel
			breakln(documentString)
		end
	end
	return documentString
end
