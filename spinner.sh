#!/bin/bash

# Main file to send pid - cmd to for tracking
pid_file="/tmp/pid_tracking_file"

err() {
    echo "[!] Error: ${@}" 1>&2
    exit 1
}

# Runs command, grabs pid and exit status
background() {
    ${cmd} &>/dev/null &
    pid="${!}"
    echo "${pid} - ${cmd}" > ${pid_file}
    wait "${pid}"
    echo "${?}" > ${pid_file}.${pid}
}

pid_file_cleanup() {
    rm ${pid_file:-rm_safeguard}* &>/dev/null # Cleanup any old pid files both main and sub.
}

# Required format: type (long/short) exit on error (exit/noexit) $command_to_run
# Example: echo_and_run -l -ne sleep 10
# Example: echo_and_run --long --noexit sleep 10
#   Type - short: Don't need to track background process;short and simple command
#   Type - long: Need to track background process; something that may take a few seconds
#   Exit on error - exit: If command fails, exit
#   Exit on error - noexit: Even if command fails, don't exit
# Note: If terminal is note wide enough, each "state" of spinner while print on new line
echo_and_run() { 
    case "${1}" in
    -l|--long)
    type="long"
    shift
    ;;
    -s|--short)
        type="short"
        shift
        ;;
    *)
        err "${@} - Specify (-l) long or (-s) short : echo_and_run --(long/short) --(exit/noexit) command"
        ;;
    esac 

    case "${1}" in
        -e|--exit)
            exit="yes"
            shift
            ;;
        -ne|--noexit)
            exit="no"
            shift
            ;;
        *)
            err "${@} - Specify (-e) exit or (-ne) no exit : echo_and_run --(long/short) --(exit/noexit) command"
            ;;
    esac 

    export cmd="${*}"
    if [[ "${type}" = "short" ]]; then
        echo -en "\t[!] Running '${*}': "
        if ${cmd} &>/dev/null ; then
            echo "OK"
            return 0
        else
            echo "FAIL"
            if [[ "${exit}" = "yes" ]]; then err "Check command ${cmd}";fi
            return 1
        fi
    fi

    if [[ "${type}" = "long" ]]; then
        pid_file_cleanup
        background &
        pid=$(grep "${cmd}" "${pid_file}" | awk '{print $1}')

        # While waiting for command to exit, (c) will be added to line.
        text="[!] Running ${*} :"
        while kill -0 "${pid}" &>/dev/null; do
            for state in '|' '/' '-' '\';do
                echo -ne "\r${text}(c): ${state}"
                sleep 0.25
            done
        done

        # While waiting for pid file to be created, (f) will be added to line.
        until [[ -f ${pid_file}.${pid} ]]; do
                for state in '|' '/' '-' '\'; do
                    echo -ne "\r${text}(f): ${state}"
                    sleep 0.25
                done
        done

        # Once it's past checking for pid file, (d) will be added to line.
        result=$(cat ${pid_file}.${pid})
        pid_file_cleanup
        case "${result}" in
        0) 
            echo -e "\r${text}(d): OK"
            return 0
            ;;
        1)
            echo -e "\r${text}(d): FAIL"
            if [[ "${exit}" = "yes" ]]; then err "Check command ${cmd}";fi
            return 1
            ;;
        *)
            err "Invalid status grabbed: ${result}"
            ;;
        esac
    fi
}

[[ -z ${@} ]] && echo_and_run --long --noexit sleep 5 || echo_and_run "${@}"

echo "End of script! This is used to show if --exit is specified and command fails it will before this line"
