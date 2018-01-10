#!/bin/bash
#
#      __    _____    ___  
#     / /    \_   \  / __\ 
#    / /      / /\/ / /    
#   / /___ /\/ /_  / /___  
#   \____/ \____/  \____/  
# 
#            - Linux Iperf Controller
#
#
# Author: marcinooo
# Overview: Main LIC script. See <url> for details.


# Variables that can be set
PROMPT="(LIC)>"
LOGS_FILE='./lic.log'
ACTIVE_IPERFS='active-iperfs.json'

# Variables that can not be set
DEFAULT_CONFIGURATION=''
HELP_HOSTS_DEFINITION=''
HELP_DATA_TRANSFERS_DEFINITION=''
LOGGER_LOGS_PATH=''
ERROR_MISSING_OPTION_VALUE=1
ERROR_PROGRAM_NOT_INSTALLED=2
ERROR_PARSING_CONFIGURARION_FILE=3
ERROR_SSH_CONNECTION=4
ERROR_MISSING_HOSTS_IN_CONFIGURATION=5
ERROR_MISSING_DATA_TRANSFERS_IN_CONFIGURATION=6
ERROR_MISSING_DATA_TRANSFER_CLIENT_IN_CONFIGURATION=7
ERROR_MISSING_DATA_TRANSFER_SERVER_IN_CONFIGURATION=8
ERROR_MISSING_DATA_TRANSFER_CLIENT_CMD_IN_CONFIGURATION=9
ERROR_MISSING_DATA_TRANSFER_SERVER_CMD_IN_CONFIGURATION=10
ERROR_MISSING_DATA_TRANSFER_CLIENT_HOST_IN_CONFIGURATION=11
ERROR_MISSING_DATA_TRANSFER_SERVER_HOST_IN_CONFIGURATION=12
ERROR_NOT_ALLOWED_OPTION_IN_DATA_TRANSFFR=13

read -r -d '' DEFAULT_CONFIGURATION <<- EOF
{
    "data-transfers": {
        "ul-udp": {
            "client": {
                "cmd": "iperf -u -c 127.0.0.1 -b 100M -t 5s -i 1",
                "host": "hostA"
            },
            "server": {
                "cmd": "iperf -s -u -i 1",
                "host": "hostB"
            }
        }
    },
    "hosts": {
        "hostA": {
            "ip": "<ip>",
            "username": "<username>",
            "password": "<password>"
        },
        "hostB": {
            "ip": "<ip>",
            "username": "<username>",
            "password": "<password>"
        }
    }
}
EOF

read -r -d '' HELP_HOSTS_DEFINITION <<- EOF
Please define "hosts" in configuration file:
{
    ...
    "hosts": {
        "<name of first host>": {
            "ip": "<ip>",
            "username": "<username>",
            "password": "<password>"
        },
        "<name of second host>": ...
    }
    ...
}
EOF

read -r -d '' HELP_DATA_TRANSFERS_DEFINITION <<- EOF
Please define "hosts" in configuration file:
{
    ...
    "data-transfers": {
        "<name of first data transfer>": {
			"client": {
				"cmd": "<iperf client command>",
				"host": "<name of host to execute iperf command>"
			},
			"server": {
                "cmd": "<iperf server command>",
                "host": "<name of host to execute iperf command>"
            }
		},
        "<name of first data transfer>": ...
    }
    ...
}
EOF


#######################################
# Sets logging destination file.
# Globals:
#   LOGGER_LOGS_PATH
# Arguments:
#   Path to file where logs will be stored. 
# Outputs:
#   None
#######################################
function initialize_logger() {
    local LOG_FILE=$1
    LOGGER_LOGS_PATH=$LOG_FILE
}

#######################################
# Dumps passed message to log file with DEBUG level.
# Globals:
#   LOGGER_LOGS_PATH
# Arguments:
#   Log message to dump. 
# Outputs:
#   None
#######################################
function log_debug() {
    local MSG=$1
    local DATETIME=$(date +"%Y-%m-%d %H:%M:%S")
	local CONTEXT=$(caller)
    echo -e "[$DATETIME][DEBUG] $MSG ($CONTEXT)" >> $LOGGER_LOGS_PATH
}

#######################################
# Dumps passed message to log file with INFO level.
# Globals:
#   LOGGER_LOGS_PATH
# Arguments:
#   Log message to dump. 
# Outputs:
#   None
#######################################
function log_info() {
    local MSG=$1
    local DATETIME=$(date +"%Y-%m-%d %H:%M:%S")
	local CONTEXT=$(caller)
    echo -e "[$DATETIME][INFO ] $MSG ($CONTEXT)" >> $LOGGER_LOGS_PATH
}

#######################################
# Dumps passed message to log file with WARN level.
# Globals:
#   LOGGER_LOGS_PATH
# Arguments:
#   Log message to dump. 
# Outputs:
#   None
#######################################
function log_warn() {
    local MSG=$1
    local DATETIME=$(date +"%Y-%m-%d %H:%M:%S")
	local CONTEXT=$(caller)
    echo -e "[$DATETIME][WARN ] $MSG ($CONTEXT)" >> $LOGGER_LOGS_PATH
}

