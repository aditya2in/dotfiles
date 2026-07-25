#!/bin/bash
# Load DeepSeek API key
if [ -f ~/.config/deepseek/env ]; then
    source ~/.config/deepseek/env
else
    echo "Warning: ~/.config/deepseek/env not found."
fi

# Run the voice chat script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python "$SCRIPT_DIR/voice_chat.py"
