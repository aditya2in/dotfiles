# ==========================================================
# 🚀 BASH ULTIMATE CONFIGURATION (Stable & Clean)
# ==========================================================

# Clear conflicting alias BEFORE loading system functions
unalias ga 2>/dev/null

# --- [ 1. Omarchy Dynamic Sync ] ---
# Loads the official developer magic
[[ -f ~/.local/share/omarchy/default/bash/rc ]] && source ~/.local/share/omarchy/default/bash/rc

# Rename system 'ga' to 'gwt' and reclaim 'ga' for Git Add
alias gwt=ga
unalias ga 2>/dev/null

# --- [ 2. Starship Theme (Clean 2-Line) ] ---
eval "$(starship init bash)"

# --- [ 3. FZF (Ultra-Fast Fuzzy Finder) ] ---
# Hit Ctrl+R to search history, Ctrl+T to find files
if command -v fzf &> /dev/null; then
    [[ -f /usr/share/fzf/completion.bash ]] && source /usr/share/fzf/completion.bash
    [[ -f /usr/share/fzf/key-bindings.bash ]] && source /usr/share/fzf/key-bindings.bash
fi

# --- [ 4. Kubernetes (K8s) Shortcuts ] ---
alias k='kubectl'
if command -v kubectl &> /dev/null; then
    source <(kubectl completion bash)
fi

# --- [ 5. Custom Aliases & Exports ] ---
export EDITOR="nvim"
export VISUAL="nvim"

alias c="clear"
alias e="exit"

# GitHub Essentials
alias gs="git status"
alias ga="git add ."
alias gc="git commit -v"
alias gp='git push origin $(git branch --show-current)'
alias gr="git remote -v"

# Claude Code / Ollama
export ANTHROPIC_AUTH_TOKEN=ollama
export ANTHROPIC_API_KEY=""
export ANTHROPIC_BASE_URL=http://localhost:11434
alias claude-qwen='ollama launch claude --model qwen3.5:9b'

# Load local bin environment
[[ -f "$HOME/.local/share/../bin/env" ]] && . "$HOME/.local/share/../bin/env"

# Added by Hugging Face CLI installer
export PATH="/home/adityaws/.local/bin:$PATH"



export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

# --- [ 6. Smart Tmux Launcher ] ---
if [[ -z "$TMUX" && $- == *i* ]]; then
    # Get session names and prepend a "NEW SESSION" option
    sessions=$(tmux ls -F '#S' 2>/dev/null)
    
    if [ -z "$sessions" ]; then
        # No sessions? Just start a default one
        tmux new-session -s default
    else
        # Show menu with existing sessions + option for a new one
        selection=$(echo -e "++ NEW SESSION ++\n$sessions" | fzf --height 40% --reverse --header="Select Tmux Workspace:" --prompt="⚡ ")

        case "$selection" in
            "++ NEW SESSION ++")
                # Ask for a name, or default to a timestamp if empty
                read -p "Session Name: " session_name
                tmux new-session -s "${session_name:-$(date +%Y%m%d_%H%M%S)}"
                ;;
            "")
                # If ESC is pressed, just stay in the normal shell
                echo "Direct shell access (tmux avoided)."
                ;;
            *)
                # Attach to the selected session
                tmux attach-session -t "$selection"
                ;;
        esac
    fi
fi