#######################################
# Dumps passed message to log file with ERROR level.
# Globals:
#   LOGGER_LOGS_PATH
# Arguments:
#   Log message to dump. 
# Outputs:
#   None
#######################################
function log_error() {
    local MSG=$1
    local DATETIME=$(date +"%Y-%m-%d %H:%M:%S")
	local CONTEXT=$(caller)
    echo -e "[$DATETIME][ERROR] $MSG ($CONTEXT)" >> $LOGGER_LOGS_PATH
}

#######################################
# Gets host object by name from given configuration file.
# If host doesn't exist LIC will be exited with non zero status.
# Globals:
#   ERROR_PARSING_CONFIGURARION_FILE
# Arguments:
#   Name of host.
#   Path to configuration file. 
# Outputs:
#   Found host object.
#######################################
function get_host() {
    local HOST=$1
    local CONFIGURATION=$2
    local HOST_DETAILS=$(jq -r ".\"hosts\".\"$HOST\"" $CONFIGURATION)
	if [[ $? -ne 0 || $HOST_DETAILS == "null" ]] ; then
		local MSG="Error ERROR_PARSING_CONFIGURARION_FILE ($ERROR_PARSING_CONFIGURARION_FILE): No $HOST definition in $CONFIGURATION file."
        log_error "$MSG"
        echo $MSG
        exit $ERROR_PARSING_CONFIGURARION_FILE
	fi
    echo "$HOST_DETAILS"
}

#######################################
# Gets host's ip from given configuration file.
# If host doesn't exist or it doesn't contain ip LIC will be exited with non zero status.
# Globals:
#   ERROR_PARSING_CONFIGURARION_FILE
# Arguments:
#   Name of host.
#   Path to configuration file. 
# Outputs:
#   Found ip address of host.
#######################################
function get_host_ip() {
    local HOST=$1
    local CONFIGURATION=$2
    local HOST_DETAILS=$(get_host $HOST $CONFIGURATION)
    local HOST_IP=$(echo $HOST_DETAILS | jq -r ".\"ip\"")
    if [[ $? -ne 0 || $HOST_IP == "null" ]] ; then
		local MSG="Error ERROR_PARSING_CONFIGURARION_FILE ($ERROR_PARSING_CONFIGURARION_FILE): No IP of $HOST in $CONFIGURATION file."
        log_error "$MSG"
        echo $MSG
        exit $ERROR_PARSING_CONFIGURARION_FILE
	fi
    echo "$HOST_IP"
} 

#######################################
# Gets host's username from given configuration file.
# If host doesn't exist or it doesn't contain username LIC will be exited with non zero status.
# Globals:
#   ERROR_PARSING_CONFIGURARION_FILE
# Arguments:
#   Name of host.
#   Path to configuration file. 
# Outputs:
#   Found username for given host.
#######################################
function get_host_username() {
    local HOST=$1
    local CONFIGURATION=$2
    local HOST_DETAILS=$(get_host $HOST $CONFIGURATION)
    local HOST_USERNAME=$(echo $HOST_DETAILS | jq -r ".\"username\"")
    if [[ $? -ne 0 || $HOST_USERNAME == "null" ]] ; then
		local MSG="Error ERROR_PARSING_CONFIGURARION_FILE ($ERROR_PARSING_CONFIGURARION_FILE): Definition of $HOST should contain \"username\" key in $CONFIGURATION file."
        log_error "$MSG"
        echo $MSG
        exit $ERROR_PARSING_CONFIGURARION_FILE
	fi
    echo "$HOST_USERNAME"
}

#######################################
# Gets host's password from given configuration file.
# If host doesn't exist or it doesn't contain password LIC will be exited with non zero status.
# Globals:
#   ERROR_PARSING_CONFIGURARION_FILE
# Arguments:
#   Name of host.
#   Path to configuration file. 
# Outputs:
#   Found password for given host.
#######################################
function get_host_password() {
    local HOST=$1
    local CONFIGURATION=$2
    local HOST_DETAILS=$(get_host $HOST $CONFIGURATION)
    local HOST_PASSWORD=$(echo $HOST_DETAILS | jq -r ".\"password\"")
    if [[ $? -ne 0 || $HOST_PASSWORD == "null" ]] ; then
		local MSG="Error ERROR_PARSING_CONFIGURARION_FILE ($ERROR_PARSING_CONFIGURARION_FILE): Definition of $HOST should contain \"password\" key in $CONFIGURATION file."
        log_error "$MSG"
        echo $MSG
        exit $ERROR_PARSING_CONFIGURARION_FILE
	fi
    echo "$HOST_PASSWORD"
}

