require 'simple_bioc'
require_relative 'helpers'

module BioC
	module_function
	
	$modifications = [:fus, :pmod, :sub, :trunc]
		
	# Recursively walk terms and parameters (leaf nodes)
	def walkTerm(statement, sublevel, entity = nil, parentFunction = nil, argidx = nil)
		
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
					substitutionString = substitutionString.tr('()','')
				end
				relation.infons["BEL (relative)"] = substitutionString
			end
			
			#
			# Map terms
			#
			if obj.instance_of?(BEL::Language::Term)
				mapTerms(statement, sublevel, parentFunction, argidx)
			
			#
			# Map parameters
			#
			elsif obj.instance_of?(BEL::Language::Parameter)
				mapParameters(statement, parentFunction, argidx)
				
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
	
	def mapTerms(statement, sublevel, parentFunction = nil, argidx = nil)
		# Shorthand assignments
		#
		obj = statement.currentobj
		document = statement.document
		passage = statement.passage
		
		objFunction = obj.fx.short_form
		argidy = 0
		
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
					walkTerm(statement, sublevel + 1, nil, objFunction, argidy)
					node = SimpleBioC::Node.new(relation)
					node.role = "member"
					
					if arg.instance_of?(BEL::Language::Term)
						
						argFunction = arg.fx.short_form
						
						# Treat argument terms of length 1 and having a parameter as annotation, unless modification
						unless arg.arguments.length == 1 and arg.arguments[0].instance_of?(BEL::Language::Parameter) and !$modifications.include? argFunction
							node.refid = "r" + String(prevrelId)
							if objFunction == :p
								case argFunction
									when :fus
										node.role = "fusion"
									when :pmod
										node.role = "proteinModification"
									when :sub
										node.role = "substitution"
									when :trunc
										node.role = "truncation"
								end
							end
						else
							node.refid = "a" + String(prevannotId)
						end
					# Treat argument parameters always as annotation
					elsif arg.instance_of?(BEL::Language::Parameter)
						node.refid = "a" + String(prevannotId)
						case objFunction
						# TODO: Needs to be completed
							when :fus
								case argidy
									when 0
										node.role = "protein"
									when 1
										node.role = "5'PartnerNucleotide"
									when 2
										node.role = "3'PartnerNucleotide"
								end
							when :pmod
								case argidy
									when 0
										node.role = "ModificationType"
									when 1
										node.role = "AminoAcidCode"
									when 2
										node.role = "ModificationPosition"
								end
							when :sub
								case argidy
									when 0
										node.role = "CodeVariant"
									when 1
										node.role = "Codon"
									when 2
										node.role = "CodeReference"
								end
							when :trunc
								case argidy
									when 0
										node.role = "TruncationPosition"
								end
							when :p
								case argidy
									when 0
										node.role = "protein"
								end
						end
						argidy += 1
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
		# (no argument substitution, no recursive walking, treat as relations when term is a modification function)
		else
			unless $modifications.include? objFunction
				annotation = SimpleBioC::Annotation.new(document)
				if statement.placeholders
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
			else
				# TODO: Clean-up (code duplication from above)
				
				# Put in separate function definition
				relation = SimpleBioC::Relation.new(document)
				relation.id = "r" + String($relationId)
				relation.infons["type"] = obj.fx.long_form
				relation.infons["BEL (full)"] = String(obj)
				relation.infons["BEL (relative)"] = String(obj).clone
				passage.relations << relation
				
				increment(:relation)
				
				# Put in separate function definition
				arg = obj.arguments[0]
				prevannotId = $annotationId
				statement.currentobj = arg
				walkTerm(statement, sublevel + 1, nil, objFunction, argidy)
				node = SimpleBioC::Node.new(relation)
				node.role = "self"
				node.refid = "a" + String(prevannotId)
				relation.infons["BEL (relative)"] = relation.infons["BEL (relative)"].sub String(arg), node.refid
				relation.nodes << node
				
				#Put in separate function
				case objFunction
					when :pmod
						case argidy
							when 0
								node.role = "ModificationType"
						end
					when :fus
						case argidy
							when 0
								node.role = "protein"
						end
				end
			end
		end
	end
	def mapParameters(statement, parentFunction = nil, argidx = nil)
		# Shorthand assignments
		#
		obj = statement.currentobj
		document = statement.document
		passage = statement.passage
		
		annotation = SimpleBioC::Annotation.new(document)
		passage.annotations << annotation
		annotation.infons["BEL (full)"] = String(obj)
		
		# Insert placeholder nodes
		#
		if statement.placeholders
			location = SimpleBioC::Location.new(annotation)
			location.offset = nil
			location.length = nil
			annotation.locations << location
			annotation.text = nil
		end
		case parentFunction
			when :fus
				case argidx
					when 0
						annotation.infons["protein"] = String(obj)
					when 1
						annotation.infons["5'PartnerNucleotide"] = String(obj)
					when 2
						annotation.infons["3'PartnerNucleotide"] = String(obj)
				end
			when :pmod
				case argidx
					when 0
						annotation.infons["ModificationType"] = String(obj)
					when 1
						annotation.infons["AminoAcidCode"] = String(obj)
					when 2
						annotation.infons["ModificationPosition"] = String(obj)
				end
			when :sub
				case argidx
					when 0
						annotation.infons["CodeVariant"] = String(obj)
					when 1
						annotation.infons["Codon"] = String(obj)
					when 2
						annotation.infons["CodeReference"] = String(obj)
				end
			when :trunc
				case argidx
					when 0
						annotation.infons["TruncationPosition"] = String(obj)
				end
			else
				annotation.infons[obj.ns] = obj.value
		end
		annotation.id = "a" + String($annotationId)
		increment(:annotation)		
	end
end
