begin
	require 'simple_bioc'
	rescue LoadError
		puts "Error: BioC mode requires the ruby gem simple_bioc (https://github.com/dongseop/simple_bioc)"
		puts "Use option `c` to inspect the BEL statement."
		abort
end
require_relative 'helpers'
require_relative 'bioc_walkTerm'

# Initialize Id sequences
$documentId = 1000
$annotationId = 100
$relationId = 100

module BioC
	module_function
	# Walk statement tree from the root
	def walkStatement(statement, commentString = nil)
		
		# Shorthand assignments	
		unless statement.nestedStatement
			obj = statement.obj
			commentString << "#{obj.to_bel}\n"
		else
			obj = statement.nestedStatement
		end
		
		document = statement.document
		debug = statement.debug
		includeBEL = statement.includeBEL
	
		# Unless there is no object
		unless obj.relationship.nil?
			# Create relationship triple
			unless statement.nestedStatement
				statement.relation = SimpleBioC::Relation.new(document)
				relation = statement.relation
			else
				statement.nestedRelation = SimpleBioC::Relation.new(document)
				relation = statement.nestedRelation
			end
			relation.id = "r" + String($relationId)
			increment(:relation)
			relation.infons["type"] = String(obj.relationship)
			if includeBEL
				relation.infons["BEL (full)"] = String(obj)
				relation.infons["BEL (relative)"] = String(obj).clone
			end
			causeNode = SimpleBioC::Node.new(relation)
			causeNode.role = "cause"
			themeNode = SimpleBioC::Node.new(relation)
			themeNode.role = "theme"
			relationshipNode = SimpleBioC::Node.new(relation)
			relationshipNode.role = "relationship"
			relation.nodes << causeNode
			relation.nodes << themeNode
			relation.nodes << relationshipNode
			statement.passage.relations << relation
			
			# Hash with references to the triple nodes
			refhash = {"cause" => causeNode, "theme" => themeNode, "relationship" => relationshipNode}
			unless statement.nestedStatement
				statement.relationTriple = refhash
			else
				statement.nestedrelationTriple = refhash
			end
		end
		
		# Subject annotation
		walkTerm(statement, 0, :subject)
		
		# Relationship annotation
		unless obj.relationship.nil?
			# Object annotation
			walkTerm(statement, 0, :object)
			
			# Relation annotation
			annotation = SimpleBioC::Annotation.new(document)
			annotation.id = "a" + String($annotationId)
			statement.relationTriple["relationship"].refid = annotation.id
			unless statement.insideNestedStatement
				statement.relationTriple["relationship"].refid = annotation.id
			else
				statement.nestedrelationTriple["relationship"].refid = annotation.id
			end
			increment(:annotation)
			annotation.infons["relationship"] = obj.relationship
			annotation.infons["type"] = "relationship"
			statement.passage.annotations << annotation
			statement.insideNestedStatement = false
		end
	end
end
