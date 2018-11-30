#!/bin/bash

#
# Data Quality Report for iotdata
#

## Check

csvstack --skipinitialspace --skip-lines 2 \
--linenumbers --filenames \
IoTNumb3rs-iotdata/marielledemuth/*.csv \
| csvstat -c 1-13

echo $?

csvstack --skipinitialspace --skip-lines 2 \
--linenumbers --filenames \
IoTNumb3rs-iotdata/marielledemuth/*.csv \
| csvcut -c 1,2,3,4,5,6,7,8,9,10,11,12,13 \
| csvsql --db sqlite:///test_db --tables iotdata \
--insert --overwrite
