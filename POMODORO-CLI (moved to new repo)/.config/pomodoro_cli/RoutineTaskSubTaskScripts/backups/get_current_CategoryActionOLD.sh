#!/bin/bash

# --- Diagnostic Line ---
# This line will help us understand which shell is actually running this script.
echo "Running with SHELL: $0, BASH_VERSION: $BASH_VERSION"
# --- End Diagnostic Line ---

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
# These variables will store the final quick result values to be used in the combined output.
quick_result_routine_name=""
quick_result_category_action="" # Renamed
# --- End QuickResult variables ---

# Initialize output_content string that will accumulate all parts of the output *after* the quick result.
output_content=""

# Get the current hour and minute for time-based routine matching
current_hour=$(date +%H)
current_minute=$(date +%M)

# Convert current time to total minutes from midnight for easy comparison
current_total_minutes=$((10#$current_hour * 60 + 10#$current_minute))

# Check if today's planner file exists. If not, populate error content and set quick result values, then exit.
if [ ! -f "$PLANNER_FILE" ]; then
    output_content+="--------------------------------------------------------\n"
    output_content+="Starting Routine, Action List, and Category/Action retrieval for $current_date at $(date)\n" # Updated message
    output_content+="--------------------------------------------------------\n"
    output_content+="Error: Planner file '$PLANNER_FILE' not found. Please ensure your daily journal is in the specified path.\n"
    output_content+="--------------------------------------------------------\n"

    quick_result_routine_name="No Active Routine" # Set for quick result section
    quick_result_category_action="NONE" # Renamed # Set for quick result section

    output_content+="Script finished at $(date)\n"
    output_content+="Output captured in: $(pwd)/$OUTPUT_FILE\n"

    # --- Final Print to STDOUT and File (for early exit) ---
    # This block now prepares the quick result and combines it with output_content for unified print.
    final_combined_output="QUICK RESULT\n"
    final_combined_output+="$quick_result_routine_name\n"
    final_combined_output+="$quick_result_category_action\n" # Renamed
    final_combined_output+="--------------------------------------------------------\n"
    final_combined_output+="$output_content"

    echo -e "$final_combined_output" > "$OUTPUT_FILE"
    echo -e "$final_combined_output"

    exit 1
fi

# Append initial logging information (This comes *after* the quick result, so no quick result data here).
output_content+="--------------------------------------------------------\n"
output_content+="Starting Routine, Action List, and Category/Action retrieval for $current_date at $(date)\n" # Updated message
output_content+="--------------------------------------------------------\n"

# Initialize an empty array to store all matched routine descriptions along with their line numbers.
matched_routines_with_lines=()
line_num=0 # Counter for current line number in the planner file

# Initialize new arrays for grouped consideration list items
linked_notes_from_routine_name_items=()
direct_subtask_items=()
linked_notes_from_subtasks_items=()

# Initialize a temporary array for the new unified consideration list (tasks + all linked notes)
# This array will be populated by consolidating the grouped arrays.
all_consideration_list_items=()


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
        start_total_minutes=$((10#$start_hour * 60 + 10#$current_minute))
        end_total_minutes=$((10#$end_hour * 60 + 10#$end_minute))

        # Check if the current system time falls within the routine's time slot.
        # This condition handles routines that cross midnight (e.g., 23:00 - 02:00).
        if (( current_total_minutes >= start_total_minutes && current_total_minutes < end_total_minutes )) || \
           ( (( end_total_minutes < start_total_minutes )) && \
             ( (current_total_minutes >= start_total_minutes) || (current_total_minutes < end_total_minutes) ) ) ; then

            # If the routine is active, add its description and line number to the array.
            matched_routines_with_lines+=("${line_num}|${routine_description_final}")

            # If the routine description itself contains a linked note,
            # and the routine is active, then add it to the specific array for routine-level links.
            if [[ "$routine_description_final" =~ \[\[([^]]+)\]\] ]]; then
                linked_note_from_routine="${BASH_REMATCH[1]}"
                linked_notes_from_routine_name_items+=("((from [[${linked_note_from_routine}]]))") # Indicate source
            fi
        fi
    fi
done < "$PLANNER_FILE"

# Initialize an array to store all tasks (action list items) found under active routines.
all_action_list_items=() # This is still for the CATEGORY/ACTION LIST display

# Process the identified active routines to extract their associated action list items.
if [ ${#matched_routines_with_lines[@]} -gt 0 ]; then
    output_content+="🎯 YOUR CURRENT ROUTINE NAME:\n"
    output_content+="----------------------------------------\n"

    # Populate quick_result_routine_name_parts for quick result section
    quick_result_routine_name_parts=()

    for routine_item_with_line in "${matched_routines_with_lines[@]}"; do
        IFS='|' read -r routine_line_num routine_description <<< "$routine_item_with_line"
        output_content+="➡️ $routine_description\n"
        quick_result_routine_name_parts+=("$routine_description") # Add to parts for quick result
        
        # Use awk to extract indented list items immediately following the routine line.
        # This identifies action list items associated with the routine.
        routine_tasks=$(awk -v start_line="$routine_line_num" '
            NR > start_line && (/^[[:space:]]+- \[.\] / || /^[[:space:]]+-/ || /^[[:space:]]+\*/ || /^[[:space:]]+[0-9]+\./) {
                task_line = $0;
                sub(/^[[:space:]]+/, "", task_line); # Remove leading indentation
                print task_line; # Print the cleaned task line
                next;
            }
            # Stop processing if a non-indented line or a non-task line is encountered after the routine.
            NR > start_line && !(/^[[:space:]]+- \[.\] / || /^[[:space:]]+-/ || /^[[:space:]]+\*/ || /^[[:space:]]+[0-9]+\./) {
                exit;
            }
        ' "$PLANNER_FILE")

        if [ -n "$routine_tasks" ]; then
            # Read each task line into the all_action_list_items array and direct_subtask_items array.
            while IFS= read -r task; do
                all_action_list_items+=("$task") # For CATEGORY/ACTION LIST display
                direct_subtask_items+=("$task") # For 'Subtasks' group in consideration list

                # If the task contains a linked note, add it to the specific array for subtask-level links.
                if [[ "$task" =~ \[\[([^]]+)\]\] ]]; then
                    linked_note_from_task="${BASH_REMATCH[1]}"
                    linked_notes_from_subtasks_items+=("((from [[${linked_note_from_task}]]))") # Indicate source
                fi
            done <<< "$routine_tasks"
        fi
    done
    output_content+="\n"

    # Join multiple routine names with " / " for quick result
    IFS=' / ' quick_result_routine_name="${quick_result_routine_name_parts[*]}"

else
    output_content+="🎯 No active routines found for the current time.\n"
    output_content+="----------------------------------------\n\n"
    quick_result_routine_name="No Active Routine" # Set for quick result section
fi

# Consolidate all unique items into all_consideration_list_items for a unified search
# This map ensures that no item is duplicated in the search list, regardless of its source group.
declare -A temp_unique_items_map
for item in "${linked_notes_from_routine_name_items[@]}"; do temp_unique_items_map["$item"]=1; done
for item in "${direct_subtask_items[@]}"; do temp_unique_items_map["$item"]=1; done
for item in "${linked_notes_from_subtasks_items[@]}"; do temp_unique_items_map["$item"]=1; done

for item in "${!temp_unique_items_map[@]}"; do
    all_consideration_list_items+=("$item")
done


# --- Determine the category/action --- # Updated comment
category_action_found="" # Renamed
category_action_source_note="" # Renamed
found_category_actions_list=() # Renamed


# Attempt to find #CategoryOrAction within the unified consideration list. # Updated message
# This loop now checks both direct tasks and linked notes.
for item_to_consider in "${all_consideration_list_items[@]}"; do
    if [[ "$item_to_consider" =~ \#CategoryOrAction ]]; then # Updated tag
        # Found directly in a task or a representation string from a linked note
        found_category_actions_list+=("$item_to_consider") # Renamed
        
        # If no category_action_found yet, set this one as the primary
        if [ -z "$category_action_found" ]; then # Renamed
            category_action_found="$item_to_consider" # Renamed
            category_action_source_note="" # Renamed # Reset if found directly in task
            # Check if the direct match came from a linked note representation
            if [[ "$category_action_found" =~ \(\(from\ \[\[([^]]+)\]\]\)\) ]]; then # Renamed
                category_action_source_note="[[${BASH_REMATCH[1]}]]" # Renamed
            fi
        fi
    elif [[ "$item_to_consider" =~ \(\(from\ \[\[([^]]+)\]\]\)\) ]]; then
        # This item is a representation of a linked note, so search inside the actual file
        note_name="${BASH_REMATCH[1]}"
        # Find the linked Markdown file within the Obsidian vault.
        linked_file_path=$(find "$OBSIDIAN_VAULT_PATH" -type f -iname "${note_name}.md" -print -quit 2>/dev/null)
        if [ -n "$linked_file_path" ]; then
            # Grep for #CategoryOrAction in the linked file. -m 1 exits after first match. # Updated tag
            found_in_linked_note=$(grep -m 1 "#CategoryOrAction" "$linked_file_path" 2>/dev/null) # Updated tag
            if [ -n "$found_in_linked_note" ]; then
                # Append the original "((from [[note]]))" part to the found action for clarity
                full_found_item="${found_in_linked_note} ${item_to_consider}"
                found_category_actions_list+=("$full_found_item") # Renamed

                # If no category_action_found yet, set this one as the primary
                if [ -z "$category_action_found" ]; then # Renamed
                    category_action_found="$full_found_item" # Renamed
                    category_action_source_note="[[${note_name}]]" # Renamed # Capture the source note name
                fi
            fi
        fi
    fi
done


# Prepare the category/action display header and content based on whether an action was found. # Updated message
category_action_display_header="" # Renamed
category_action_display_content="" # Renamed

if [ -n "$category_action_found" ]; then # Renamed
    # Clean up the found action item by removing #CategoryOrAction tag and leading list markers, # Updated tag
    # and also remove the ((from [[note]])) part for the main display, keep it for quick result.
    cleaned_category_action=$(echo "$category_action_found" | sed -E 's/ \#CategoryOrAction//g; s/^\s*[-*] \[.?\]\s*//g; s/^\s*[-*]\s*//g; s/^\s*[0-9]+\.\s*//g; s/\s*\(\(from\ \[\[[^]]+\]\]\)\)//g' | xargs) # Updated tag
    
    # Construct the dynamic header including the source note if available
    if [ -n "$category_action_source_note" ]; then # Renamed
        category_action_display_header="✨ YOUR CURRENT CATEGORY/ACTION #CategoryOrAction ${category_action_source_note} :" # Updated message and tag
    else
        category_action_display_header="✨ YOUR CURRENT CATEGORY/ACTION #CategoryOrAction :" # Updated message and tag
    fi
    
    category_action_display_content="$cleaned_category_action" # Renamed
    quick_result_category_action="$cleaned_category_action" # Set for quick result section
else
    category_action_display_header="✨ YOUR CURRENT CATEGORY/ACTION (No category/action identified with '#CategoryOrAction' tag.) :" # Updated message and tag
    category_action_display_content="NONE" # Renamed
    quick_result_category_action="NONE" # Set for quick result section
fi

# Helper function for printing grouped lists within the consideration section
# It takes the header and a list of items as arguments
print_grouped_list() {
    local header="$1"
    shift
    local items=("$@")
    output_content+="    ➡️ **$header**\n"
    if [ ${#items[@]} -gt 0 ]; then
        # Use a temporary associative array for uniqueness within THIS specific group's display
        declare -A unique_map
        for item in "${items[@]}"; do
            unique_map["$item"]=1
        done
        for item in "${!unique_map[@]}"; do
            output_content+="        - $item\n"
        done
    else
        output_content+="        (None)\n"
    fi
}

# Append "CONSIDERED LIST FOR CATEGORY OR ACTION" section with grouping.
output_content+="✨ CONSIDERED LIST FOR CATEGORY OR ACTION:\n"
output_content+="----------------------------------------\n"

if [ ${#linked_notes_from_routine_name_items[@]} -gt 0 ] || \
   [ ${#direct_subtask_items[@]} -gt 0 ] || \
   [ ${#linked_notes_from_subtasks_items[@]} -gt 0 ]; then

    print_grouped_list "Linked Notes from Routine Name" "${linked_notes_from_routine_name_items[@]}"
    print_grouped_list "Subtasks" "${direct_subtask_items[@]}"
    print_grouped_list "Linked Notes from Subtasks" "${linked_notes_from_subtasks_items[@]}"
else
    output_content+="    (No items added to the consideration list.)\n"
fi
output_content+="\n"


# --- Check for Duplicate #CategoryOrAction Tags --- # Updated message
output_content+="🔍 DUPLICATE #CategoryOrAction TAGS CHECK:\n" # Updated message
output_content+="----------------------------------------\n"

if [ ${#found_category_actions_list[@]} -gt 1 ]; then # Renamed
    output_content+="    ❌ Multiple instances of #CategoryOrAction were found!\n" # Updated message
    output_content+="    Please ensure only one #CategoryOrAction is active at a time.\n" # Updated message
    output_content+="    Found #CategoryOrAction tags in the following items:\n" # Updated message
    # Use a map to print unique found_category_actions_list items
    declare -A unique_found_actions_map
    for action_item in "${found_category_actions_list[@]}"; do # Renamed
        unique_found_actions_map["$action_item"]=1
    done
    for action_item in "${!unique_found_actions_map[@]}"; do
        output_content+="        - $action_item\n"
    done
else
    output_content+="    ✅ No duplicate #CategoryOrAction tags found. Only one (or zero) active #CategoryOrAction.\n" # Updated message
fi
output_content+="\n"


# Append "CATEGORY/ACTION" with the new, dynamic format. # Updated message
output_content+="$category_action_display_header\n" # Renamed
output_content+="----------------------------------------\n"
output_content+="$category_action_display_content\n" # Renamed
output_content+="--------------------------------------------------------\n"

# Append final logging information.
output_content+="Script finished at $(date)\n"
output_content+="Output captured in: $(pwd)/$OUTPUT_FILE\n"

# --- Final Print to STDOUT and File ---
# Construct the final output string with QUICK RESULT at the top, followed by the main content.
final_combined_output="QUICK RESULT\n"
final_combined_output+="$quick_result_routine_name\n"
final_combined_output+="$quick_result_category_action\n" # Renamed
final_combined_output+="--------------------------------------------------------\n"
final_combined_output+="$output_content"

echo -e "$final_combined_output" > "$OUTPUT_FILE"
echo -e "$final_combined_output"
