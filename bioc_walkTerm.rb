require 'simple_bioc'
require_relative 'helpers'

module BioC
	module_function
	
	# Recursively walk terms and parameters (leaf nodes)
	def walkTerm(statement, sublevel, entity = nil)
		
		# Map subject and object when walkTerm is called non-recursively 
		
		if entity == :subject
			element = "cause"
			unless statement.nestedStatement
				statement.currentobj = statement.obj.subject
			else
				statement.currentobj = statement.nestedStatement.subject
			end
		elsif entity == :object
			element = "theme"
			unless statement.nestedStatement
				statement.currentobj = statement.obj.object
			else
				statement.currentobj = statement.nestedStatement.object
			end
		end
		
		# Shorthand assignments
		obj = statement.currentobj
		document = statement.document
		passage = statement.passage
		unless statement.nestedStatement
			relation = statement.relation
			relationTriple = statement.relationTriple
		else
			relation = statement.nestedRelation
			relationTriple = statement.nestedrelationTriple
		end
		
		if !obj.nil?
			if sublevel == 0
					# Statements are relations unless they are unary
					unless !obj.instance_of?(BEL::Language::Statement) and obj.arguments.length == 1 and obj.arguments[0].instance_of?(BEL::Language::Parameter) 
						relationTriple[element].refid = "r" + String($relationId)
					else
						relationTriple[element].refid = "a" + String($annotationId)
					end
				
				# Substitute elements for relative original BEL string
				substitutionString = relation.infons["BEL (relative)"].sub String(obj), relationTriple[element].refid
				if entity == :object
					#strip remaining brackets
					substitutionString = substitutionString.tr(')(','')
				end
				relation.infons["BEL (relative)"] = substitutionString
			end
			
			#
			# Map terms
			#
			if obj.instance_of?(BEL::Language::Term)
				mapTerms(statement, sublevel)
			
			#
			# Map parameters
			#
			elsif obj.instance_of?(BEL::Language::Parameter)
				mapParameters(statement)
				
			#
			# Map statements
			#
			elsif obj.instance_of?(BEL::Language::Statement)
				statement.nestedStatement = obj
				statement.insideNestedStatement = true
				walkStatement(statement)
			end
		end
	end
	
	def mapTerms(statement, sublevel)
		# Shorthand assignments
		#
		obj = statement.currentobj
		document = statement.document
		passage = statement.passage
		
		# Handle n-ary terms and unary terms containing terms or statements, n > 2
		#
		unless obj.arguments.length == 1 and obj.arguments[0].instance_of?(BEL::Language::Parameter)
			relation = SimpleBioC::Relation.new(document)
			relation.id = "r" + String($relationId)
			relation.infons["type"] = obj.fx.long_form
			relation.infons["BEL (full)"] = String(obj)
			relation.infons["BEL (relative)"] = String(obj).clone
			passage.relations << relation
			increment(:relation)
			
			# Handle n-ary terms
			#
			if obj.arguments.length > 1
				obj.arguments.each do |arg|
					prevannotId = $annotationId
					prevrelId = $relationId
					statement.currentobj = arg
					walkTerm(statement, sublevel + 1)
					node = SimpleBioC::Node.new(relation)
					node.role = "member"
					
					if arg.instance_of?(BEL::Language::Term)
						
						# Treat argument terms of length 1 and having a parameter as annotation
						unless arg.arguments.length == 1 and arg.arguments[0].instance_of?(BEL::Language::Parameter)
							node.refid = "r" + String(prevrelId)
						else
							node.refid = "a" + String(prevannotId)
						end
					
					# Treat argument parameters always as annotation
					elsif arg.instance_of?(BEL::Language::Parameter)
						node.refid = "a" + String(prevannotId)
					end
					relation.infons["BEL (relative)"] = relation.infons["BEL (relative)"].sub String(arg), node.refid
					relation.nodes << node
				end

			# Handle unary terms containing terms (treat arguments as annotations)
			#
			else
				arg = obj.arguments[0]
				prevannotId = $annotationId
				statement.currentobj = arg
				walkTerm(statement, sublevel + 1)
				node = SimpleBioC::Node.new(relation)
				node.role = "self"
				node.refid = "a" + String(prevannotId)
				relation.infons["BEL (relative)"] = relation.infons["BEL (relative)"].sub String(arg), node.refid
				relation.nodes << node
			end
		
		# Handle unary terms containing parameters
		# (no argument substitution, no recursive walking)
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
			annotation.infons[obj.arguments[0].ns] = obj.arguments[0].value
			
		end
	end
	
	def mapParameters(statement)
		# Shorthand assignments
		#
		obj = statement.currentobj
		document = statement.document
		passage = statement.passage
		
		annotation = SimpleBioC::Annotation.new(document)
		
		# Insert placeholder nodes
		#
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
		annotation.infons[obj.ns] = obj.value
	end
end