#######################################
# Checks ssh connection to given host.
# If connection doesn't work LIC will be exited with non zero status.
# Globals:
#   ERROR_SSH_CONNECTION
# Arguments:
#   Name of host.
#   Ip address of host.
#   Username of host.
#   Password of host. 
# Outputs:
#   None
#######################################
function check_ssh_connection() {
    local HOST=$1
    local IP=$2
    local USERNAME=$3
    local PASSWORD=$4
    log_info "Checking connection to \"$HOST\" host ($IP / $USERNAME / $PASSWORD)."
    local STATUS=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -l $USERNAME $IP "pwd")
    if [[ ${STATUS##*/} != $USERNAME ]] ; then
        local MSG="Error ERROR_SSH_CONNECTION ($ERROR_SSH_CONNECTION): Connection to \"$HOST\" host doesn't work."
        log_error "$MSG"
        echo $MSG
        exit $ERROR_SSH_CONNECTION
    fi
    log_info "Connection to \"$HOST\" host works fine."
}

#######################################
# Checks if jq command is installed.
# If it isn't installed LIC will be exited with non zero status.
# Globals:
#   ERROR_PROGRAM_NOT_INSTALLED
# Arguments:
#   None
# Outputs:
#   "OK" if jq is installed otherwise LIC will be exited.
#######################################
function check_jq() {
    local STATUS=$(jq --version)
    if [[ ${STATUS:0:2} != "jq" ]] ; then
        local MSG="Error ERROR_PROGRAM_NOT_INSTALLED ($ERROR_PROGRAM_NOT_INSTALLED): jq is not installed. Please install it with command: apt install jq && jq --version"
        log_error "$MSG"
        echo $MSG
        exit $ERROR_PROGRAM_NOT_INSTALLED
    else
        echo "OK"
    fi
}

#######################################
# Checks if xterm command is installed.
# If it isn't installed LIC will be exited with non zero status.
# Globals:
#   ERROR_PROGRAM_NOT_INSTALLED
# Arguments:
#   None
# Outputs:
#   "OK" if xterm is installed otherwise LIC will be exited.
#######################################
function check_xterm() {
    local STATUS=$(xterm -version)
    if [[ ${STATUS:0:5} != "XTerm" ]] ; then
        local MSG="Error ERROR_PROGRAM_NOT_INSTALLED ($ERROR_PROGRAM_NOT_INSTALLED): xterm is not installed. Please install it with command: apt install xterm && xterm -version"
        log_error "$MSG"
        echo $MSG
        exit $ERROR_PROGRAM_NOT_INSTALLED
    else
        echo "OK"
    fi
}

#######################################
# Validate configuration.
# LIC will be exited with non zero status if configuration is not valid.
# Globals:
#   ERROR_MISSING_HOSTS_IN_CONFIGURATION
#   HELP_HOSTS_DEFINITION
#   ERROR_MISSING_DATA_TRANSERFS_IN_CONFIGURATION
#   HELP_DATA_TRANSFERS_DEFINITION
#   ERROR_NOT_ALLOWED_OPTION_IN_DATA_TRANSFER
#   ACTIVE_IPERFS
# Arguments:
#   Path to configuration file.
# Outputs:
#   "OK" if configuration is valid.
#######################################
function check_configuration() {
    local CONFIGURATION=$1
    local HOSTS_DEFINITION=$(jq -r ".\"hosts\"" $CONFIGURATION)
    if [[ $? -ne 0 || $HOSTS_DEFINITION = "{}" ]] ; then
        local MSG="Error ERROR_MISSING_HOSTS_IN_CONFIGURATION ($ERROR_MISSING_HOSTS_IN_CONFIGURATION): No \"hosts\" section in $CONFIGURATION file."
        log_error "$MSG"
        echo
        echo $MSG
        echo -e "$HELP_HOSTS_DEFINITION"
        exit $ERROR_MISSING_HOSTS_IN_CONFIGURATION
    fi
    local HOSTS=$(jq -r ".\"hosts\" | keys[]" $CONFIGURATION)
    for HOST in $HOSTS ; do
        local IP=$(get_host_ip $HOST $CONFIGURATION)
        local USERNAME=$(get_host_username $HOST $CONFIGURATION)
        local PASSWORD=$(get_host_password $HOST $CONFIGURATION)
        check_ssh_connection $HOST $IP $USERNAME $PASSWORD
    done
    local DATA_TRANSFERS=$(jq -r ".\"data-transfers\"" $CONFIGURATION)
    if [[ $? -ne 0 || $HOSTS = "{}" ]] ; then 
        local MSG="Error ERROR_MISSING_DATA_TRANSERFS_IN_CONFIGURATION ($ERROR_MISSING_DATA_TRANSERFS_IN_CONFIGURATION): No \"data-transfers\" section in $CONFIGURATION file."
        log_error "$MSG"
        echo
        echo $MSG
        echo -e "$HELP_DATA_TRANSFERS_DEFINITION"
        exit $ERROR_MISSING_DATA_TRANSERFS_IN_CONFIGURATION
    fi
    local DATA_TRANSFERS=$(jq -r ".\"data-transfers\" | keys[]" $CONFIGURATION)
    for DT_NAME in $DATA_TRANSFERS ; do
        local CLIENT_CMD=$(get_data_transfer_client_cmd $DT_NAME $CONFIGURATION)
        local SERVER_CMD=$(get_data_transfer_server_cmd $DT_NAME $CONFIGURATION)
        if [[ $CLIENT_CMD == *"-p"* || $SERVER_CMD == *"-p"* ]] ; then
            local MSG="Error ERROR_NOT_ALLOWED_OPTION_IN_DATA_TRANSFER ($ERROR_NOT_ALLOWED_OPTION_IN_DATA_TRANSFER): Parameter \"-p\" is not allowed in iperf command for \"$DT_NAME\" data transfer. Port is selected by LIC."
            log_error "$MSG"
            echo $MSG
            exit $ERROR_NOT_ALLOWED_OPTION_IN_DATA_TRANSFER
        fi
    done
    if [ ! -f $ACTIVE_IPERFS ]; then
        echo "[]" > $ACTIVE_IPERFS
        log_info "New file for active data transfers was created."
    fi
    echo "OK"
}

#######################################
# Generate new raw configuration file.
# Globals:
#   DEFAULT_CONFIGURATION
# Arguments:
#   Path to configuration file.
# Outputs:
#   "OK" if configuration is valid.
#######################################
function generate_configuration() {
    local CONFIGURATION=$1
    if [[ -f $CONFIGURATION ]] ; then
        echo -n "File $CONFIGURATION already exists. Do you want to overwrite it? [y/n]: "
        while read CONFIRMED ; do
            case $CONFIRMED in 
                y|yes)
                    log_info "Generating $CONFIGURATION configuration."
                    echo "$DEFAULT_CONFIGURATION" > $CONFIGURATION
                    echo "Configuration was saved in $CONFIGURATION"
                    break
                    ;;
                n|no)
                    break
                    ;;
                *)
                    echo -n "Type n|no|y|yes: "
                    ;;
            esac
        done
    else
        log_info "Generating $CONFIGURATION configuration."
        echo "$DEFAULT_CONFIGURATION" > $CONFIGURATION
        echo "Configuration was saved in $CONFIGURATION"
    fi
}

