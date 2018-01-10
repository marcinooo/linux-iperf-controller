#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# The script will execute without options, but will not run a blocking shell
source $SCRIPT_DIR/../lic.sh

# Resources
VALID_CONFIGURATION="$SCRIPT_DIR/resources/valid_config.json"
INVALID_CONFIGURATION_ON_MAIN_LEVEL="$SCRIPT_DIR/resources/invalid_config_on_main_level.json"
INVALID_CONFIGURATION_ON_HOST_LEVEL="$SCRIPT_DIR/resources/invalid_config_on_host_level.json"
INVALID_CONFIGURATION_ON_DATA_TRANSFER_CLIENT_AND_SERVER_LEVEL="$SCRIPT_DIR/resources/invalid_config_on_data_transfer_client_and_server_level.json"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

function test_get_host_from_valid_configuration() {
    OUTPUT="$(get_host "server-1" $VALID_CONFIGURATION)"
    EXPECTED_OUTPUT=$'{\n  "ip": "192.168.1.1",\n  "username": "user-1",\n  "password": "password-1"\n}'
    if [[ "$OUTPUT" == $EXPECTED_OUTPUT ]] ; then
        echo -e $GREEN"PASS"$NC
    else
        echo -e $RED"FAIL"$NC
    fi
}

function test_get_missing_host_from_valid_configuration() {
    OUTPUT="$(get_host "XXXXXXX" $VALID_CONFIGURATION)"
    PART_OF_EXPECTED_OUTPUT="ERROR_PARSING_CONFIGURARION_FILE"
    if [[ "$OUTPUT" == *"$PART_OF_EXPECTED_OUTPUT"* ]] ; then
        echo -e $GREEN"PASS"$NC
    else
        echo -e $RED"FAIL"$NC
    fi
}

function test_get_host_from_invalid_configuration() {
    OUTPUT="$(get_host "server-1" $INVALID_CONFIGURATION_ON_MAIN_LEVEL)"
    PART_OF_EXPECTED_OUTPUT="ERROR_PARSING_CONFIGURARION_FILE"
    if [[ "$OUTPUT" == *"$PART_OF_EXPECTED_OUTPUT"* ]] ; then
        echo -e $GREEN"PASS"$NC
    else
        echo -e $RED"FAIL"$NC
    fi
}

function test_get_host_ip_from_valid_configuration() {
    OUTPUT="$(get_host_ip "server-1" $VALID_CONFIGURATION)"
    EXPECTED_OUTPUT=$'192.168.1.1'
    if [[ "$OUTPUT" == $EXPECTED_OUTPUT ]] ; then
        echo -e $GREEN"PASS"$NC
    else
        echo -e $RED"FAIL"$NC
    fi
}

function test_get_host_ip_from_invalid_configuration() {
    OUTPUT="$(get_host_ip "server-1" $INVALID_CONFIGURATION_ON_HOST_LEVEL)"
    PART_OF_EXPECTED_OUTPUT="ERROR_PARSING_CONFIGURARION_FILE"
    if [[ "$OUTPUT" == *"$PART_OF_EXPECTED_OUTPUT"* ]] ; then
        echo -e $GREEN"PASS"$NC
    else
        echo -e $RED"FAIL"$NC
    fi
}

function test_get_host_username_from_valid_configuration() {
    OUTPUT="$(get_host_username "server-1" $VALID_CONFIGURATION)"
    EXPECTED_OUTPUT=$'user-1'
    if [[ "$OUTPUT" == $EXPECTED_OUTPUT ]] ; then
        echo -e $GREEN"PASS"$NC
    else
        echo -e $RED"FAIL"$NC
    fi
}

function test_get_host_username_from_invalid_configuration() {
    OUTPUT="$(get_host_username "server-1" $INVALID_CONFIGURATION_ON_HOST_LEVEL)"
    PART_OF_EXPECTED_OUTPUT="ERROR_PARSING_CONFIGURARION_FILE"
    if [[ "$OUTPUT" == *"$PART_OF_EXPECTED_OUTPUT"* ]] ; then
        echo -e $GREEN"PASS"$NC
    else
        echo -e $RED"FAIL"$NC
    fi
}

function test_get_host_password_from_valid_configuration() {
    OUTPUT="$(get_host_password "server-1" $VALID_CONFIGURATION)"
    EXPECTED_OUTPUT=$'password-1'
    if [[ "$OUTPUT" == $EXPECTED_OUTPUT ]] ; then
        echo -e $GREEN"PASS"$NC
    else
        echo -e $RED"FAIL"$NC
    fi
}

function test_get_host_password_from_invalid_configuration() {
    OUTPUT="$(get_host_ip "server-1" $INVALID_CONFIGURATION_ON_HOST_LEVEL)"
    PART_OF_EXPECTED_OUTPUT="ERROR_PARSING_CONFIGURARION_FILE"
    if [[ "$OUTPUT" == *"$PART_OF_EXPECTED_OUTPUT"* ]] ; then
        echo -e $GREEN"PASS"$NC
    else
        echo -e $RED"FAIL"$NC
    fi
}

