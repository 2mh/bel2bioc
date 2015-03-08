require 'colorize'
require 'bel'
require_relative 'helpers'
require_relative 'cli_walkTerm'

$slice = 30
$debug = false

module Cli
	module_function
	def walkStatement(obj)
		if $debug
			puts "[[ #{obj.to_bel} ]]\n".bold
		else
			puts "#{obj.to_bel}\n"
		end
	
		# Output of parsed nodes to command-line
	
		puts "Subject:".black.on_green.bold + " " + String(obj.subject)
		
		# Walk subject term
		Cli.walkTerm(obj.subject, 0)
		
		puts "Relationship:".black.on_green.bold + " " + String(obj.relationship)
		
		puts "Object:".black.on_green.bold + " " + String(obj.object)
		
		# Walk object term
		Cli.walkTerm(obj.object, 0)
		
		puts "Annotations: ".light_cyan + String(obj.annotations)
		puts "Comment: ".light_cyan + String(obj.comment)
		puts "Subject only?: ".light_cyan + String(obj.subject_only?)
		puts "Simple?: ".light_cyan + String(obj.simple?)
		puts "Nested?: ".light_cyan + String(obj.nested?)
		puts "BEL: ".light_cyan + String(obj.to_bel)
		begin
			puts "RDF: ".light_cyan + String(obj.to_rdf).slice(0,$slice)
			puts "URI: ".light_cyan + String(obj.to_uri)
		rescue NoMethodError
		end
		puts "Hash: ".light_cyan + String(obj.hash)
	end
end
