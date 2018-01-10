#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo
echo "Running test_configuration_manipulation_functions suite:"
echo
$SCRIPT_DIR/test_configuration_manipulation_functions.sh

echo
echo "Running test_management_of_active_iperfs suite:"
echo
$SCRIPT_DIR/test_management_of_active_iperfs.sh