function test_get_data_transfer_client_details_from_valid_configuration() {
    OUTPUT="$(get_data_transfer_client_details "ul-udp" $VALID_CONFIGURATION)"
    EXPECTED_OUTPUT=$'{\n  "cmd": "iperf -u -c 127.0.0.1 -b 100M -t 5s -i 1",\n  "host": "server-2"\n}'
    if [[ "$OUTPUT" == $EXPECTED_OUTPUT ]] ; then
        echo -e $GREEN"PASS"$NC
    else
        echo -e $RED"FAIL"$NC
    fi
}

function test_get_missing_data_transfer_client_details_from_valid_configuration() {
    OUTPUT="$(get_data_transfer_client_details "XXXXXXX" $VALID_CONFIGURATION)"
    PART_OF_EXPECTED_OUTPUT="ERROR_MISSING_DATA_TRANSFER_CLIENT_IN_CONFIGURATION"
    if [[ "$OUTPUT" == *"$PART_OF_EXPECTED_OUTPUT"* ]] ; then
        echo -e $GREEN"PASS"$NC
    else
        echo -e $RED"FAIL"$NC
    fi
}

function test_get_data_transfer_client_details_from_invalid_configuration() {
    OUTPUT="$(get_data_transfer_client_details "ul-udp" $INVALID_CONFIGURATION_ON_MAIN_LEVEL)"
    PART_OF_EXPECTED_OUTPUT="ERROR_MISSING_DATA_TRANSFER_CLIENT_IN_CONFIGURATION"
    if [[ "$OUTPUT" == *"$PART_OF_EXPECTED_OUTPUT"* ]] ; then
        echo -e $GREEN"PASS"$NC
    else
        echo -e $RED"FAIL"$NC
    fi
}

function test_get_data_transfer_server_details_from_valid_configuration() {
    OUTPUT="$(get_data_transfer_server_details "ul-udp" $VALID_CONFIGURATION)"
    EXPECTED_OUTPUT=$'{\n  "cmd": "iperf -s -u -i 1",\n  "host": "server-1"\n}'
    if [[ "$OUTPUT" == $EXPECTED_OUTPUT ]] ; then
        echo -e $GREEN"PASS"$NC
    else
        echo -e $RED"FAIL"$NC
    fi
}

function test_get_data_transfer_client_cmd_from_valid_configuration() {
    OUTPUT="$(get_data_transfer_client_cmd "ul-udp" $VALID_CONFIGURATION)"
    EXPECTED_OUTPUT=$'iperf -u -c 127.0.0.1 -b 100M -t 5s -i 1'
    if [[ "$OUTPUT" == $EXPECTED_OUTPUT ]] ; then
        echo -e $GREEN"PASS"$NC
    else
        echo -e $RED"FAIL"$NC
    fi
}

function test_get_data_transfer_client_cmd_from_invalid_configuration() {
    OUTPUT="$(get_data_transfer_client_cmd "ul-udp" $INVALID_CONFIGURATION_ON_DATA_TRANSFER_CLIENT_AND_SERVER_LEVEL)"
    PART_OF_EXPECTED_OUTPUT="ERROR_MISSING_DATA_TRANSFER_CLIENT_CMD_IN_CONFIGURATION"
    if [[ "$OUTPUT" == *"$PART_OF_EXPECTED_OUTPUT"* ]] ; then
        echo -e $GREEN"PASS"$NC
    else
        echo -e $RED"FAIL"$NC
    fi
}

function test_get_data_transfer_client_host_from_valid_configuration() {
    OUTPUT="$(get_data_transfer_client_host "ul-udp" $VALID_CONFIGURATION)"
    EXPECTED_OUTPUT=$'server-2'
    if [[ "$OUTPUT" == $EXPECTED_OUTPUT ]] ; then
        echo -e $GREEN"PASS"$NC
    else
        echo -e $RED"FAIL"$NC
    fi
}

function test_get_data_transfer_client_host_from_invalid_configuration() {
    OUTPUT="$(get_data_transfer_client_host "ul-udp" $INVALID_CONFIGURATION_ON_DATA_TRANSFER_CLIENT_AND_SERVER_LEVEL)"
    PART_OF_EXPECTED_OUTPUT="ERROR_MISSING_DATA_TRANSFER_CLIENT_HOST_IN_CONFIGURATION"
    if [[ "$OUTPUT" == *"$PART_OF_EXPECTED_OUTPUT"* ]] ; then
        echo -e $GREEN"PASS"$NC
    else
        echo -e $RED"FAIL"$NC
    fi
}

