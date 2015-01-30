require 'bel'
require 'simple_bioc'
require 'colorize'

$slice = 30

# Walk statement tree from the root
def walkStatement(obj)
	puts "##################### #{obj.to_bel} ########################\n".bold
	puts "Subject:".black.on_green.bold + " " + String(obj.subject)
	walkTerm(obj.subject)
	puts "Relationship:".black.on_green.bold + " " + String(obj.relationship)
	puts "Object:".black.on_green.bold + " " + String(obj.object)
	walkTerm(obj.object)
	puts "Annotations: ".light_cyan + String(obj.annotations)
	puts "Comment: ".light_cyan + String(obj.comment)
	puts "Subject only?: ".light_cyan + String(obj.subject_only?)
	puts "Simple?: ".light_cyan + String(obj.simple?)
	puts "Nested?: ".light_cyan + String(obj.nested?)
	puts "BEL: ".light_cyan + String(obj.to_bel)
	puts "RDF: ".light_cyan + String(obj.to_rdf).slice(0,$slice)
	puts "URI: ".light_cyan + String(obj.to_uri)
	puts "Hash: ".light_cyan + String(obj.hash)
end

# Recursively walk terms and parameter (leaf nodes)
def walkTerm(obj, sublevel = 0)
	tab = "\t"*2*sublevel 
	if obj.instance_of?(BEL::Language::Term)
		puts tab + "\tSublevel: ".yellow + String(sublevel)
		puts tab + "\tFX: ".yellow + String(obj.fx)
		puts tab + "\tSignature: ".yellow + String(obj.signature)
		puts tab + "\tValid?: ".yellow + String(obj.valid?)
		puts tab + "\tValid signatures: ".yellow + String(obj.valid_signatures)
		puts tab + "\tInvalid signatures: ".yellow + String(obj.invalid_signatures)
		puts tab + "\tRDF: ".yellow + String(obj.to_rdf).slice(0,$slice)
		puts tab + "\tRDF type: ".yellow + String(obj.rdf_type)
		puts tab + "\tURI: ".yellow + String(obj.to_uri)
		puts tab + "\tHash: ".yellow + String(obj.hash)
		puts tab + "\tArguments: ".yellow + String(obj.arguments)
		obj.arguments.each do |subobj|
			if subobj.instance_of?(BEL::Language::Term)
				puts tab + "\t\tTerm Argument:".yellow
				walkTerm(subobj, sublevel + 1)
			else
				puts tab + "\t\tParameter Argument: ".green + String(subobj)
				puts tab + "\t\t\tNS: ".green + String(subobj.ns)
				puts tab + "\t\t\tValue: ".green + String(subobj.value)
				puts tab + "\t\t\tEncoding: ".green + String(subobj.enc)
				puts tab + "\t\t\tSignature: ".green + String(subobj.signature)
				if not subobj.ns.is_a? NilClass
					puts tab + "\t\t\tRDF: ".green + String(subobj.to_rdf).slice(0,$slice)
					puts tab + "\t\t\tURI: ".green + String(subobj.to_uri)
				end
				puts tab + "\t\t\tHash: ".green + String(subobj.hash)
			end
		end
	end
end

ARGV.each do|infile|
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
	
	statements.each do |obj|
		walkStatement(obj)
		puts "\n\n"
	end
end
