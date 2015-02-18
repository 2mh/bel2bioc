require 'bel'
require 'simple_bioc'
require 'colorize'

$slice = 30
$toScreen = false
$debug = false
$annotationTextLocationOffset = true

$documentId = 1000
$annotationId = 100
$relationId = 100

def counterReset()
	$documentId = 1000
	$annotationId = 100
	$relationId = 100
end

def increment(id)
	case id
	when :document
		$documentId += 1
	when :relation
		$relationId += 1
	when :annotation
		$annotationId += 1
	end
end

# Walk statement tree from the root
def walkStatement(obj, document, passage = nil, recursiveStatement = false)
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
		unless obj.relationship.nil?
			
			# Relationship triple
			relation = SimpleBioC::Relation.new(document)
			relation.id = "r" + String($relationId)
			increment(:relation)
			relation.infons["type"] = String(obj.relationship)
			relation.infons["BEL (full)"] = String(obj)
			relation.infons["BEL (relative)"] = String(obj).clone
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
		walkTerm(obj.subject, 0, passage, document, tripleRelation, relation, :subject, recursiveStatement)
		
		#http://stackoverflow.com/a/252253
		unless obj.relationship.nil?
		
			# Object annotation
			walkTerm(obj.object, 0, passage, document, tripleRelation, relation, :object, recursiveStatement)
			
			# Relation annotation
			annotation = SimpleBioC::Annotation.new(document)
			annotation.id = "a" + String($annotationId)
			tripleRelation["trigger"].refid = annotation.id
			increment(:annotation)
			annotation.infons["trigger"] = obj.relationship
			if $annotationTextLocationOffset
				annotation.text = nil
				location = SimpleBioC::Location.new(annotation)
				location.offset = nil
				location.length = nil
				annotation.locations << location
			end
			passage.annotations << annotation
		end
	end
end

# Recursively walk terms and parameter (leaf nodes)
def walkTerm(obj, sublevel, passage = nil, document = nil, relationTriple = nil, relation = nil, entity = nil, recursiveStatement = false)
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
				element = "cause"
			elsif entity == :object
				element = "theme"
			end
				unless !obj.instance_of?(BEL::Language::Statement) and obj.arguments.length == 1 and obj.arguments[0].instance_of?(BEL::Language::Parameter)
					relationTriple[element].refid = "r" + String($relationId)
				else
					relationTriple[element].refid = "a" + String($annotationId)
				end
			substitutionString = relation.infons["BEL (relative)"].sub String(obj), relationTriple[element].refid
			if entity == :object
				#strip remaining brackets
				substitutionString = substitutionString.tr(')(','')
			end
			relation.infons["BEL (relative)"] = substitutionString
		end
		if obj.instance_of?(BEL::Language::Term)
			unless obj.arguments.length == 1 and obj.arguments[0].instance_of?(BEL::Language::Parameter)
				relation = SimpleBioC::Relation.new(document)
				relation.id = "r" + String($relationId)
				relation.infons["type"] = obj.fx.long_form
				relation.infons["BEL (full)"] = String(obj)
				relation.infons["BEL (relative)"] = String(obj).clone
				document.relations << relation
				increment(:relation)
				# Recursive call
				if obj.arguments.length > 1
					obj.arguments.each do |arg|
						prevannotId = $annotationId
						prevrelId = $relationId
						walkTerm(arg, sublevel + 1, passage, document)
						node = SimpleBioC::Node.new(relation)
						node.role = "member"
						if arg.instance_of?(BEL::Language::Term)
							unless arg.arguments.length == 1 and arg.arguments[0].instance_of?(BEL::Language::Parameter)
								unless recursiveStatement
									node.refid = "r" + String($relationId)
								else
									node.refid = "r" + String(prevrelId)
								end
							else
								node.refid = "a" + String(prevannotId)
							end
						elsif arg.instance_of?(BEL::Language::Parameter)
							node.refid = "a" + String(prevannotId)
						end
						puts arg, node.refid
						relation.infons["BEL (relative)"] = relation.infons["BEL (relative)"].sub String(arg), node.refid
						relation.nodes << node
					end
				else
					arg = obj.arguments[0]
					prevannotId = $annotationId
					walkTerm(arg, sublevel + 1, passage, document)
					node = SimpleBioC::Node.new(relation)
					node.role = "self"
					node.refid = "a" + String(prevannotId)
					relation.infons["BEL (relative)"] = relation.infons["BEL (relative)"].sub String(arg), node.refid
					relation.nodes << node
				end
			else
				annotation = SimpleBioC::Annotation.new(document)
				if $annotationTextLocationOffset
					location = SimpleBioC::Location.new(annotation)
					location.offset = nil
					location.length = nil
					annotation.text = nil
					annotation.locations << location
				end
				passage.annotations << annotation
				annotation.id = "a" + String($annotationId)
				increment(:annotation)
				annotation.infons["BEL (full)"] = String(obj)
				#annotation.infons["Entrez GeneID"] = nil
				annotation.infons[obj.arguments[0].ns] = obj.arguments[0].value
				
			end
		
		elsif obj.instance_of?(BEL::Language::Statement)
			walkStatement(obj, document, passage, recursiveStatement=true)
		else
			annotation = SimpleBioC::Annotation.new(document)
			if $annotationTextLocationOffset
				location = SimpleBioC::Location.new(annotation)
				location.offset = nil
				location.length = nil
				annotation.locations << location
				annotation.text = nil
			end
			passage.annotations << annotation
			annotation.id = "a" + String($annotationId)
			increment(:annotation)
			annotation.infons["BEL (full)"] = String(obj)
			#annotation.infons["Entrez GeneID"] = nil # dummy value
			annotation.infons[obj.ns] = obj.value
			
		end
	end
end
if !$debug
	collection = SimpleBioC::Collection.new()
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
	
	puts "<!--\nBioC from #{statements.length} statements"
	
	statements.each do |obj|
		
		if $debug
			collection = SimpleBioC::Collection.new()
		end
		
		document = SimpleBioC::Document.new(collection)
		passage = SimpleBioC::Passage.new(document)
		passage.offset = nil
		document.passages << passage
		
		document.id = "d" + String($documentId)
		increment(:document)
		walkStatement(obj, document, passage, false)
			
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
	counterReset()
end
