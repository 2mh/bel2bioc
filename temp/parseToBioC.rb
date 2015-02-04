require 'bel'
require 'simple_bioc'
require 'colorize'

$slice = 30
$toScreen = false
$passageCounter = 0
$debug = true

# Walk statement tree from the root
def walkStatement(obj, document)
	puts "[[ #{obj.to_bel} ]]\n".bold
	if $toScreen
		puts "Subject:".black.on_green.bold + " " + String(obj.subject)
		walkTerm(obj.subject, 0)
		puts "Relationship:".black.on_green.bold + " " + String(obj.relationship)
		puts "Object:".black.on_green.bold + " " + String(obj.object)
		walkTerm(obj.object, 0)
		puts "Annotations: ".light_cyan + String(obj.annotations)
		puts "Comment: ".light_cyan + String(obj.comment)
		puts "Subject only?: ".light_cyan + String(obj.subject_only?)
		puts "Simple?: ".light_cyan + String(obj.simple?)
		puts "Nested?: ".light_cyan + String(obj.nested?)
		puts "BEL: ".light_cyan + String(obj.to_bel)
		puts "RDF: ".light_cyan + String(obj.to_rdf).slice(0,$slice)
		puts "URI: ".light_cyan + String(obj.to_uri)
		puts "Hash: ".light_cyan + String(obj.hash)
	else
		# Instantiate passage
		$passageCounter += 1
		passage = SimpleBioC::Passage.new(document)
		passage.infons["num"] = $passageCounter
		passage.offset = 0
		document.passages << passage
		
		# Subject annotation
		subjAnnotation = SimpleBioC::Annotation.new(document)
		subjLocation = SimpleBioC::Location.new(subjAnnotation)
		subjLocation.offset = rand(0..100) # dummy code
		subjLocation.length = rand(0..100) # dummy code
		subjAnnotation.locations << subjLocation
		passage.annotations << subjAnnotation
		walkTerm(obj.subject, 0, subjAnnotation, :subject)
		
		#http://stackoverflow.com/a/252253
		unless obj.relationship.nil?
		
			# Object annotation
			objAnnotation = SimpleBioC::Annotation.new(document)
			objLocation = SimpleBioC::Location.new(objAnnotation)
			objLocation.offset = rand(0..100) # dummy code
			objLocation.length = rand(0..100) # dummy code
			objAnnotation.locations << objLocation
			passage.annotations << objAnnotation
			walkTerm(obj.object, 0, objAnnotation, :object)
			
			# Relation annotation (dummy definition!)
			relation = SimpleBioC::Relation.new(document)
			relation.id = rand(0..1000000)# dummy value
			relation.infons["type"] = String(obj.relationship)
			causeNode = SimpleBioC::Node.new(relation)
			themeNode = SimpleBioC::Node.new(relation)
			triggerNode = SimpleBioC::Node.new(relation)
			relation.nodes << causeNode
			relation.nodes << themeNode
			relation.nodes << triggerNode
			relation.nodes.each do |currentNode|
				currentNode.refid = rand(0..1000)
				currentNode.role = "lorem ipsum dolor sit amet lirum larum loeffelstiel".split(" ")[rand(0..8)]
			# end dummy definition
			
			end
			document.relations << relation
		end
	end
end

# Recursively walk terms and parameter (leaf nodes)
def walkTerm(obj, sublevel, annotation = nil, entity = nil)
	if $toScreen
		tab = "\t"*2*sublevel 
		if obj.instance_of?(BEL::Language::Term)
			puts tab + "\tSublevel: ".yellow + String(sublevel)
			puts tab + "\tFunction: ".yellow + String(obj.fx)
			puts tab + "\t\tShort form: " + String(obj.fx.short_form)
			puts tab + "\t\tLong form: " + String(obj.fx.long_form)
			puts tab + "\t\tReturn type: " + String(obj.fx.return_type)
			puts tab + "\t\tDescription: "  + String(obj.fx.description)
			puts tab + "\t\tSignatures: " + String(obj.fx.signatures)
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
	elsif !obj.nil?
		if obj.instance_of?(BEL::Language::Term)
			annotation.id = obj.hash # dummy value
			annotation.infons["type"] = obj.fx.long_form
			walkTerm(obj.arguments[0], 0, annotation,  entity)
		else 
			annotation.infons["Entrez GeneID"] = nil # dummy value
			annotation.infons[obj.ns] = obj.value
			#location offset?
			annotation.text = obj.value
		end
	end
end
if !$debug
	collection = SimpleBioC::Collection.new()
end

ARGV.each do|infile|
	if !$debug
		document = SimpleBioC::Document.new(collection)
	end
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
		if $debug
			collection = SimpleBioC::Collection.new()
			document = SimpleBioC::Document.new(collection)
		end
		
		walkStatement(obj, document)
			
		collection.documents << document
		
		xml = SimpleBioC.to_xml(collection)
		puts xml
		puts "\n\n"
	end
end
