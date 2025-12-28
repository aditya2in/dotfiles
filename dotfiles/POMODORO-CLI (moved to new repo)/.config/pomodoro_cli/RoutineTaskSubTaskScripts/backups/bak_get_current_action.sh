#!/bin/bash

# Get the current date in Букмекерлар-MM-DD format
current_date=$(date +%Y-%m-%d)

# Define the planner file name using the current date variable
PLANNER_FILE="/home/aditya/obsidian/All Things/Journal/Daily Journal/${current_date}.md"

# Define a static output file name
OUTPUT_FILE="current_routine.txt"

# Inform user about the output file location before starting, and overwrite the file
echo "🚀 Script will capture logs into: $(pwd)/$OUTPUT_FILE" > "$OUTPUT_FILE"
echo "Starting Routine, Action List, and Current Action retrieval for $current_date at $(date)" | tee -a "$OUTPUT_FILE"
echo "--------------------------------------------------------" | tee -a "$OUTPUT_FILE"

# Get the current hour and minute
current_hour=$(date +%H)
current_minute=$(date +%M)

# Convert current time to total minutes from midnight
current_total_minutes=$((10#$current_hour * 60 + 10#$current_minute))

# Check if the planner file exists
if [ ! -f "$PLANNER_FILE" ]; then
    echo "Error: Planner file '$PLANNER_FILE' not found for today!" | tee -a "$OUTPUT_FILE"
    echo "Please make sure a planner file for today exists at that path." | tee -a "$OUTPUT_FILE"
    exit 1
fi

# Initialize an empty array to store all matched routine descriptions along with their line numbers
matched_routines_with_lines=()
line_num=0

# Loop through the planner file line by line
while IFS= read -r line || [[ -n "$line" ]]; do
    line_num=$((line_num + 1))
    # Check if the line contains a time pattern (e.g., "HH:MM - HH:MM")
    if [[ "$line" =~ ([0-9]{2}:[0-9]{2})\ -\ ([0-9]{2}:[0-9]{2}) ]]; then
        start_time_str="${BASH_REMATCH[1]}"
        end_time_str="${BASH_REMATCH[2]}"

        routine_description_raw="${line#*- \[ \] }"
        # Use sed to remove ONLY the time pattern, keeping any text that follows it.
        # Use xargs to aggressively trim leading/trailing whitespace, including non-breaking spaces
        routine_description_final=$(echo "$routine_description_raw" | sed -E 's/\s*([0-9]{2}:[0-9]{2})\s*-\s*([0-9]{2}:[0-9]{2})\s*//' | xargs)

        # Extract hour and minute from start time
        start_hour=${start_time_str%:*}
        start_minute=${start_time_str#*:}

        # Extract hour and minute from end time
        end_hour=${end_time_str%:*}
        end_minute=${end_time_str#*:}

        # Convert start and end times to total minutes from midnight
        start_total_minutes=$((10#$start_hour * 60 + 10#$start_minute))
        end_total_minutes=$((10#$end_hour * 60 + 10#$end_minute))

        # Check if current time falls within the routine's time slot
        # This condition handles both normal and cross-midnight routines
        if (( current_total_minutes >= start_total_minutes && current_total_minutes < end_total_minutes )) || \
           ( (( end_total_minutes < start_total_minutes )) && \
             ( (current_total_minutes >= start_total_minutes) || (current_total_minutes < end_total_minutes) ) ) ; then

            # Add the trimmed routine's description and its line number to our array
            # Format: "LINE_NUMBER|ROUTINE_DESCRIPTION"
            matched_routines_with_lines+=("${line_num}|${routine_description_final}")
        fi
    fi
done < "$PLANNER_FILE"

# Initialize an array to store all tasks (action list items) from the matched routines
all_action_list_items=()
current_action_found="" # Initialize variable for the current action

# After looping through the entire file, process the matched routines to extract tasks
if [ ${#matched_routines_with_lines[@]} -gt 0 ]; then
    # Determine the appropriate header based on the number of routines found
    if [ ${#matched_routines_with_lines[@]} -eq 1 ]; then
        found_routine_header="🎯 YOUR CURRENT ROUTINE:"
    else
        found_routine_header="🎯 YOUR CURRENT ROUTINES:"
    fi

    # Print the routine header and each matched routine
    echo "$found_routine_header" | tee -a "$OUTPUT_FILE"
    echo "----------------------------------------" | tee -a "$OUTPUT_FILE"

    for routine_item_with_line in "${matched_routines_with_lines[@]}"; do
        IFS='|' read -r routine_line_num routine_description <<< "$routine_item_with_line"
        echo "✅ Routine: $routine_description" | tee -a "$OUTPUT_FILE"

        # Extract tasks using awk starting from the next line, looking for indented lines
        # This assumes tasks are indented relative to the routine line.
        # We look for lines starting with ' ' or '\t' after the routine line.
        routine_tasks=$(awk -v start_line="$routine_line_num" '
            NR > start_line && (/^[[:space:]]+- \[.\] / || /^[[:space:]]+-/ || /^[[:space:]]+\*/ || /^[[:space:]]+[0-9]+\./) {
                # Trim leading spaces/tabs but keep the original bullet/checkbox format
                task_line = $0;
                sub(/^[[:space:]]+/, "", task_line); # Remove leading spaces/tabs
                print task_line; # Print raw task, will be formatted later for "Consideration List"
                next;
            }
            NR > start_line && !(/^[[:space:]]+- \[.\] / || /^[[:space:]]+-/ || /^[[:space:]]+\*/ || /^[[:space:]]+[0-9]+\./) {
                # Stop if we hit an unindented line or a non-task line
                exit;
            }
        ' "$PLANNER_FILE")

        if [ -n "$routine_tasks" ]; then
            # Read tasks into the all_action_list_items array
            while IFS= read -r task; do
                all_action_list_items+=("$task")
            done <<< "$routine_tasks"
        fi
    done
    echo "" | tee -a "$OUTPUT_FILE" # Add a blank line for separation
else
    # No routines found for the current time
    echo "🎯 YOUR CURRENT ROUTINE:" | tee -a "$OUTPUT_FILE"
    echo "----------------------------------------" | tee -a "$OUTPUT_FILE"
    echo "❌ No routine currently scheduled." | tee -a "$OUTPUT_FILE"
    echo "" | tee -a "$OUTPUT_FILE" # Add a blank line for separation
fi

# Now process the all_action_list_items to find the #CurrentAction
for action_item in "${all_action_list_items[@]}"; do
    if [[ "$action_item" =~ \#CurrentAction ]]; then
        current_action_found="$action_item"
        break # Exit loop after finding the first #CurrentAction
    fi
done

# Print the "CONSIDERATION LIST" (Action List)
echo "📝 YOUR ACTION LIST:" | tee -a "$OUTPUT_FILE"
echo "----------------------------------------" | tee -a "$OUTPUT_FILE"

if [ ${#all_action_list_items[@]} -gt 0 ]; then
    for action_item in "${all_action_list_items[@]}"; do
        echo "    ➡️ $action_item" | tee -a "$OUTPUT_FILE"
    done
else
    if [ ${#matched_routines_with_lines[@]} -gt 0 ]; then
        echo "    (No specific action items listed for this routine.)" | tee -a "$OUTPUT_FILE"
    else
        echo "    (No active routines, so no action list items.)" | tee -a "$OUTPUT_FILE"
    fi
fi
echo "" | tee -a "$OUTPUT_FILE" # Add a blank line for separation

# Print the "CURRENT TASK" (renamed to "CURRENT ACTION")
echo "✨ YOUR CURRENT ACTION:" | tee -a "$OUTPUT_FILE"
echo "----------------------------------------" | tee -a "$OUTPUT_FILE"

if [ -n "$current_action_found" ]; then
    echo "    🔥 $current_action_found" | tee -a "$OUTPUT_FILE"
else
    echo "    (No current action identified with '#CurrentAction' tag.)" | tee -a "$OUTPUT_FILE"
fi
echo "--------------------------------------------------------" | tee -a "$OUTPUT_FILE"

# Final logging
echo "Script finished at $(date)" | tee -a "$OUTPUT_FILE"
echo "Output captured in: $(pwd)/$OUTPUT_FILE" | tee -a "$OUTPUT_FILE"
