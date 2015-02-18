require 'simple_bioc'
require_relative 'helpers'

module BioC
	module_function
	# Recursively walk terms and parameters (leaf nodes)
	def walkTerm(obj, sublevel, passage = nil, document = nil, relationTriple = nil, relation = nil, entity = nil, recursiveStatement = false)
		# Output of parsed terms to BioC
		if !obj.nil?
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
end
