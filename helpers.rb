# Reset document, annotation, relationship ids
def counterReset()
	$documentId = 1000
	$annotationId = 100
	$relationId = 100
end

# Increment id of given element
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

# Insert linebreak
def breakln(str)
	str << "\n"
end

# Insert empty line
def emptyln(str)
	breakln(str)
	breakln(str)
end

# Put argument error and exit
def argError
	string = <<-EOS
--------------------------------------------------------------------
BEL2BioC converter

Usage: bel2bioc.rb -<args> <files>
--------------------------------------------------------------------
Command-line arguments:
--------------------------------------------------------------------
b: Output to BioC. Provide multiple file names separated by spaces 
   for batch processing. Name of each output file is <file>.xml
--------------------------------------------------------------------
p: Insert empty placeholder nodes for 'location'
t: Treat input file as tabulated (CSV), use BEL Id as document id, 
   sentence as passage text.
a: Only in combination with t: Do not include sentence Id and PMID 
   as passage infons.
m: Ask user to enter collection meta-data
o: Include original BEL statements as comment
--------------------------------------------------------------------
c: Output of attributes to CLI (debugging). Output should be piped to
   `more` or `less -R` (due to color coding).
i: Includes additional nodes with full absolute BEL statement and 
   relative BEL statement with relation and annotation ids
d: CLI debugging mode: Export each statement as separate BioC collection.
--------------------------------------------------------------------
	EOS
	puts string
	abort
end

def createRelation(statement)
	obj = statement.currentobj
	passage = statement.passage
	document = statement.document
	debug = statement.debug
	includeBEL = statement.includeBEL
	
	# Put in separate function definition
	relation = SimpleBioC::Relation.new(document)
	relation.id = "r" + String($relationId)
	relation.infons["type"] = obj.fx.long_form
	if includeBEL
		relation.infons["BEL (full)"] = String(obj)
		relation.infons["BEL (relative)"] = String(obj).clone
	end
	passage.relations << relation
	increment(:relation)
	return relation
end

def unaryTermParameter(statement, relation, annotationId, objFunction, argidy, sublevel)
	obj = statement.currentobj
	debug = statement.debug
	includeBEL = statement.includeBEL
	
	arg = obj.arguments[0]
	prevannotId = annotationId
	statement.currentobj = arg
	walkTerm(statement, sublevel + 1, nil, objFunction, argidy)
	node = SimpleBioC::Node.new(relation)
	node.role = "self"
	node.refid = "a" + String(prevannotId)
	if includeBEL
		relation.infons["BEL (relative)"] = relation.infons["BEL (relative)"].sub String(arg), node.refid
	end
	relation.nodes << node
	return node
end
