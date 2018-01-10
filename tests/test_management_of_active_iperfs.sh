#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# The script will execute without options, but will not run a blocking shell
source $SCRIPT_DIR/../lic.sh

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Mock ACTIVE_IPERFS
ACTIVE_IPERFS=$(mktemp)


function test_add_server_pid_to_active_iperfs() {
    # Test setup
    rm -f $ACTIVE_IPERFS
    # Test
    local OUTPUT="$(add_server_pid_to_active_iperfs "ul-udp" 85644 85619)"
    local FILE_CONTENT=$(cat $ACTIVE_IPERFS)
    local EXPECTED_OUTPUT_1=$'"iperf-pid": "85619",'
    local EXPECTED_OUTPUT_2=$'"window-pid": "85644"'
    if [[ $FILE_CONTENT == *"$EXPECTED_OUTPUT_1"* ]] && [[ $FILE_CONTENT == *"$EXPECTED_OUTPUT_2"* ]] ; then
        echo -e $GREEN"PASS"$NC
    else
        echo -e $RED"FAIL"$NC
    fi
    # Test teardown
    rm -f $ACTIVE_IPERFS
}

function test_add_client_pid_to_active_iperfs() {
    # Test setup
    rm -f $ACTIVE_IPERFS
    echo -e $'[\n  {\n    "dt": "ul-udp",\n    "server": {\n      "iperf-pid": "85619",\n      "window-pid": "85644"\n    }\n  }]' > $ACTIVE_IPERFS
    # Test
    local OUTPUT="$(add_client_pid_to_active_iperfs "ul-udp" 11111 22222)"
    local FILE_CONTENT=$(cat $ACTIVE_IPERFS)
    local EXPECTED_OUTPUT_1=$'"iperf-pid": "22222",'
    local EXPECTED_OUTPUT_2=$'"window-pid": "11111"'
    if [[ $FILE_CONTENT == *"$EXPECTED_OUTPUT_1"* ]] && [[ $FILE_CONTENT == *"$EXPECTED_OUTPUT_2"* ]] ; then
        echo -e $GREEN"PASS"$NC
    else
        echo -e $RED"FAIL"$NC
    fi
    # Test teardown
    rm -f $ACTIVE_IPERFS
}

echo "Test 'add_server_pid_to_active_iperfs':                                          $(test_add_server_pid_to_active_iperfs)"
echo "Test 'add_server_pid_to_active_iperfs':                                          $(test_add_client_pid_to_active_iperfs)"
