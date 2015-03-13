# bel2bioc
Project for the conversion of OpenBEL files into BioC XML data.

Usage: 
`bel2bioc.rb -<args> <files>`
##Command-line arguments:

**b**: Output to BioC. Provide multiple file names separated by spaces for batch processing. Name of each output file is <file>.xml

**p**: Insert empty placeholder nodes for 'location'

**t**: Treat input file as tabulated (CSV), use BEL Id as document id
sentence as passage text.

**a**: Only in combination with t: Do not include sentence Id and PMID
as passage infons.

**m**: Ask user to enter collection meta-data

**o**: Include original BEL statements as comment

### Debugging

**c**: Output of attributes to CLI (debugging). Output should be piped to
   `more` or `less -R` (due to color coding).
   
**i**: Includes additional nodes with full absolute BEL statement and 
   relative BEL statement with relation and annotation ids
   
**d**: CLI debugging mode: Export each statement as separate BioC collection.
