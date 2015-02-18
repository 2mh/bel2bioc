#!/usr/bin/env ruby
# vim: ts=2 sw=2

require 'bel'
require_relative 'cli_walkStatement.rb'
require_relative 'bioc_walkStatement.rb'

$debug = false

def main
	if !$debug
		collection = SimpleBioC::Collection.new()
	end
	
	if ["-b", "-c"].include? ARGV[0]
		unless ARGV[0].instance_of?(NilClass)
			ARGV[1..-1].each do |infile|
				belfile = File.new(infile, "r")
		
				# parse; yield each parsed object to the block
				namespace_mapping = {GO:GOBP}
				
				# Create parse tree top-down
				statements = []
				BEL::Script.parse(belfile, namespace_mapping) do |obj|
					if obj.instance_of?(BEL::Language::Statement)
						statements << obj
					end
				end
				
				commentString = "<!--\nBioC from #{statements.length} statements"
				
				statements.each do |obj|
					if ARGV[0] == "-b"			
						if $debug
							collection = SimpleBioC::Collection.new()
						end
						
						document = SimpleBioC::Document.new(collection)
						passage = SimpleBioC::Passage.new(document)
						passage.offset = nil
						document.passages << passage
						
						document.id = "d" + String($documentId)
						increment(:document)
									
						collection.documents << document
						
						BioC.walkStatement(obj, document, passage, false, commentString)
						
						if $debug
							xml = SimpleBioC.to_xml(collection)
							puts xml
						end
					elsif ARGV[0] == "-c"
						Cli.walkStatement(obj, document, passage, false)
					end
				end
				
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
