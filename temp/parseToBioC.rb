require 'bel'
require 'simple_bioc'
require 'colorize'

$slice = 30
$toScreen = false

$passageCounter = 100
$annotationId = 100
$relationId = 100

$debug = false


def incrRel()
	$relationId += 1
end

# Walk statement tree from the root
def walkStatement(obj, document)
	if $debug
		puts "[[ #{obj.to_bel} ]]\n".bold
	else
		puts "#{obj.to_bel}\n"
	end

	# Output of parsed nodes to command-line
	if $toScreen
		puts "Subject:".black.on_green.bold + " " + String(obj.subject)
		# Walk subject term
		walkTerm(obj.subject, 0)
		
		puts "Relationship:".black.on_green.bold + " " + String(obj.relationship)
		
		puts "Object:".black.on_green.bold + " " + String(obj.object)
		# Walk object term
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

	# Output of parsed nodes to BioC-XML
	else
		# Instantiate passage
		passage = SimpleBioC::Passage.new(document)
		passage.infons["num"] = $passageCounter
		$passageCounter += 1
		passage.offset = 0
		document.passages << passage
		
		unless obj.relationship.nil?
			
			# Relationship triple
			relation = SimpleBioC::Relation.new(document)
			relation.id = "r" + String($relationId)
			incrRel()
			relation.infons["type"] = String(obj.relationship)
			causeNode = SimpleBioC::Node.new(relation)
			causeNode.role = "cause"
			themeNode = SimpleBioC::Node.new(relation)
			themeNode.role = "theme"
			triggerNode = SimpleBioC::Node.new(relation)
			triggerNode.role = "trigger"
			relation.nodes << causeNode
			relation.nodes << themeNode
			relation.nodes << triggerNode
			document.relations << relation
			tripleRelation = {"cause" => causeNode, "theme" => themeNode, "trigger" => triggerNode}
			
		end
		
		# Subject annotation
		walkTerm(obj.subject, 0, passage, document, tripleRelation, :subject)
		
		#http://stackoverflow.com/a/252253
		unless obj.relationship.nil?
		
			# Object annotation
			walkTerm(obj.object, 0, passage, document, tripleRelation, :object)
			
			# Relation annotation
			annotation = SimpleBioC::Annotation.new(document)
			annotation.id = "a" + String($annotationId)
			tripleRelation["trigger"].refid = annotation.id
			$annotationId += 1
			annotation.infons["trigger"] = obj.relationship
			annotation.text = nil
			location = SimpleBioC::Location.new(annotation)
			location.offset = nil
			location.length = nil
			annotation.locations << location
			passage.annotations << annotation
		end
	end
end

# Recursively walk terms and parameter (leaf nodes)
def walkTerm(obj, sublevel, passage = nil, document = nil, relation = nil, entity = nil)
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
					puts tab + "\t\tTerm Argument:".yellow + String(subobj)
					# Recursive call
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
		if sublevel == 0
			if entity == :subject
				relation["cause"].refid = "r" + String($relationId)
			elsif entity == :object
				relation["theme"].refid = "r" + String($annotationId)
			end
		end
		
		if obj.instance_of?(BEL::Language::Term)
			if !obj.fx.short_form == :proteinAbundance
				relation = SimpleBioC::Relation.new(document)
				relation.id = "r" + String($relationId)
				relation.infons["type"] = obj.fx.long_form
				relation.infons["BEL (full)"] = String(obj)
				relation.infons["BEL (relative)"] = String(obj).clone
				document.relations << relation
				incrRel()
				# Recursive call
				if obj.arguments.length > 1
					obj.arguments.each do |arg|
						walkTerm(arg, sublevel + 1, passage, document)
						node = SimpleBioC::Node.new(relation)
						node.role = "member"
						if arg.instance_of?(BEL::Language::Term)
							node.refid = "r" + String($relationId)
						elsif arg.instance_of?(BEL::Language::Parameter)
							node.refid = "a" + String($annotationId)
						end
						relation.infons["BEL (relative)"] = relation.infons["BEL (relative)"].sub String(arg), node.refid
						relation.nodes << node
					end
				else
					arg = obj.arguments[0]
					walkTerm(arg, sublevel + 1, passage, document)
					node = SimpleBioC::Node.new(relation)
					node.role = "self"
					# Code duplication -> refactoring
					if arg.instance_of?(BEL::Language::Term)
						node.refid = "r" + String($relationId)
					elsif arg.instance_of?(BEL::Language::Parameter)
						node.refid = "a" + String($annotationId)
					end
					relation.infons["BEL (relative)"] = relation.infons["BEL (relative)"].sub String(arg), node.refid
					relation.nodes << node
				end
			else
				puts "foobar"
			end
		else
			annotation = SimpleBioC::Annotation.new(document)
			location = SimpleBioC::Location.new(annotation)
			location.offset = nil
			location.length = nil
			annotation.locations << location
			passage.annotations << annotation
			annotation.id = "a" + String($annotationId)
			$annotationId += 1
			annotation.infons["BEL (full)"] = String(obj)
			annotation.infons["Entrez GeneID"] = nil # dummy value
			annotation.infons[obj.ns] = obj.value
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
		puts "<!--"
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
		
		document.id = "d" + String(rand(10000..1000000))
		walkStatement(obj, document)
			
		collection.documents << document
		
		if $debug
			xml = SimpleBioC.to_xml(collection)
			puts xml
			puts "\n\n"
		end
	end
	if !$debug
		puts "-->"
		xml = SimpleBioC.to_xml(collection)
		puts xml
		puts "\n\n"
	end
end
