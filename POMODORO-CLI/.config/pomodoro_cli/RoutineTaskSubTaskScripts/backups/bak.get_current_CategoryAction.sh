#!/bin/bash

# Get the current date in Букмекерлар-MM-DD format
current_date=$(date +%Y-%m-%d)

# Define the planner file name using the current date variable
# Ensure this path is correct for your daily journal files
PLANNER_FILE="/home/aditya/obsidian/All Things/Journal/Daily Journal/${current_date}.md"

# Define the root path to your Obsidian vault
# This is crucial for searching linked notes
OBSIDIAN_VAULT_PATH="/home/aditya/obsidian"

# Define a static output file name. This file will store the script's output.
OUTPUT_FILE="current_routine.txt"

# --- Variables to store data for QuickResult ---
quick_result_routine_name=""
quick_result_current_action=""
# --- End QuickResult variables ---

# Initialize output_content string that will accumulate all parts of the output
output_content=""

# Get the current hour and minute for time-based routine matching
current_hour=$(date +%H)
current_minute=$(date +%M)

# Convert current time to total minutes from midnight for easy comparison
current_total_minutes=$((10#$current_hour * 60 + 10#$current_minute))

# Check if today's planner file exists. If not, set error quick results and exit.
if [ ! -f "$PLANNER_FILE" ]; then
    output_content+="--------------------------------------------------------\n"
    output_content+="Starting Routine, Action List, and Current Action retrieval for $current_date at $(date)\n"
    output_content+="--------------------------------------------------------\n"
    output_content+="Error: Planner file '$PLANNER_FILE' not found for today!\n"
    output_content+="Please make sure a planner file for today exists at that path.\n"
    quick_result_routine_name="Error: Planner file not found."
    quick_result_current_action="Error: No Action."
    
    # Final log info for error case
    output_content+="--------------------------------------------------------\n"
    output_content+="Script finished at $(date)\n"
    output_content+="Output captured in: $(pwd)/$OUTPUT_FILE\n"

    # Print to stdout and file before exiting
    echo -e "QUICK RESULT\n${quick_result_routine_name}\n${quick_result_current_action}\n${output_content}" > "$OUTPUT_FILE"
    echo -e "QUICK RESULT\n${quick_result_routine_name}\n${quick_result_current_action}\n${output_content}"
    exit 1
fi

# Append initial standard messages to output_content
output_content+="--------------------------------------------------------\n"
output_content+="Starting Routine, Action List, and Current Action retrieval for $current_date at $(date)\n"
output_content+="--------------------------------------------------------\n"

# Initialize an empty array to store all matched routine descriptions along with their line numbers.
matched_routines_with_lines=()
line_num=0 # Counter for current line number in the planner file

# Loop through the planner file line by line to identify active routines.
while IFS= read -r line || [[ -n "$line" ]]; do
    line_num=$((line_num + 1))
    # Check if the line contains a time pattern (e.g., "HH:MM - HH:MM")
    if [[ "$line" =~ ([0-9]{2}:[0-9]{2})\ -\ ([0-9]{2}:[0-9]{2}) ]]; then
        start_time_str="${BASH_REMATCH[1]}" # Capture start time (e.g., "08:00")
        end_time_str="${BASH_REMATCH[2]}"   # Capture end time (e.g., "09:00")

        # Extract the routine description by removing the time pattern and leading bullet/checkbox.
        routine_description_raw="${line#*- \[ \] }"
        routine_description_final=$(echo "$routine_description_raw" | sed -E 's/\s*([0-9]{2}:[0-9]{2})\s*-\s*([0-9]{2}:[0-9]{2})\s*//' | xargs)

        # Parse start and end times into hour and minute components.
        start_hour=${start_time_str%:*}
        start_minute=${start_time_str#*:}
        end_hour=${end_time_str%:*}
        end_minute=${end_time_str#*:}

        # Convert routine start and end times to total minutes from midnight for comparison.
        start_total_minutes=$((10#$start_hour * 60 + 10#$start_minute))
        end_total_minutes=$((10#$end_hour * 60 + 10#$end_minute))

        # Check if the current system time falls within the routine's time slot.
        # This condition handles routines that cross midnight (e.g., 23:00 - 02:00).
        if (( current_total_minutes >= start_total_minutes && current_total_minutes < end_total_minutes )) || \
           ( (( end_total_minutes < start_total_minutes )) && \
             ( (current_total_minutes >= start_total_minutes) || (current_total_minutes < end_total_minutes) ) ) ; then

            # If the routine is active, add its description and line number to the array.
            matched_routines_with_lines+=("${line_num}|${routine_description_final}")
        fi
    fi
done < "$PLANNER_FILE"

# Initialize an array to store all tasks (action list items) found under active routines.
all_action_list_items=()
# Initialize variable to store the identified current action.
current_action_found=""

# --- Determine quick_result_routine_name based on found routines ---
if [ ${#matched_routines_with_lines[@]} -gt 0 ]; then
    IFS='|' read -r _ first_routine_description <<< "${matched_routines_with_lines[0]}"
    quick_result_routine_name="$first_routine_description"
else
    quick_result_routine_name="No routine currently scheduled."
fi
# --- End QuickResult routine name determination ---

# Process the identified active routines to extract their associated action list items.
if [ ${#matched_routines_with_lines[@]} -gt 0 ]; then
    if [ ${#matched_routines_with_lines[@]} -eq 1 ]; then
        found_routine_header="🎯 YOUR CURRENT ROUTINE NAME:"
    else
        found_routine_header="🎯 YOUR CURRENT ROUTINES NAME:"
    fi

    output_content+="$found_routine_header\n"
    output_content+="----------------------------------------\n"
    for routine_item_with_line in "${matched_routines_with_lines[@]}"; do
        IFS='|' read -r routine_line_num routine_description <<< "$routine_item_with_line"
        output_content+="$routine_description\n"
        routine_tasks=$(awk -v start_line="$routine_line_num" '
            NR > start_line && (/^[[:space:]]+- \[.\] / || /^[[:space:]]+-/ || /^[[:space:]]+\*/ || /^[[:space:]]+[0-9]+\./) {
                task_line = $0;
                sub(/^[[:space:]]+/, "", task_line); # Remove leading indentation
                print task_line; # Print the cleaned task line
                next;
            }
            NR > start_line && !(/^[[:space:]]+- \[.\] / || /^[[:space:]]+-/ || /^[[:space:]]+\*/ || /^[[:space:]]+[0-9]+\./) {
                exit; # Stop if a non-indented or non-task line is encountered
            }
        ' "$PLANNER_FILE")

        if [ -n "$routine_tasks" ]; then
            while IFS= read -r task; do
                all_action_list_items+=("$task")
            done <<< "$routine_tasks"
        fi
    done
    output_content+="\n"
else
    output_content+="🎯 YOUR CURRENT ROUTINE NAME:\n"
    output_content+="----------------------------------------\n"
    output_content+="❌ No routine currently scheduled.\n"
    output_content+="\n"
fi

# ----------------------------------------------------
# Logic for finding #CurrentAction:
# ----------------------------------------------------

# Attempt 1: Find #CurrentAction directly in the action list items
for action_item in "${all_action_list_items[@]}"; do
    if [[ "$action_item" =~ \#CurrentAction ]]; then
        current_action_found="$action_item"
        break
    fi
done

# Attempt 2: If #CurrentAction was NOT found, search inside linked Obsidian notes.
if [ -z "$current_action_found" ]; then
    for action_item in "${all_action_list_items[@]}"; do
        if [[ "$action_item" =~ \[\[([^]]+)\]\] ]]; then
            note_name="${BASH_REMATCH[1]}"
            linked_file_path=$(find "$OBSIDIAN_VAULT_PATH" -type f -iname "${note_name}.md" -print -quit 2>/dev/null)
            if [ -n "$linked_file_path" ]; then
                found_in_linked_note=$(grep -m 1 "#CurrentAction" "$linked_file_path" 2>/dev/null)
                if [ -n "$found_in_linked_note" ]; then
                    current_action_found="${found_in_linked_note} (from [[${note_name}]])"
                    break
                fi
            fi
        fi
    done
fi

# Initialize variables for the current action display based on found action
current_action_display_header=""
current_action_display_content=""

if [ -n "$current_action_found" ]; then
    if [[ "$current_action_found" =~ (.*)\ \(\(from\ \[\[([^]]+)\]\]\)\) ]]; then
        current_action_display_content_raw="${BASH_REMATCH[1]}"
        linked_note_info="(from [[${BASH_REMATCH[2]}]])"
        current_action_display_content=$(echo "$current_action_display_content_raw" | sed 's/ \#CurrentAction//g' | sed 's/^- \[\ \] //g' | xargs)
        current_action_display_header="✨ YOUR CURRENT ACTION #CurrentAction ${linked_note_info} :"
    else
        current_action_display_content_raw="$current_action_found"
        current_action_display_content=$(echo "$current_action_display_content_raw" | sed 's/ \#CurrentAction//g' | sed 's/^- \[\ \] //g' | xargs)
        current_action_display_header="✨ YOUR CURRENT ACTION #CurrentAction :"
    fi
    quick_result_current_action="$current_action_display_content"
else
    current_action_display_content="NONE"
    current_action_display_header="✨ YOUR CURRENT ACTION (No current action identified with '#CurrentAction' tag.) :"
    quick_result_current_action="NONE"
fi

# Append "YOUR CATEGORY/ACTION LIST" section.
output_content+="📝 YOUR CATEGORY/ACTION LIST:\n"
output_content+="----------------------------------------\n"

if [ ${#all_action_list_items[@]} -gt 0 ]; then
    for action_item in "${all_action_list_items[@]}"; do
        output_content+="    ➡️ $action_item\n"
    done
else
    if [ ${#matched_routines_with_lines[@]} -gt 0 ]; then
        output_content+="    (No specific action items listed for this routine.)\n"
    else
        output_content+="    (No active routines, so no action list items.)\n"
    fi
fi
output_content+="\n"

# Append "CURRENT ACTION" with the new, dynamic format.
output_content+="$current_action_display_header\n"
output_content+="----------------------------------------\n"
output_content+="$current_action_display_content\n"
output_content+="--------------------------------------------------------\n"

# Append final logging information.
output_content+="Script finished at $(date)\n"
output_content+="Output captured in: $(pwd)/$OUTPUT_FILE\n"

# --- Final Print to STDOUT and File ---
final_output_to_print="QUICK RESULT\n"
final_output_to_print+="$quick_result_routine_name\n"
final_output_to_print+="$quick_result_current_action\n"
final_output_to_print+="$output_content"

echo -e "$final_output_to_print" > "$OUTPUT_FILE"
echo -e "$final_output_to_print"
