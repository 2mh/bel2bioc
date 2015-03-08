#!/usr/bin/env ruby
# vim: ts=2 sw=2

require 'bel'
require 'ostruct'
require 'csv'
require 'date'
require_relative 'cli_walkStatement.rb'
require_relative 'bioc_walkStatement.rb'

$debug = false
DF = "DEFINE NAMESPACE"
URL = 'AS URL "http://www.example.com/example.belns"'

def main
	unless ARGV.length == 0
		args = ARGV[0].split ""
	else
		argError
	end
		
	arglist = ['b', 'c', 'd', 'p', 't', 'a', 'm']
	hasargs = false
	
	args.each do |arg|
		if arglist.include? arg
			hasargs = true
			break
		end
	end
	
	if args.include? 'd'
		$debug = true
	end
	
	if !$debug
		collection = SimpleBioC::Collection.new()
		if args.include? 'm'
			puts "Enter collection souce:"
			collection.source = STDIN.gets.strip
			puts "Enter collection key:"
			usrkey = STDIN.gets.chomp
			if usrkey.rpartition(".")[-1] == "key"
				collection.key = usrkey
			else
				puts "Error: Not a valid key file"
				abort
			end
			puts "Override collection date (YYYY-MM-DD) or leave blank for system date:"
			usrdate = STDIN.gets.chomp
			unless usrdate.length == 0
				begin
					collection.date = Date.parse(usrdate)
				rescue ArgumentError
					puts "Error: Not a valid date"
					abort
				end
			else
				collection.date = Time.new.strftime("%Y-%m-%d")
			end
		end
	end
	
	if hasargs
		ARGV[1..-1].each do |infile|
			unless args.include? 't'
				belfile = File.new(infile, "r")
			else
				csvObj = csvReader(infile)
				belfile = belBuilder(csvObj)
			end
			
			# Shortnames for namespaces
			namespace_mapping = {GO:GOBP}
			
			# Create parse tree top-down
			statements = []

			# Extract BEL statements from the document
			BEL::Script.parse(belfile, namespace_mapping) do |obj|
				if obj.instance_of?(BEL::Language::Statement)
					statements << obj
				end
			end
			
			# Instantiate comment string for converted BEL statements
			commentString = "<!--\nBioC from #{statements.length} statements\n"
			
			statements.each do |obj|

				# BioC generation
				if args.include? 'b'

					# create a collection for each document in debug mode
					if $debug
						collection = SimpleBioC::Collection.new()
					end
					
					# One document with one passage per statement
					statementObj = OpenStruct.new()
					statementObj.obj = obj
					statementObj.document = SimpleBioC::Document.new(collection)
					statementObj.passage = SimpleBioC::Passage.new(statementObj.document)
					statementObj.passage.offset = nil
					statementObj.document.passages << statementObj.passage
					
					if args.include? 'p'
						statementObj.placeholders = true
					end
					
					unless args.include? 't'
						statementObj.document.id = "d" + String($documentId)
						increment(:document)
					else
						bel_meta = csvObj.rowArray.shift
						statementObj.document.id = bel_meta.bel_id
						statementObj.passage.text = bel_meta.sentence
						statementObj.tabulated = true
						if args.include? 'a'
							statementObj.passage.infons["sentence id"] = bel_meta.sentence_id
							statementObj.passage.infons["PMID"] = bel_meta.pmid
						end
					end
					
					collection.documents << statementObj.document
					
					BioC.walkStatement(statementObj, commentString)
					
					# Output BioC for each statement in debug mode
					if $debug
						xml = SimpleBioC.to_xml(collection)
						puts xml
					end

				# CLI output 
				elsif args.include? 'c'
					Cli.walkStatement(obj)
				end
			end
			
			# BioC comment splicing and output (normal mode)
			if args.include? 'b' and !$debug
				commentString << "-->\n"
				xml = SimpleBioC.to_xml(collection)
				xml = String(xml).lines.insert(1, commentString).join("")
				outfile = infile.rpartition(".")[0] + ".xml"
				File.open(outfile, 'w') { |file| file.write(xml) }
				puts "Conversion of #{infile} completed."
			end
			counterReset()
		end
		puts "Done."
	else
		argError
	end
end

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

if __FILE__ == $0
	main()
end