#######################################
# Gets client data for given data transfer from configuration file.
# If client section doesn't exist LIC will be exited with non zero status.
# Globals:
#   HELP_DATA_TRANSFERS_DEFINITION
#   ERROR_MISSING_DATA_TRANSFER_CLIENT_IN_CONFIGURATION
# Arguments:
#   Name of data transfer.
#   Path to configuration file.
# Outputs:
#   Cient data for data transfer.
#######################################
function get_data_transfer_client_details() {
    local DT_NAME=$1
    local CONFIGURATION=$2
    local CLIENT_DETAILS=$(jq -r ".\"data-transfers\".\"$DT_NAME\".\"client\"" $CONFIGURATION)
    if [[ $? -ne 0 || $CLIENT_DETAILS == "null" ]] ; then
		local MSG="Error ERROR_MISSING_DATA_TRANSFER_CLIENT_IN_CONFIGURATION ($ERROR_MISSING_DATA_TRANSFER_CLIENT_IN_CONFIGURATION): No \"client\" details for \"$DT_NAME\" data transfer in $CONFIGURATION file."
        log_error "$MSG"
        echo $MSG
        echo -e "$HELP_DATA_TRANSFERS_DEFINITION"
        exit $ERROR_MISSING_DATA_TRANSFER_CLIENT_IN_CONFIGURATION
	fi
    echo "$CLIENT_DETAILS"
}

#######################################
# Gets client iperf command for given data transfer from configuration file.
# If command doesn't exist LIC will be exited with non zero status.
# Globals:
#   HELP_DATA_TRANSFERS_DEFINITION
#   ERROR_MISSING_DATA_TRANSFER_CLIENT_CMD_IN_CONFIGURATION
# Arguments:
#   Name of data transfer.
#   Path to configuration file.
# Outputs:
#   Client iperf command for data transfer.
#######################################
function get_data_transfer_client_cmd() {
    local DT_NAME=$1
    local CONFIGURATION=$2
    local CLIENT_DETAILS=$(get_data_transfer_client_details $DT_NAME $CONFIGURATION)
    local CLIENT_CMD=$(echo $CLIENT_DETAILS | jq -r ".\"cmd\"")
    if [[ $? -ne 0 || $CLIENT_CMD == "null" ]] ; then
        local MSG="Error ERROR_MISSING_DATA_TRANSFER_CLIENT_CMD_IN_CONFIGURATION ($ERROR_MISSING_DATA_TRANSFER_CLIENT_CMD_IN_CONFIGURATION): No \"cmd\" field for \"$DT_NAME\" data transfer in $CONFIGURATION file."
        log_error "$MSG"
        echo $MSG
        echo -e "$HELP_DATA_TRANSFERS_DEFINITION"
        exit $ERROR_MISSING_DATA_TRANSFER_CLIENT_CMD_IN_CONFIGURATION
    fi
    echo "$CLIENT_CMD"
}

