#!/bin/bash

echo "set295.xml ..."
ruby bel2bioc.rb -b ../temp_data/set295.bel > ../temp_data/set295.xml
echo "set268.xml ..."
ruby bel2bioc.rb -b ../temp_data/set268.bel > ../temp_data/set268.xml
echo "set27.xml ..."
ruby bel2bioc.rb -b ../temp_data/set27.bel > ../temp_data/set27.xml

echo "XML files generated in ../temp_data."

