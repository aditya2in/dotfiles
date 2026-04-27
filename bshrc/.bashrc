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

# --- [ 6. Auto-Start Tmux ] ---
if [[ -z "$TMUX" && $- == *i* ]]; then
    # Get the number of active sessions
    session_count=$(tmux ls 2>/dev/null | wc -l)

    if [ "$session_count" -eq 0 ]; then
        # No sessions? Create 'default' and jump in
        tmux new-session -s default
    elif [ "$session_count" -eq 1 ]; then
        # Exactly one session? Jump in automatically (even if renamed)
        tmux attach-session
    else
        # Multiple sessions? Show a menu (Most recent at the top)
        # We use fzf to let you pick instantly
        selected=$(tmux ls -F '#S' | fzf --height 40% --reverse --header="Select Tmux Workspace:" --prompt="⚡ ")
        if [ -n "$selected" ]; then
            tmux attach-session -t "$selected"
        else
            # If you hit ESC, just stay in the normal shell
            echo "Direct shell access (tmux avoided)."
        fi
    fi
fi
