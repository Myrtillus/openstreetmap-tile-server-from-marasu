#!/bin/bash

echo "Executing $@ ..."

$@
if [ $? -gt 0 ]; then
  kill 1
fi