#######################################
# Gets client host for given data transfer from configuration file.
# If host doesn't exist LIC will be exited with non zero status.
# Globals:
#   HELP_DATA_TRANSFERS_DEFINITION
#   ERROR_MISSING_DATA_TRANSFER_CLIENT_HOST_IN_CONFIGURATION
# Arguments:
#   Name of data transfer.
#   Path to configuration file.
# Outputs:
#   Client host for data transfer.
#######################################
function get_data_transfer_client_host() {
    local DT_NAME=$1
    local CONFIGURATION=$2
    local CLIENT_DETAILS=$(get_data_transfer_client_details $DT_NAME $CONFIGURATION)
    local CLIENT_HOST=$(echo $CLIENT_DETAILS | jq -r ".\"host\"")
    if [[ $? -ne 0 || $CLIENT_HOST == "null" ]] ; then
        local MSG="Error ERROR_MISSING_DATA_TRANSFER_CLIENT_HOST_IN_CONFIGURATION ($ERROR_MISSING_DATA_TRANSFER_CLIENT_HOST_IN_CONFIGURATION): No \"host\" field for \"$DT_NAME\" data transfer in $CONFIGURATION file."
        log_error "$MSG"
        echo $MSG
        echo -e "$HELP_DATA_TRANSFERS_DEFINITION"
        exit $ERROR_MISSING_DATA_TRANSFER_CLIENT_HOST_IN_CONFIGURATION
    fi
    echo "$CLIENT_HOST"
}

#######################################
# Gets server data for given data transfer from configuration file.
# If server section doesn't exist LIC will be exited with non zero status.
# Globals:
#   HELP_DATA_TRANSFERS_DEFINITION
#   ERROR_MISSING_DATA_TRANSFER_SERVER_IN_CONFIGURATION
# Arguments:
#   Name of data transfer.
#   Path to configuration file.
# Outputs:
#   Server data for data transfer.
#######################################
function get_data_transfer_server_details() {
    local DT_NAME=$1
    local CONFIGURATION=$2
    local SERVER_DETAILS=$(jq -r ".\"data-transfers\".\"$DT_NAME\".\"server\"" $CONFIGURATION)
    if [[ $? -ne 0 || $SERVER_DETAILS == "null" ]] ; then
		local MSG="Error ERROR_MISSING_DATA_TRANSFER_SERVER_IN_CONFIGURATION ($ERROR_MISSING_DATA_TRANSFER_SERVER_IN_CONFIGURATION): No \"server\" section for \"$DT_NAME\" data transfer in $CONFIGURATION file."
        log_error "$MSG"
        echo $MSG
        echo -e "$HELP_DATA_TRANSFERS_DEFINITION"
        exit $ERROR_MISSING_DATA_TRANSFER_SERVER_IN_CONFIGURATION
	fi
    echo "$SERVER_DETAILS"
}

#######################################
# Gets server iperf command for given data transfer from configuration file.
# If command doesn't exist LIC will be exited with non zero status.
# Globals:
#   HELP_DATA_TRANSFERS_DEFINITION
#   ERROR_MISSING_DATA_TRANSFER_SERVER_CMD_IN_CONFIGURATION
# Arguments:
#   Name of data transfer.
#   Path to configuration file.
# Outputs:
#   Server iperf command for data transfer.
#######################################
function get_data_transfer_server_cmd() {
    local DT_NAME=$1
    local CONFIGURATION=$2
    local SERVER_DETAILS=$(get_data_transfer_server_details $DT_NAME $CONFIGURATION)
    local SERVER_CMD=$(echo $SERVER_DETAILS | jq -r ".\"cmd\"")
    if [[ $? -ne 0 || $SERVER_CMD == "null" ]] ; then
        local MSG="Error ERROR_MISSING_DATA_TRANSFER_SERVER_CMD_IN_CONFIGURATION ($ERROR_MISSING_DATA_TRANSFER_SERVER_CMD_IN_CONFIGURATION): No \"cmd\" field for \"$DT_NAME\" data transfer in $CONFIGURATION file."
        log_error "$MSG"
        echo $MSG
        echo -e "$HELP_DATA_TRANSFERS_DEFINITION"
        exit $ERROR_MISSING_DATA_TRANSFER_SERVER_CMD_IN_CONFIGURATION
    fi
    echo "$SERVER_CMD"
}

#######################################
# Gets server host for given data transfer from configuration file.
# If host doesn't exist LIC will be exited with non zero status.
# Globals:
#   HELP_DATA_TRANSFERS_DEFINITION
#   ERROR_MISSING_DATA_TRANSFER_SERVER_HOST_IN_CONFIGURATION
# Arguments:
#   Name of data transfer.
#   Path to configuration file.
# Outputs:
#   Server host for data transfer.
#######################################
function get_data_transfer_server_host() {
    local DT_NAME=$1
    local CONFIGURATION=$2
    local SERVER_DETAILS=$(get_data_transfer_server_details $DT_NAME $CONFIGURATION)
    local SERVER_HOST=$(echo $SERVER_DETAILS | jq -r ".\"host\"")
    if [[ $? -ne 0 || $SERVER_HOST == "null" ]] ; then
        local MSG="Error ERROR_MISSING_DATA_TRANSFER_SERVER_HOST_IN_CONFIGURATION ($ERROR_MISSING_DATA_TRANSFER_SERVER_HOST_IN_CONFIGURATION): No \"host\" field for \"$DT_NAME\" data transfer in $CONFIGURATION file."
        log_error "$MSG"
        echo $MSG
        echo -e "$HELP_DATA_TRANSFERS_DEFINITION"
        exit $ERROR_MISSING_DATA_TRANSFER_SERVER_HOST_IN_CONFIGURATION
    fi
    echo "$SERVER_HOST"
}

