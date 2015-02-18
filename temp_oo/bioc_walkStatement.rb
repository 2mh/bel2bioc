require 'simple_bioc'
require_relative 'helpers'
require_relative 'bioc_walkTerm'

$annotationTextLocationOffset = true

# Initialize Id sequences
$documentId = 1000
$annotationId = 100
$relationId = 100

module BioC
	module_function
	# Walk statement tree from the root
	def walkStatement(obj, document, passage = nil, recursiveStatement = false, commentString = nil)
		unless commentString.nil?
			commentString << "#{obj.to_bel}\n"
		end
		# Output of parsed nodes to command-line
		# Unless there is no object
		unless obj.relationship.nil?
			# Create relationship triple
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
			# Hash with references to the triple nodes
			tripleRelation = {"cause" => causeNode, "theme" => themeNode, "trigger" => triggerNode}
			
		end
		
		# Subject annotation
		walkTerm(obj.subject, 0, passage, document, tripleRelation, relation, :subject, recursiveStatement)
		
		unless obj.relationship.nil?
		
			# Object annotation
			walkTerm(obj.object, 0, passage, document, tripleRelation, relation, :object, recursiveStatement)
			
			# Relation annotation
			annotation = SimpleBioC::Annotation.new(document)
			annotation.id = "a" + String($annotationId)
			tripleRelation["trigger"].refid = annotation.id
			increment(:annotation)
			annotation.infons["trigger"] = obj.relationship
			
			# Insert placeholder nodes 'text' and 'location'
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
