#!/usr/bin/env ruby
# vim: ts=2 sw=2

require 'bel'
require 'ostruct'
require_relative 'cli_walkStatement.rb'
require_relative 'bioc_walkStatement.rb'

# Debugging flag
$debug = false

def main
	if !$debug
		collection = SimpleBioC::Collection.new()
	end
	
	# -b: Output to BioC
	# -c: Output of attributes to CLI (debugging)
	if ["-b", "-c"].include? ARGV[0]
		unless ARGV[0].instance_of?(NilClass)
			ARGV[1..-1].each do |infile|
				belfile = File.new(infile, "r")
		
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
					if ARGV[0] == "-b"			

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
						statementObj.document.id = "d" + String($documentId)
						
						increment(:document)
									
						collection.documents << statementObj.document
						
						BioC.walkStatement(statementObj, commentString)
						
						# Output BioC for each statement in debug mode
						if $debug
							xml = SimpleBioC.to_xml(collection)
							puts xml
						end

					# CLI output 
					elsif ARGV[0] == "-c"
						Cli.walkStatement(obj, document, passage, false)
					end
				end
				
				# BioC comment splicing and output (normal mode)
				if ARGV[0] == "-b" and !$debug
					commentString << "-->\n"
					xml = SimpleBioC.to_xml(collection)
					xml = String(xml).lines.insert(1, commentString).join("")
					puts xml
				end
				counterReset()
			end
		else
			puts "Usage: main.rb -[b|c] <file>"
		end
	else
		puts "Usage: main.rb -[b|c] <file>"
	end
end

if __FILE__ == $0
	main()
end