#######################################
# Finds unbind port for server iperf.
# Globals:
#   None
# Arguments:
#   Name of data transfer.
#   Path to configuration file.
# Outputs:
#   Unbind port.
#######################################
function get_unbind_port() {
    local DT_NAME=$1
    local CONFIGURATION=$2
    local SERVER_HOST=$(get_data_transfer_server_host $DT_NAME $CONFIGURATION)
    local IP=$(get_host_ip $SERVER_HOST $CONFIGURATION)
    local USERNAME=$(get_host_username $SERVER_HOST $CONFIGURATION)
    local PASSWORD=$(get_host_password $SERVER_HOST $CONFIGURATION)
    local MIN=5000
    local MAX=50000
    local PORT=""
    for N in $(seq 1 100) ; do
        PORT=$(echo $(($MIN + $RANDOM % $MAX)))
        local OUTPUT=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -l $USERNAME $IP  "lsof -i:$PORT")
        if [[ "$OUTPUT" = "" ]] ; then 
            break
        fi
    done
    echo "$PORT"
}

#######################################
# Dumps pid of active server iperf to file with active data transfers.
# Globals:
#   ACTIVE_IPERFS
# Arguments:
#   Name of data transfer.
#   PID of xterm window.
#   PID of iperf.
# Outputs:
#   None
#######################################
function add_server_pid_to_active_iperfs() {
    local DT_NAME=$1
    local XTERM_PID=$2
    local IPERF_PID=$3
    local TEMPFILE=$(mktemp)
    if [[ ! -f $ACTIVE_IPERFS ]] ; then
        echo "[]" > $ACTIVE_IPERFS
    fi
    cp $ACTIVE_IPERFS "$TEMPFILE"
    local DT=$(jq ". += [{\"dt\": \"$DT_NAME\", \"server\": {\"iperf-pid\": \"$IPERF_PID\", \"window-pid\": \"$XTERM_PID\"}}]" $TEMPFILE > $ACTIVE_IPERFS)
    rm -f "$TEMPFILE"
}

#######################################
# Dumps pid of active client iperf to file with active data transfers.
# Globals:
#   ACTIVE_IPERFS
# Arguments:
#   Name of data transfer.
#   PID of xterm window.
#   PID of iperf.
# Outputs:
#   None
#######################################
function add_client_pid_to_active_iperfs() {
    local DT_NAME=$1
    local XTERM_PID=$2
    local IPERF_PID=$3
    local TEMPFILE=$(mktemp)
    cp $ACTIVE_IPERFS "$TEMPFILE"
    local DT=$(jq "[.[] | select(.dt == \"$DT_NAME\") += {\"client\": {\"iperf-pid\": \"$IPERF_PID\", \"window-pid\": \"$XTERM_PID\"}}]" $TEMPFILE > $ACTIVE_IPERFS)
    rm -f "$TEMPFILE"
}

#######################################
# Starts client iperf for given data transfers.
# Globals:
#   None
# Arguments:
#   Name of data transfer.
#   Server iperf port.
#   Path to configuration file.
# Outputs:
#   None
#######################################
function start_client_iperf() {
    local DT_NAME=$1
    local PORT=$2
    local CONFIGURATION=$3
    local CLIENT_CMD=$(get_data_transfer_client_cmd $DT_NAME $CONFIGURATION)
    local CLIENT_HOST=$(get_data_transfer_client_host $DT_NAME $CONFIGURATION)
    local IP=$(get_host_ip $CLIENT_HOST $CONFIGURATION)
    local USERNAME=$(get_host_username $CLIENT_HOST $CONFIGURATION)
    local PASSWORD=$(get_host_password $CLIENT_HOST $CONFIGURATION)
    CLIENT_CMD="$CLIENT_CMD -p $PORT"
    local TITLE="Data transfer: $DT_NAME\nHost: $CLIENT_HOST ($IP)\nCommand: $CLIENT_CMD\n\n"
    exec xterm -fa DejaVuSansMono -hold -e "echo -e \"$TITLE\"; sshpass -p \"$PASSWORD\" ssh -o StrictHostKeyChecking=no -l $USERNAME $IP \"$CLIENT_CMD\"" &
    local XTERM_PID=$!
    sleep 1
    local CLIENT_CMD_PS=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -l $USERNAME $IP "ps -ef | grep -v -e ssh -e grep |  grep \"$CLIENT_CMD\"")
    local CLIENT_CMD_PIDS=$(echo "$CLIENT_CMD_PS" | tr -s ' ' | cut -d ' ' -f 2)
    local IPERF_PID=${CLIENT_CMD_PIDS##*$'\n'}
    add_client_pid_to_active_iperfs $DT_NAME $XTERM_PID $IPERF_PID
}

