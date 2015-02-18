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
