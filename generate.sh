#!/bin/bash

echo "set295.xml ..."
ruby bel2bioc.rb -b temp_data/set295.bel
echo "set268.xml ..."
ruby bel2bioc.rb -b temp_data/set268.bel
echo "set27.xml ..."
ruby bel2bioc.rb -b temp_data/set27.bel

echo "XML files generated in ../temp_data"

echo "Training.tab ..."
ruby bel2bioc.rb -batmop Task1/Training.tab

echo "XML files generated in ../Task1"
