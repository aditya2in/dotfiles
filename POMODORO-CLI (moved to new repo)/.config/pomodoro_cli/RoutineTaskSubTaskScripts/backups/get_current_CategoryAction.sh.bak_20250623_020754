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
    output_content+="Error: Planner file '$PLANNER_FILE' not found. Please ensure your daily journal is in the specified path.\n"
    output_content+="--------------------------------------------------------\n"
    output_content+="Script finished at $(date)\n"
    output_content+="Output captured in: $(pwd)/$OUTPUT_FILE\n"

    quick_result_routine_name="No Active Routine (Planner File Missing)"
    quick_result_current_action="N/A"

    final_output_to_print="QUICK RESULT\n"
    final_output_to_print+="$quick_result_routine_name\n"
    final_output_to_print+="$quick_result_current_action\n"
    final_output_to_print+="--------------------------------------------------------\n"
    final_output_to_print+="$output_content"

    echo -e "$final_output_to_print" > "$OUTPUT_FILE"
    echo -e "$final_output_to_print"
    exit 1
fi

# Append initial logging information.
output_content+="--------------------------------------------------------\n"
output_content+="Starting Routine, Action List, and Current Action retrieval for $current_date at $(date)\n"
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
        start_total_minutes=$((10#$start_hour * 60 + 10#$start_minute))
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

    # Quick result for routine name
    quick_result_routine_name_parts=()

    for routine_item_with_line in "${matched_routines_with_lines[@]}"; do
        IFS='|' read -r routine_line_num routine_description <<< "$routine_item_with_line"
        output_content+="➡️ $routine_description\n"
        quick_result_routine_name_parts+=("$routine_description")

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
    quick_result_routine_name="No Active Routine"
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


# --- Determine the current action ---
current_action_found=""
current_action_source_note="" # New variable to store the source linked note for the header
found_current_actions_list=() # Array to store all items identified with #CurrentAction


# Attempt to find #CurrentAction within the unified consideration list.
# This loop now checks both direct tasks and linked notes.
for item_to_consider in "${all_consideration_list_items[@]}"; do
    if [[ "$item_to_consider" =~ \#CurrentAction ]]; then
        # Found directly in a task or a representation string from a linked note
        found_current_actions_list+=("$item_to_consider") # Add to list for duplicate check
        
        # If no current_action_found yet, set this one as the primary
        if [ -z "$current_action_found" ]; then
            current_action_found="$item_to_consider"
            current_action_source_note="" # Reset if found directly in task
            # Check if the direct match came from a linked note representation
            if [[ "$current_action_found" =~ \(\(from\ \[\[([^]]+)\]\]\)\) ]]; then
                current_action_source_note="[[${BASH_REMATCH[1]}]]"
            fi
        fi
    elif [[ "$item_to_consider" =~ \(\(from\ \[\[([^]]+)\]\]\)\) ]]; then
        # This item is a representation of a linked note, so search inside the actual file
        note_name="${BASH_REMATCH[1]}"
        # Find the linked Markdown file within the Obsidian vault.
        linked_file_path=$(find "$OBSIDIAN_VAULT_PATH" -type f -iname "${note_name}.md" -print -quit 2>/dev/null)
        if [ -n "$linked_file_path" ]; then
            # Grep for #CurrentAction in the linked file. -m 1 exits after first match.
            found_in_linked_note=$(grep -m 1 "#CurrentAction" "$linked_file_path" 2>/dev/null)
            if [ -n "$found_in_linked_note" ]; then
                # Append the original "((from [[note]]))" part to the found action for clarity
                full_found_item="${found_in_linked_note} ${item_to_consider}"
                found_current_actions_list+=("$full_found_item") # Add to list for duplicate check

                # If no current_action_found yet, set this one as the primary
                if [ -z "$current_action_found" ]; then
                    current_action_found="$full_found_item"
                    current_action_source_note="[[${note_name}]]" # Capture the source note name
                fi
            fi
        fi
    fi
done


# Prepare the current action display header and content based on whether an action was found.
current_action_display_header=""
current_action_display_content=""

if [ -n "$current_action_found" ]; then
    # Clean up the found action item by removing #CurrentAction tag and leading list markers,
    # and also remove the ((from [[note]])) part for the main display, keep it for quick result.
    cleaned_current_action=$(echo "$current_action_found" | sed -E 's/ \#CurrentAction//g; s/^\s*[-*] \[.?\]\s*//g; s/^\s*[-*]\s*//g; s/^\s*[0-9]+\.\s*//g; s/\s*\(\(from\ \[\[[^]]+\]\]\)\)//g' | xargs)
    
    # Construct the dynamic header including the source note if available
    if [ -n "$current_action_source_note" ]; then
        current_action_display_header="✨ YOUR CURRENT ACTION #CurrentAction ${current_action_source_note} :"
    else
        current_action_display_header="✨ YOUR CURRENT ACTION #CurrentAction :"
    fi
    
    current_action_display_content="$cleaned_current_action"
    # For quick result, only show the cleaned action text without source link
    quick_result_current_action="$cleaned_current_action"
else
    current_action_display_header="✨ YOUR CURRENT ACTION (No current action identified with '#CurrentAction' tag.) :"
    current_action_display_content="NONE"
    quick_result_current_action="NONE"
fi

# Append "YOUR CATEGORY/ACTION LIST" section (original direct tasks only).
# Removed as per user request to streamline with "Considered List"
# output_content+="📝 YOUR CATEGORY/ACTION LIST:\n"
# output_content+="----------------------------------------\n"

# if [ ${#all_action_list_items[@]} -gt 0 ]; then
#     for action_item in "${all_action_list_items[@]}"; do
#         output_content+="    ➡️ $action_item\n"
#     done
# else
#     if [ ${#matched_routines_with_lines[@]} -gt 0 ]; then
#         output_content+="    (No specific action items listed for this routine.)\n"
#     else
#         output_content+="    (No active routines, so no action list items.)\n"
#     fi
# fi
# output_content+="\n"

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

# Call the helper function for each group
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


# --- Check for Duplicate #CurrentAction Tags ---
output_content+="🔍 DUPLICATE #CurrentAction TAGS CHECK:\n"
output_content+="----------------------------------------\n"

if [ ${#found_current_actions_list[@]} -gt 1 ]; then
    output_content+="    ❌ Multiple instances of #CurrentAction were found!\n"
    output_content+="    Please ensure only one #CurrentAction is active at a time.\n"
    output_content+="    Found #CurrentAction tags in the following items:\n"
    # Use a map to print unique found_current_actions_list items
    declare -A unique_found_actions_map
    for action_item in "${found_current_actions_list[@]}"; do
        unique_found_actions_map["$action_item"]=1
    done
    for action_item in "${!unique_found_actions_map[@]}"; do
        output_content+="        - $action_item\n"
    done
else
    output_content+="    ✅ No duplicate #CurrentAction tags found. Only one (or zero) active #CurrentAction.\n"
fi
output_content+="\n"


# Append "CURRENT ACTION" with the new, dynamic format.
output_content+="$current_action_display_header\n"
output_content+="----------------------------------------\n"
output_content+="$current_action_display_content\n"
output_content+=\"--------------------------------------------------------\\n\"\n

# Append final logging information.
output_content+="Script finished at $(date)\n"
output_content+="Output captured in: $(pwd)/$OUTPUT_FILE\n"

# --- Final Print to STDOUT and File ---
final_output_to_print="QUICK RESULT\n"
final_output_to_print+="$quick_result_routine_name\n"
final_output_to_print+="$quick_result_current_action\n"
final_output_to_print+="--------------------------------------------------------\n"
final_output_to_print+="$output_content"

echo -e "$final_output_to_print" > "$OUTPUT_FILE"
echo -e "$final_output_to_print"