function test_get_data_transfer_server_cmd_from_valid_configuration() {
    OUTPUT="$(get_data_transfer_server_cmd "ul-udp" $VALID_CONFIGURATION)"
    EXPECTED_OUTPUT=$'iperf -s -u -i 1'
    if [[ "$OUTPUT" == $EXPECTED_OUTPUT ]] ; then
        echo -e $GREEN"PASS"$NC
    else
        echo -e $RED"FAIL"$NC
    fi
}

function test_get_data_transfer_server_cmd_from_invalid_configuration() {
    OUTPUT="$(get_data_transfer_server_cmd "ul-udp" $INVALID_CONFIGURATION_ON_DATA_TRANSFER_CLIENT_AND_SERVER_LEVEL)"
    PART_OF_EXPECTED_OUTPUT="ERROR_MISSING_DATA_TRANSFER_SERVER_CMD_IN_CONFIGURATION"
    if [[ "$OUTPUT" == *"$PART_OF_EXPECTED_OUTPUT"* ]] ; then
        echo -e $GREEN"PASS"$NC
    else
        echo -e $RED"FAIL"$NC
    fi
}

function test_get_data_transfer_server_host_from_valid_configuration() {
    OUTPUT="$(get_data_transfer_server_host "ul-udp" $VALID_CONFIGURATION)"
    EXPECTED_OUTPUT=$'server-1'
    if [[ "$OUTPUT" == $EXPECTED_OUTPUT ]] ; then
        echo -e $GREEN"PASS"$NC
    else
        echo -e $RED"FAIL"$NC
    fi
}

function test_get_data_transfer_server_host_from_invalid_configuration() {
    OUTPUT="$(get_data_transfer_server_host "ul-udp" $INVALID_CONFIGURATION_ON_DATA_TRANSFER_CLIENT_AND_SERVER_LEVEL)"
    PART_OF_EXPECTED_OUTPUT="ERROR_MISSING_DATA_TRANSFER_SERVER_HOST_IN_CONFIGURATION"
    if [[ "$OUTPUT" == *"$PART_OF_EXPECTED_OUTPUT"* ]] ; then
        echo -e $GREEN"PASS"$NC
    else
        echo -e $RED"FAIL"$NC
    fi
}


echo "Test 'test_get_host_from_valid_configuration':                                   $(test_get_host_from_valid_configuration)"
echo "Test 'test_get_missing_host_from_valid_configuration':                           $(test_get_missing_host_from_valid_configuration)"
echo "Test 'test_get_host_from_invalid_configuration':                                 $(test_get_host_from_invalid_configuration)"
echo "Test 'test_get_host_ip_from_valid_configuration':                                $(test_get_host_ip_from_valid_configuration)"
echo "Test 'test_get_host_ip_from_invalid_configuration':                              $(test_get_host_ip_from_invalid_configuration)"
echo "Test 'test_get_host_username_from_valid_configuration':                          $(test_get_host_username_from_valid_configuration)"
echo "Test 'test_get_host_username_from_invalid_configuration':                        $(test_get_host_username_from_invalid_configuration)"
echo "Test 'test_get_host_password_from_valid_configuration':                          $(test_get_host_password_from_valid_configuration)"
echo "Test 'test_get_host_password_from_invalid_configuration':                        $(test_get_host_password_from_invalid_configuration)"
echo "Test 'test_get_data_transfer_client_details_from_valid_configuration':           $(test_get_data_transfer_client_details_from_valid_configuration)"
echo "Test 'test_get_data_transfer_server_details_from_valid_configuration':           $(test_get_data_transfer_server_details_from_valid_configuration)"
echo "Test 'test_get_missing_data_transfer_client_details_from_valid_configuration':   $(test_get_missing_data_transfer_client_details_from_valid_configuration)"
echo "Test 'test_get_data_transfer_client_details_from_invalid_configuration':         $(test_get_data_transfer_client_details_from_invalid_configuration)"
echo "Test 'test_get_data_transfer_client_cmd_from_valid_configuration':               $(test_get_data_transfer_client_cmd_from_valid_configuration)"
echo "Test 'test_get_data_transfer_client_cmd_from_invalid_configuration':             $(test_get_data_transfer_client_cmd_from_invalid_configuration)"
echo "Test 'test_get_data_transfer_client_host_from_valid_configuration':              $(test_get_data_transfer_client_host_from_valid_configuration)"
echo "Test 'test_get_data_transfer_client_host_from_invalid_configuration':            $(test_get_data_transfer_client_host_from_invalid_configuration)"
echo "Test 'test_get_data_transfer_server_cmd_from_valid_configuration':               $(test_get_data_transfer_server_cmd_from_valid_configuration)"
echo "Test 'test_get_data_transfer_server_cmd_from_invalid_configuration':             $(test_get_data_transfer_server_cmd_from_invalid_configuration)"
echo "Test 'test_get_data_transfer_server_host_from_valid_configuration':              $(test_get_data_transfer_server_host_from_valid_configuration)"
echo "Test 'test_get_data_transfer_server_host_from_invalid_configuration':            $(test_get_data_transfer_server_host_from_invalid_configuration)"