#######################################
# Starts server iperf for given data transfers.
# Globals:
#   None
# Arguments:
#   Name of data transfer.
#   Server iperf port.
#   Path to configuration file.
# Outputs:
#   None
#######################################
function start_server_iperf() {
    local DT_NAME=$1
    local PORT=$2
    local CONFIGURATION=$3
    local SERVER_HOST=$(get_data_transfer_server_host $DT_NAME $CONFIGURATION)
    local IP=$(get_host_ip $SERVER_HOST $CONFIGURATION)
    local USERNAME=$(get_host_username $SERVER_HOST $CONFIGURATION)
    local PASSWORD=$(get_host_password $SERVER_HOST $CONFIGURATION)
    local SERVER_CMD=$(get_data_transfer_server_cmd $DT_NAME $CONFIGURATION)
    SERVER_CMD="$SERVER_CMD -p $PORT"
    local TITLE="Data transfer: $DT_NAME\nHost: $SERVER_HOST ($IP)\nCommand: $SERVER_CMD\n\n"
    exec xterm -fa DejaVuSansMono -hold -e "echo -e \"$TITLE\"; sshpass -p \"$PASSWORD\" ssh -o StrictHostKeyChecking=no -l $USERNAME $IP \"$SERVER_CMD\"" &
    local XTERM_PID=$!
    sleep 1
    local SERVER_CMD_PS=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -l $USERNAME $IP "ps -ef | grep -v -e ssh -e grep |  grep \"$SERVER_CMD\"")
    local SERVER_CMD_PIDS=$(echo "$SERVER_CMD_PS" | tr -s ' ' | cut -d ' ' -f 2)
    local IPERF_PID=${SERVER_CMD_PIDS##*$'\n'}
    add_server_pid_to_active_iperfs $DT_NAME $XTERM_PID $IPERF_PID
}

#######################################
# Starts given data transfers.
# Globals:
#   None
# Arguments:
#   Data transfer to start.
#   Path to configuration file.
# Outputs:
#   None
#######################################
function start_data_transfer() {
    local DT_NAME=$1
    local CONFIGURATION=$2
    local PORT=$(get_unbind_port $DT_NAME $CONFIGURATION)
    start_server_iperf $DT_NAME $PORT $CONFIGURATION
    start_client_iperf $DT_NAME $PORT $CONFIGURATION
}

#######################################
# Stops server iperf for given data transfers.
# Globals:
#   None
# Arguments:
#   Data transfer to stop.
#   Path to configuration file.
# Outputs:
#   None
#######################################
function stop_server_iperf() {
    local DT_NAME=$1
    local CONFIGURATION=$2
    local IPERF_PID=$(jq -r ".[] | select(.dt == \"$DT_NAME\") | .\"server\".\"iperf-pid\"" $ACTIVE_IPERFS)
    local SERVER_HOST=$(get_data_transfer_server_host $DT_NAME $CONFIGURATION)
    local IP=$(get_host_ip $SERVER_HOST $CONFIGURATION)
    local USERNAME=$(get_host_username $SERVER_HOST $CONFIGURATION)
    local PASSWORD=$(get_host_password $SERVER_HOST $CONFIGURATION)
    local IPERF_KILL_STATUS=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -l $USERNAME $IP "kill $IPERF_PID 2>&1; wait \$!")
    log_info "Output from killing of server window: \n$IPERF_KILL_STATUS"
}

#######################################
# Stops client iperf for given data transfers.
# Globals:
#   None
# Arguments:
#   Data transfer to stop.
#   Path to configuration file.
# Outputs:
#   None
#######################################
function stop_client_iperf() {
    local DT_NAME=$1
    local CONFIGURATION=$2
    local IPERF_PID=$(jq -r ".[] | select(.dt == \"$DT_NAME\") | .\"client\".\"iperf-pid\"" $ACTIVE_IPERFS)
    local CLIENT_HOST=$(get_data_transfer_client_host $DT_NAME $CONFIGURATION)
    local IP=$(get_host_ip $CLIENT_HOST $CONFIGURATION)
    local USERNAME=$(get_host_username $CLIENT_HOST $CONFIGURATION)
    local PASSWORD=$(get_host_password $CLIENT_HOST $CONFIGURATION)
    local IPERF_KILL_STATUS=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -l $USERNAME $IP "kill $IPERF_PID 2>&1; wait \$!")
    log_info "Output from killing of server window: \n$IPERF_KILL_STATUS"
}

