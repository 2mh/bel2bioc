require 'bel'
require 'simple_bioc'

# Walk statement tree from the root
def walkStatement(obj)
	puts "##########################################################"
	puts "Subject: " + String(obj.subject)
	walkTerm(obj.subject)
	puts "Relationship: " + String(obj.relationship)
	puts "Object: " + String(obj.object)
	walkTerm(obj.object)
	puts "Annotations: " + String(obj.annotations)
	puts "Comment: " + String(obj.comment)
	puts "Subject only?: " + String(obj.subject_only?)
	puts "Simple?: " + String(obj.simple?)
	puts "Nested?: " + String(obj.nested?)
	puts "BEL:" + String(obj.to_bel)
	puts "RDF: " + String(obj.to_rdf).slice(0,300) + "... <snip />"
	puts "URI: " + String(obj.to_uri)
end

# Recursively walk terms and parameter (leaf nodes)
def walkTerm(obj, sublevel = 0)
	tab = "\t"*2*sublevel 
	if obj.instance_of?(BEL::Language::Term)
		puts tab + "\tSublevel: " + String(sublevel)
		puts tab + "\tFX: " + String(obj.fx)
		puts tab + "\tSignature: " + String(obj.signature)
		puts tab + "\tArguments: " + String(obj.arguments)
		obj.arguments.each do |subobj|
			if subobj.instance_of?(BEL::Language::Term)
				puts tab + "\t\tTerm Argument:\n"
				walkTerm(subobj, sublevel + 1)
			else
				puts tab + "\t\tParameter Argument: " + String(subobj)
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
	end
end
