#!/bin/bash

echo "Executing $@ ..."

EXIT_CODE=1
(while [ $EXIT_CODE -gt 0 ]; do
    $@
    # loops on error code: greater-than 0
    EXIT_CODE=$?
		sleep 60
done) &