#######################################
# Stops given data transfers.
# Globals:
#   None
# Arguments:
#   Data transfer to stop.
#   Path to configuration file.
# Outputs:
#   None
#######################################
function stop_data_transfer() {
    local DT_NAME=$1
    local CONFIGURATION=$2
    stop_server_iperf $DT_NAME $CONFIGURATION
    stop_client_iperf $DT_NAME $CONFIGURATION
    local SERVER_WINDOW_PID=$(jq -r ".[] | select(.dt == \"$DT_NAME\") | .\"server\".\"window-pid\"" $ACTIVE_IPERFS)
    local CLIENT_WINDOW_PID=$(jq -r ".[] | select(.dt == \"$DT_NAME\") | .\"client\".\"window-pid\"" $ACTIVE_IPERFS)
    local SERVER_WINDOW_KILL_STATUS=$(kill $SERVER_WINDOW_PID 2>&1; wait $!)
    log_info "Output from killing of server window: \n$SERVER_WINDOW_KILL_STATUS"
    local CLIENT_WINDOW_KILL_STATUS=$(kill $CLIENT_WINDOW_PID 2>&1; wait $!)
    log_info "Output from killing of client window: \n$CLIENT_WINDOW_KILL_STATUS"
    local TEMPFILE=$(mktemp)
    cp $ACTIVE_IPERFS "$TEMPFILE"
    local DT=$(jq -r "del(.[] | select(.dt == \"$DT_NAME\"))" $TEMPFILE > $ACTIVE_IPERFS)
    rm -f "$TEMPFILE"
}

#######################################
# Reads user commands and schedule corresponding action.
# Globals:
#   None
# Arguments:
#   Path to configuration file.
# Outputs:
#   None
#######################################
function run_infinite_loop() {
    local CONFIGURATION=$1
    log_info "Running infinite shell loop based on $CONFIGURATION configuration."
    while read -e -p "$PROMPT " COMMAND ARGS; do
        case $COMMAND in
            start)
                if [[ -z $ARGS ]] ; then
                    ARGS=$(jq -r ".\"data-transfers\" | keys[]" $CONFIGURATION)
                fi
                for DT_NAME in $ARGS ; do
                    DT=$(jq -r ".\"data-transfers\".\"$DT_NAME\"" $CONFIGURATION)
                    if [[ $? -eq 0 && $DT != "null" ]] ; then
                        local IS_ACTIVE=$(jq -r ".[] | select(.dt == \"$DT_NAME\") | .dt" $ACTIVE_IPERFS)
                        if [[ "$IS_ACTIVE" != "$DT_NAME" ]] ; then
                            echo "Starting \"$DT_NAME\" data transfer..."
                            start_data_transfer $DT_NAME $CONFIGURATION
                        else
                            echo "\"$DT_NAME\" data transfer is already started."
                        fi
                    else
                        echo "\"$DT_NAME\" data transfer doesn't exists."
                    fi
                done
                ;;
            stop)
                if [[ -z $ARGS ]] ; then
                    ARGS=$(jq -r ".\"data-transfers\" | keys[]" $CONFIGURATION)
                fi
                for DT_NAME in $ARGS ; do
                    local IS_ACTIVE=$(jq -r ".[] | select(.dt == \"$DT_NAME\") | .dt" $ACTIVE_IPERFS)
                    if [[ "$IS_ACTIVE" == "$DT_NAME" ]] ; then
                        echo "Stoping \"$DT_NAME\" data transfer..."
                        stop_data_transfer $DT_NAME $CONFIGURATION
                    else
                        echo "\"$DT_NAME\" data transfer was not activated."
                    fi
                done
                ;;
            q|quit)
                echo "See you!"
                exit 0
                ;;
            ?|help)
                echo "Commands:"
                echo "start <data transfer name> - start given data transer; "
                echo "                             if no data transfer name is given then all data transfers from the configuration file will be started"
                echo "stop  <data transfer name> - stop given data transer; "
                echo "                             if no data transfer name is given then all data transfers from the configuration file will be stoped"
                echo "quit or q                  - quit linux iperf controller"
                echo "help or ?                  - show this help"
                ;;
            *)
                echo "Command unknown. Type help or ? to list commands."
                ;;
        esac
        history -s "$COMMAND $ARGS"
    done
}

#######################################
# Runs infinite shell loop.
# Globals:
#   None
# Arguments:
#   Path to configuration file. 
# Outputs:
#   None
#######################################
function run_shell() {
    local CONFIGURATION=$1
    echo "Welcome to the Linux Iperf Controller shell."
    echo
    echo "Checking libraries..."
    echo -n "- jq... "
    check_jq
    echo -n "- xterm... "
    check_xterm
    echo
    echo -n "Checking configuration... "
    check_configuration $CONFIGURATION
    echo 
    echo "Type help or ? to list commands."
    echo
    run_infinite_loop $CONFIGURATION
}


initialize_logger $LOGS_FILE


case  $1 in 

    -g|--generate)
        if [[ -n $2 ]] ; then
            generate_configuration $2
        else
            MSG="Error ERROR_MISSING_OPTION_VALUE ($ERROR_MISSING_OPTION_VALUE): Option -g|--generate <filename> requires filename."
            log_error "$MSG"
            echo $MSG
            exit $ERROR_MISSING_OPTION_VALUE
        fi
        ;;
    -c|--config)
        if [[ -n $2 ]] ; then
            run_shell $2
        else
            MSG="Error ERROR_MISSING_OPTION_VALUE ($ERROR_MISSING_OPTION_VALUE): Option -c|--config <filename> requires filename."
            log_error "$MSG"
            echo $MSG
            exit $ERROR_MISSING_OPTION_VALUE
        fi
        ;; 
    *)
        echo "Please use -c|--config <filename> option to load configuration or -g|--generate <filename> option to generate configuration."
        ;;

esac
