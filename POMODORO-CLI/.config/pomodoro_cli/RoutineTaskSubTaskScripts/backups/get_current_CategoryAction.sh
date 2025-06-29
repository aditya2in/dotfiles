#!/bin/bash

# --- Diagnostic Line ---
# This line will help us understand which shell is actually running this script.
echo "Running with SHELL: $0, BASH_VERSION: $BASH_VERSION"
# --- End Diagnostic Line ---

# Get the current date in YYYY-MM-DD format
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
# These variables will store the final quick result values to be used in the combined output.
quick_result_routine_name=""
quick_result_category_action=""
# --- End QuickResult variables ---

# Initialize output_content string that will accumulate all parts of the output *after* the quick result.
output_content=""

# Get the current hour and minute for time-based routine matching
current_hour=$(date +%H)
current_minute=$(date +%M)

# Convert current time to total minutes from midnight for easy comparison
current_total_minutes=$((10#$current_hour * 60 + 10#$current_minute))

# --- Initial Logging Information ---
output_content+="INFORMATION ABOUT THE SCRIPT\n"
output_content+="--------------------------------------------------------\n"
output_content+="Starting Routine, Action List, and Category/Action retrieval for ${current_date} at $(date)\n"
output_content+="Planner file processed: $PLANNER_FILE\n"
output_content+="--------------------------------------------------------\n"

# Check if today's planner file exists. If not, populate error content and set quick result values.
if [ ! -f "$PLANNER_FILE" ]; then
    output_content+="ERROR: Planner file not found at $PLANNER_FILE. Please ensure your daily journal is created.\n"
    quick_result_routine_name="ERROR: Planner file not found."
    quick_result_category_action="ERROR: Planner file not found."
else
    # Find active routine based on current time
    # The routine line must be unchecked (- [ ]) and contain a time range (e.g., 09:00 - 10:00)
    # The routine must not be within a 'CRITICAL REVISION' section (indicated by specific tags or headers)
    active_routine_name=$(
        grep -E "^\s*-\s*\[\s*\]\s*\*\*[^_][^:]+?\*\*.*([0-1][0-9]|2[0-3]):[0-5][0-9]\s*-\s*([0-1][0-9]|2[0-3]):[0-5][0-9]" "$PLANNER_FILE" |
        grep -v -E "^\s*-\s*\[\s*\]\s*\*CRITICAL REVISION\*" |
        while IFS= read -r line; do
            # Extract start and end times from the line
            if [[ "$line" =~ ([0-1][0-9]|2[0-3]):([0-5][0-9])\s*-\s*([0-1][0-9]|2[0-3]):([0-5][0-9]) ]]; then
                start_hour=${BASH_REMATCH[1]}
                start_minute=${BASH_REMATCH[2]}
                end_hour=${BASH_REMATCH[3]}
                end_minute=${BASH_REMATCH[4]}

                start_total_minutes=$((10#$start_hour * 60 + 10#$start_minute))
                end_total_minutes=$((10#$end_hour * 60 + 10#$end_minute))

                # Check if current time is within the routine's time range
                if (( current_total_minutes >= start_total_minutes && current_total_minutes < end_total_minutes )); then
                    # Extract the routine name (text between ** and the time)
                    routine_name_raw=$(echo "$line" | sed -E 's/^\s*-\s*\[\s*\]\s*\*\*([^_][^:]+?)\*\*.*/\1/' | sed -E 's/\s+([0-1][0-9]|2[0-3]):[0-5][0-9]\s*-\s*([0-1][0-9]|2[0-3]):[0-5][0-9]//')
                    echo "$routine_name_raw"
                    exit 0 # Exit after finding the first active routine
                else
                    echo "        DEBUG: Current Time (min): $current_total_minutes | Routine '$line' Start (min): $start_total_minutes | End (min): $end_total_minutes"
                fi
            fi
        done
    )

    output_content+="ROUTINE DECLARATION\n"
    output_content+="----------------------------------------\n"
    if [ -n "$active_routine_name" ]; then
        output_content+="- **$active_routine_name**\n"
        quick_result_routine_name="Current Routine: $active_routine_name"
    else
        output_content+="No active routine found for the current time.\n"
        quick_result_routine_name="No Active Routine"
    fi
    output_content+="\n"

    # CRITICAL REVISION: Process file to extract subtasks and linked notes for the active routine, and find Category/Action tags
    output_content+="CRITICAL REVISION: CONSIDERED LISTS\n"
    output_content+="--------------------------------------------------------\n"

    TEMP_AWK_OUTPUT_FILE="awk_output_temp.txt"

    if [ -n "$active_routine_name" ]; then
        # Get the line number of the active routine to determine indentation
        routine_line_number=$(grep -n -E "^\s*-\s*\[\s*\]\s*\*\*${active_routine_name}\*\*.*([0-1][0-9]|2[0-3]):[0-5][0-9]\s*-\s*([0-1][0-9]|2[0-3]):[0-5][0-9]" "$PLANNER_FILE" | head -n 1 | cut -d: -f1)

        # AWK command to process the planner file
        # This AWK command is designed to:
        # 1. Capture the indentation of the active routine.
        # 2. Extract subtasks and linked notes belonging to that routine.
        # 3. Identify any #CategoryOrAction tags.
        awk -v current_time_param="$current_total_minutes" \
            -v routine_line_param="$routine_line_number" \
            -v routine_name_param="$active_routine_name" \
            -v obsidian_vault_path_param="$OBSIDIAN_VAULT_PATH" \
            '
            BEGIN {
                FS = ""; # Field separator for character-by-character processing, though not strictly used in this logic for fields.
                current_routine_indentation_param = -1;
                in_active_routine_block = 0;
                found_category_action = "";
                routine_subtasks_content = "";
                routine_linked_notes_content = "";
                duplicate_category_action_found = 0;
                found_category_actions_list_str = ""; # To collect all found tags as a string
                first_category_action_tag = ""; # To store the first tag encountered
            }
            
            # Check if the line matches the active routine, capture its indentation
            NR == routine_line_param {
                match($0, /^(\s*)-\s*\*?\*?(.+?)\*?\*?\s*([0-1][0-9]|2[0-3]):[0-5][0-9]\s*-\s*([0-1][0-9]|2[0-3]):[0-5][0-9]/);
                current_routine_indentation_param = length(substr($0, RSTART, RLENGTH)) - length(gensub(/^\s*/, "", "g", substr($0, RSTART, RLENGTH)));
                in_active_routine_block = 1;
                next;
            }

            # If inside the active routine block, process lines
            in_active_routine_block == 1 {
                # Check indentation: if current line's indentation is less than or equal to the routine's,
                # we've exited the routine's block of subtasks.
                line_indent = length($0) - length(gensub(/^\s*/, "", "g", $0));
                
                # Only process subtasks/linked notes if their indentation is greater than the routine's
                # and it's not another routine declaration line (to avoid capturing other routines as subtasks)
                # MODIFICATION: Changed 'line' to '$0' for awk to correctly process the current line.
                if (line_indent > current_routine_indentation_param && ! ($0 ~ /^\s*-\s*(\[\s*\]\s*)?\*\*MUSCLE MEMORY.*([0-1][0-9]|2[0-3]):[0-5][0-9]\s*-\s*([0-1][0-9]|2[0-3]):[0-5][0-9]/) ) {
                    # This line is a subtask or linked note
                    if ($0 ~ /\[\[[^\]]+\]\]/) {
                        # Linked note
                        match($0, /\[\[([^\]]+)\]\]/);
                        linked_note = substr($0, RSTART + 2, RLENGTH - 4);
                        # Use gsub to replace "[[...]]" with just the text inside brackets for cleaner output in some cases, or keep original line.
                        # For now, keeping original line for full context.
                        routine_linked_notes_content = (routine_linked_notes_content == "" ? "" : routine_linked_notes_content "\\n") "\\t- " $0;
                    } else if ($0 ~ /^\s*-\s*(\[[x ]\]\s*)?/) {
                        # Subtask (checked or unchecked)
                        routine_subtasks_content = (routine_subtasks_content == "" ? "" : routine_subtasks_content "\\n") "\\t- " $0;
                    }
                } else if (line_indent <= current_routine_indentation_param && NR > routine_line_param) {
                    # We have exited the routine's block
                    in_active_routine_block = 0;
                }
            }
            
            # Capture #CategoryOrAction tags anywhere in the file (not just within the routine block)
            if ($0 ~ /#CategoryOrAction\s*([^[:space:]]+)?/) {
                # Extract the tag, remove "#CategoryOrAction" part
                tag_content = gensub(/.*#CategoryOrAction\s*([^[:space:]]+)?.*/, "\\1", "1", $0);
                if (tag_content == "") {
                    tag_content = "DefaultCategoryAction"; # Or handle as needed for empty tag
                }
                
                # If it's the first tag, store it.
                if (first_category_action_tag == "") {
                    first_category_action_tag = tag_content;
                }
                
                # Add to the list of found tags as a comma-separated string
                found_category_actions_list_str = (found_category_actions_list_str == "" ? "" : found_category_actions_list_str "," ) tag_content;
            }

            END {
                # Need to pass these values back to the shell script.
                # AWK does not directly modify shell variables.
                # We'll print them in a structured format and parse them in bash.
                print "ROUTINE_SUBTASKS_CONTENT_START";
                print routine_subtasks_content;
                print "ROUTINE_SUBTASKS_CONTENT_END";
                
                print "ROUTINE_LINKED_NOTES_CONTENT_START";
                print routine_linked_notes_content;
                print "ROUTINE_LINKED_NOTES_CONTENT_END";

                # Determine the final category_action to display
                # Split found_category_actions_list_str into an array to check for duplicates
                n_tags = split(found_category_actions_list_str, temp_tags_array, ",");
                
                # Use an associative array to find unique tags
                delete unique_tags_map; # Clear map for each run
                for (i=1; i<=n_tags; i++) {
                    unique_tags_map[temp_tags_array[i]] = 1;
                }
                
                # Count unique tags
                unique_tags_count_awk = 0;
                for (tag in unique_tags_map) {
                    unique_tags_count_awk++;
                }

                if (unique_tags_count_awk > 1) {
                    duplicate_category_action_found = 1;
                    # If multiple unique tags, list them.
                    found_category_action = "Multiple #CategoryOrAction tags found:\\n";
                    for (tag in unique_tags_map) {
                        found_category_action = found_category_action "        - " tag "\\n";
                    }
                } else if (first_category_action_tag != "") {
                    found_category_action = first_category_action_tag;
                } else {
                    found_category_action = "No active category/action identified with '#CategoryOrAction' tag.";
                }


                print "FOUND_CATEGORY_ACTION_START";
                print found_category_action;
                print "FOUND_CATEGORY_ACTION_END";

                print "DUPLICATE_CATEGORY_ACTION_FOUND_START";
                print duplicate_category_action_found;
                print "DUPLICATE_CATEGORY_ACTION_FOUND_END";

                print "FOUND_CATEGORY_ACTIONS_LIST_STR_START";
                # For debugging or further processing in bash if needed
                print found_category_actions_list_str;
                print "FOUND_CATEGORY_ACTIONS_LIST_STR_END";
            }
            ' "$PLANNER_FILE" > "$TEMP_AWK_OUTPUT_FILE"

        # Parse output from AWK
        awk_output=$(cat "$TEMP_AWK_OUTPUT_FILE")

        routine_subtasks_content=$(echo "$awk_output" | sed -n '/ROUTINE_SUBTASKS_CONTENT_START/,/ROUTINE_SUBTASKS_CONTENT_END/{//!p}')
        routine_linked_notes_content=$(echo "$awk_output" | sed -n '/ROUTINE_LINKED_NOTES_CONTENT_START/,/ROUTINE_LINKED_NOTES_CONTENT_END/{//!p}')
        category_action_display_content=$(echo "$awk_output" | sed -n '/FOUND_CATEGORY_ACTION_START/,/FOUND_CATEGORY_ACTION_END/{//!p}')
        duplicate_category_action_status=$(echo "$awk_output" | sed -n '/DUPLICATE_CATEGORY_ACTION_FOUND_START/,/DUPLICATE_CATEGORY_ACTION_FOUND_END/{//!p}')
        # In case you need the raw list of tags in bash for any reason
        found_category_actions_list_str_bash=$(echo "$awk_output" | sed -n '/FOUND_CATEGORY_ACTIONS_LIST_STR_START/,/FOUND_CATEGORY_ACTIONS_LIST_STR_END/{//!p}')

        # Clean up temporary file
        rm "$TEMP_AWK_OUTPUT_FILE"

        if [ -n "$routine_subtasks_content" ]; then
            output_content+="- For Routine: '**$active_routine_name**'\n"
            output_content+="$routine_subtasks_content\n"
        fi

        if [ -n "$routine_linked_notes_content" ]; then
            if [ -z "$routine_subtasks_content" ]; then # Add header if no subtasks
                output_content+="- For Routine: '**$active_routine_name**'\n"
            fi
            output_content+="$routine_linked_notes_content\n"
        fi

        if [ -z "$routine_subtasks_content" ] && [ -z "$routine_linked_notes_content" ]; then
            output_content+="No routine found, so no subtasks or linked notes to display.\n"
        fi
    else
        output_content+="No routine found, so no subtasks or linked notes to display.\n"
    fi
    output_content+="\n"

    # Process and display Category/Action based on AWK output
    output_content+="DUPLICATE #CategoryOrAction TAGS CHECK:\n"
    output_content+="--------------------------------------------------------\n"

    # Split the comma-separated string into a bash array for easy iteration and uniqueness check
    IFS=',' read -r -a found_category_actions_list <<< "$found_category_actions_list_str_bash"

    declare -A unique_found_actions_map
    for action_item in "${found_category_actions_list[@]}"; do
        if [ -n "$action_item" ]; then # Ensure action_item is not empty
            unique_found_actions_map["$action_item"]=1
        fi
    done

    # Get the count of unique actions
    unique_actions_count="${#unique_found_actions_map[@]}"

    category_action_display_header="YOUR CURRENT CATEGORY/ACTION :"
    if [ "$unique_actions_count" -gt 1 ]; then
        output_content+="    Multiple #CategoryOrAction tags found. Please ensure only one is active at a time for clear focus.\n"
        output_content+="    Found tags:\n"
        # Iterate over keys (unique tags) in the associative array
        for action_item in "${!unique_found_actions_map[@]}"; do
            output_content+="        - $action_item\n"
        done
        quick_result_category_action="Multiple Active Category/Actions found. Check log."
    elif [ "$unique_actions_count" -eq 1 ]; then
        # If only one unique tag, display it
        local clean_category_action="${found_category_actions_list[0]}" # Assuming the first element is the single unique one
        # To be safe, iterate the map to get the single unique value.
        for item in "${!unique_found_actions_map[@]}"; do
            clean_category_action="$item"
            break # Get the first (and only) key
        done
        output_content+="    Found one active #CategoryOrAction: $clean_category_action\n"
        quick_result_category_action="Current Category/Action: $clean_category_action"
    else
        output_content+="    No duplicate #CategoryOrAction tags found. Only one (or zero) active #CategoryOrAction.\n"
        quick_result_category_action="No Active Category/Action"
    fi
    output_content+="\n"


    # Append "CATEGORY/ACTION" with the new, dynamic format.
    output_content+="$category_action_display_header\n"
    output_content+="----------------------------------------\n"
    output_content+="$category_action_display_content\n"
    output_content+="--------------------------------------------------------\n"
fi

# Append final logging information.
output_content+="FINAL CONCLUSION\n"
output_content+="--------------------------------------------------------\n"
output_content+="Script finished at $(date)\n"
output_content+="Output captured in: $(pwd)/$OUTPUT_FILE\n"
output_content+="--------------------------------------------------------\n"

# --- Final Print to STDOUT and File ---
# Construct the final output string with QUICK RESULT at the top, followed by the main content.
final_combined_output="QUICK RESULT\n"
final_combined_output+="$quick_result_routine_name\n"
final_combined_output+="$quick_result_category_action\n"
final_combined_output+="--------------------------------------------------------\n"
final_combined_output+="$output_content"

echo -e "$final_combined_output" > "$OUTPUT_FILE"
echo -e "$final_combined_output"
