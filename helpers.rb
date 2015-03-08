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
	Usage: main.rb -<args> <file>
	Command-line arguments
	
	b: Output to BioC
	c: Output of attributes to CLI (debugging)
	d: Debug mode: Export each statement as separate BioC file.
	p: Insert empty placeholder nodes for 'location'
	t: Treat input file as tabulated (CSV), use BEL Id as document id, sentence as passage text
	a: Only in combination with t: Add sentence Id and PMID as passage infons
	m: Ask user to enter collection meta-data
	o: Include original BEL statements as comment
	EOS
	puts string
	abort
end
