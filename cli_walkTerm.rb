require 'colorize'
require 'bel'
require_relative 'helpers'

module Cli
	module_function
	# Recursively walk terms and parameters (leaf nodes)
	def walkTerm(obj, sublevel, passage = nil, document = nil, relationTriple = nil, relation = nil, entity = nil, recursiveStatement = false)
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
			begin
				puts tab + "\tRDF: ".yellow + String(obj.to_rdf).slice(0,$slice)
				puts tab + "\tRDF type: ".yellow + String(obj.rdf_type)
				puts tab + "\tURI: ".yellow + String(obj.to_uri)
			rescue NoMethodError
			end
			puts tab + "\tHash: ".yellow + String(obj.hash)
			puts tab + "\tArguments: ".yellow + String(obj.arguments)
			obj.arguments.each do |subobj|
				if subobj.instance_of?(BEL::Language::Term)
					puts tab + "\t\tTerm Argument:".yellow + String(subobj)
					# Recursive call of walkTerm
					walkTerm(subobj, sublevel + 1)
				else
					puts tab + "\t\tParameter Argument: ".green + String(subobj)
					puts tab + "\t\t\tNS: ".green + String(subobj.ns)
					puts tab + "\t\t\tValue: ".green + String(subobj.value)
					puts tab + "\t\t\tEncoding: ".green + String(subobj.enc)
					puts tab + "\t\t\tSignature: ".green + String(subobj.signature)
					if not subobj.ns.is_a? NilClass
						begin
							puts tab + "\t\t\tRDF: ".green + String(subobj.to_rdf).slice(0,$slice)
							puts tab + "\t\t\tURI: ".green + String(subobj.to_uri)
						rescue NoMethodError
						end
					end
					puts tab + "\t\t\tHash: ".green + String(subobj.hash)
				end
			end
		end
	end
end
