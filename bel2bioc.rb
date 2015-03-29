#!/usr/bin/env ruby
# vim: ts=2 sw=2

begin
	require 'bel'
	rescue LoadError
		puts "Error: bel2bioc requires the ruby gem bel.rb (https://github.com/OpenBEL/bel.rb)"
		abort
end
require 'ostruct'
require 'csv'
require 'date'
require_relative 'cli_walkStatement'
require_relative 'bioc_walkStatement'
require_relative 'bioc_tabulatedConversion'

$debug = false

def main
	argv = ARGV[0]
	
	unless ARGV.length == 0
		args = argv.split ""
	else
		argError
	end
	
	unless args[0] == '-' and (args.include? 'b' or args.include? 'c')
		argError
	end
	
	arglist = ['b', 'c', 'd', 'p', 't', 'a', 'm', 'o', 's']
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
			puts "Enter collection source:"
			collection.source = STDIN.gets.strip
			puts "Enter collection key:"
			usrkey = STDIN.gets.chomp
			if usrkey.rpartition(".")[-1] == "key"
				collection.key = usrkey
			else
				puts "Error: Not a valid key file"
				abort
			end
			puts "Enter collection date (YYYY-MM-DD) or press Enter for system date:"
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
		puts "Files to process: #{ARGV[1..-1].length}"
		if args.include? 'd'; puts "Debugging mode active, single collection per statement, output to stdout."; end
		ARGV[1..-1].each do |infile|
			puts "Processing #{infile} ..."
			unless args.include? 't'
				belfile = File.new(infile, "r")
			else
				puts "Generating BEL from tabulated file ..."
				csvObj = csvReader(infile)
				belfile = belBuilder(csvObj)
			end
			
			# Shortnames for namespaces
			namespace_mapping = {GO:GOBP}
			
			# Create parse tree top-down
			statements = []

			puts "Parsing BEL document ..."
			# Extract BEL statements from the document
			BEL::Script.parse(belfile, namespace_mapping) do |obj|
				if obj.instance_of?(BEL::Language::Statement)
					statements << obj
				end
			end
			
			if statements.length == 0
				puts "Error: Invalid or empty BEL document #{infile}. Use argument 't' for tabulated source data."
				abort
			elsif args.include? 't' and statements.length < csvObj.linecount
				puts "Warning: Only #{statements.length} of #{csvObj.linecount} BEL statements in the source file have been parsed. \nPossible error in the BEL syntax on line #{statements.length + 2} of #{infile}."
			end
			
			# Instantiate comment string for converted BEL statements
			counterCommentString = "<!--\nBioC from #{statements.length} statements\n"
			commentString = counterCommentString.clone
			counterCommentString << "-->\n"
			
			
			puts "Building BioC structure ..."
			statements.each_with_index do |obj, idx|
			
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
					
					if $debug
						statementObj.debug = true
					end
					
					if args.include? 'p'
						statementObj.placeholders = true
					end
					
					if args.include? 'i'
						statementObj.includeBEL = true
					end
					
					unless args.include? 't'
						statementObj.document.id = "d" + String($documentId)
						increment(:document)
					else
						bel_meta = csvObj.rowArray.shift
						statementObj.document.id = bel_meta.bel_id
						statementObj.passage.text = bel_meta.sentence
						statementObj.tabulated = true
						unless args.include? 'a'
							statementObj.passage.infons["Sentence id"] = bel_meta.sentence_id
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
					
					# Simple progress indicator for large input data sets
					if idx != 0 and idx % 1000 == 0
						puts "Processed #{idx} statements ..."
					end
				# CLI output 
				elsif args.include? 'c'
					Cli.walkStatement(obj)
				end
			end
			
			# BioC comment splicing and output (normal mode)
			if args.include? 'b' and !$debug
				commentString << "-->\n"
				puts "Generating XML ..."
				xml = SimpleBioC.to_xml(collection)
				if args.include? 'o'
					finalCommentString = commentString
				else
					finalCommentString = counterCommentString
				end
				xml = String(xml).lines.insert(1, finalCommentString).join("")
				outfile = infile.rpartition(".")[0] + ".xml"
				outfileObj = File.open(outfile, 'w') { |file| file.write(xml) }
				puts "Conversion of #{infile} completed."
				outfileObj = nil
			end
			counterReset()
		end
		puts "Done."
		exit! # Need to force exit for large tabulated input data sets (cause unknown)
	else
		argError
	end
end

if __FILE__ == $0
	main()
end
