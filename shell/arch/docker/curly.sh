#!/bin/bash
# this script adds additional retry and response code checking for curl to verify the download is successful

readonly ourScriptName=$(basename -- "$0")
readonly defaultRetryCount=5
readonly defaultRetryWait="10"
readonly defaultOutputFile="/tmp/curly_output"
readonly defaultSilentMode="true"
retry_count="${defaultRetryCount}"
retry_wait="${defaultRetryWait}"
output_file="${defaultOutputFile}"
silent_mode="${defaultSilentMode}"

function run_curl() {

	if [[ "${silent_mode}" == "false" ]]; then
		echo -e "[info] Attempting to curl ${url}...\n"
	fi

	# construct retry max time from count and wait
	retry_max_time=$((${retry_count}*${retry_wait}))

	# add in silent mode flag for curl if set to 'true' (default)
	if [[ "${silent_mode}" == "false" ]]; then
		silent_mode=""
	else
		silent_mode="-s"
	fi

	while true; do

		response_code=$(curl --connect-timeout 5 --max-time 10 --retry "${retry_count}" --retry-delay "${retry_wait}" --retry-max-time "${retry_max_time}" -o "${output_file}" -L "${silent_mode}" -w "%{http_code}" "${url}")

		if [ "${response_code}" -ge "200" ] && [ "${response_code}" -le "299" ]; then
			if [[ "${silent_mode}" == "false" ]]; then
			  echo -e "\n[info] curl successful for ${url}, response code ${response_code}"
			fi
			break
		else
			if [ "${retry_count}" -eq "0" ]; then
				echo -e "\n[warn] Response code ${response_code} from curl != 2xx, exausted retries exiting script..."; exit 1
			else
				if [[ "${silent_mode}" == "false" ]]; then
				  echo -e "\n[warn] Response code ${response_code} from curl != 2xx, retrying in 10 secs..."; sleep "${retry_wait}"
				fi
				retry_count=$((retry_count-1))
			fi
		fi

	done
}

function show_help() {
	cat <<ENDHELP
Description:
	Wrapper for curl to ensure it retries when failing to download (non 2xx code).
Syntax:
	${ourScriptName} [args]
Where:
	-h or --help
		Displays this text.

	-rc or --retry-count <number>
		Set the number of retries before we give up.
		Defaults to '${defaultRetryCount}'.

	-rw or --retry-wait <number>
		Time in seconds to wait between retries.
		Defaults to '${defaultRetryWait}'.

	-of or --output-file <path+filename>
		Path to filename to store result from curl.
		Defaults to '${defaultOutputFile}'.

	-sm or --silent-mode <true|false>
		Define whether to run curl silently or not.
		Defaults to '${defaultSilentMode}'.

	-url or --url <url>
		URL that curl will process.
		No default.
Example:
	curly.sh -rc 6 -rw 10 -of /tmp/curly_output -sm true -url http://www.google.co.uk
ENDHELP
}

while [ "$#" != "0" ]
do
	case "$1"
	in
		-rc|--retry-count)
			retry_count=$2
			shift
			;;
		-rw|--retry-wait)
			retry_wait=$2
			shift
			;;
		-of|--output-file)
			output_file=$2
			shift
			;;
		-sm|--silent-mode)
			silent_mode=$2
			shift
			;;
		-url|--url)
			url=$2
			shift
			;;
		-h|--help)
			show_help
			exit 0
			;;
		*)
			echo "${ourScriptName}: ERROR: Unrecognised argument '$1'." >&2
			show_help
			 exit 1
			 ;;
	 esac
	 shift
done

run_curl "${retry_count}" "${retry_wait}" "${output_file}" "${silent_mode}" "${url}"
