# ==========================================================
# 🚀 BASH ULTIMATE CONFIGURATION (Stable & Clean)
# ==========================================================

# --- [ 1. Omarchy Dynamic Sync ] ---
# Loads the official developer magic
[[ -f ~/.local/share/omarchy/default/bash/rc ]] && source ~/.local/share/omarchy/default/bash/rc

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
alias gs="git status"
alias ga="git add ."
alias gc="git commit -v" 
alias gp="git push origin new"
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
    # Create a new session with the config file explicitly loaded if it doesn't exist
    tmux has-session -t default 2>/dev/null || tmux -f ~/.tmux.conf new-session -d -s default
    tmux attach-session -t default
fi
