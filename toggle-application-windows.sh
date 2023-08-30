#!/bin/bash
# TODO: proper place for the log in the unix system

window_title=""
command_to_execute=""

function get_args() {
	options=$(getopt -o t:c: --long window-title:,command: -n "$0" -- "$@")
	eval set -- "$options"

	while true; do
		case "$1" in
		-t | --window-title)
			window_title="$2"
			shift 2
			;;
		-c | --command)
			command_to_execute="$2"
			shift 2
			;;
		--)
			shift
			break
			;;
		*)
			echo "Internal error!"
			exit 1
			;;
		esac
	done

	# Check if required options are provided
	if [ -z "$window_title" ] || [ -z "$command_to_execute" ]; then
		echo "Usage: $0 --window-title <window-title> --command <command>"
		exit 1
	fi
}

get_args "$@"

window_ids=$(wmctrl -l | grep "$window_title" | awk '{print $1}')
number_of_window_ids=$(echo "$window_ids" | wc -l)

log_file="$HOME/Private/dotfiles/bin/toggle.log"
config_folder="$HOME/.config/toggle-application-windows"
command_file="$config_folder/$command_to_execute.txt"

create_required_directories_and_files() {
	if [ ! -d "$config_folder" ]; then
		mkdir -p "$config_folder"
	fi

	if [ ! -f "$command_file" ]; then
		touch "$command_file"
	fi

	if [ ! -f "$log_file" ]; then
		touch "$log_file"
	fi
}

open_new_application_window() {
	printf "No windows with title '%s' found. Opening a new one...\n" "$window_title"
	# store values 1 - number of available windows and 1 - selected window
	printf "1 1" >"$command_file"
	$command_to_execute &
}

toggle_open_application_windows() {
	read -r previous_number_of_windows previous_selected_window_index <"$command_file"

	selected_window_index=1
	# TODO: extract this to a function so it will be more readable
	if [ "$number_of_window_ids" -eq "$previous_number_of_windows" ]; then
		# is not equal
		if [ "$previous_selected_window_index" -ne "$number_of_window_ids" ]; then
			selected_window_index=$((previous_selected_window_index + 1))
		fi
	fi

	printf "%s %s" "$number_of_window_ids" "$selected_window_index" >"$command_file"
	printf "Selected window index: %s\n" "$selected_window_index"

	wmctrl -i -a "$(echo "$window_ids" | sed -n "$selected_window_index"p)"
}

main() {
	create_required_directories_and_files
	printf "Number of available windows: %s\n" "$number_of_window_ids"

	if [ "$number_of_window_ids" -eq 0 ]; then
		open_new_application_window
	else
		toggle_open_application_windows
	fi

	exit 0
}

main
