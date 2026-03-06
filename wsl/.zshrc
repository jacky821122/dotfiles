export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Helper: print install hint for missing dependency (usage: _zshrc_hint "name" "install command")
_zshrc_hint() { echo "\033[33m[zshrc]\033[0m $1 not found. Install with:\n  \033[36m$2\033[0m" >&2; }

export ZSH="$HOME/.oh-my-zsh"

if [ -d "$ZSH" ]; then
    ZSH_THEME="bira"

    plugins=(git)
    _omz_custom="${ZSH_CUSTOM:-$ZSH/custom}"
    if [ -d "$_omz_custom/plugins/zsh-syntax-highlighting" ]; then
        plugins+=(zsh-syntax-highlighting)
    else
        _zshrc_hint "zsh-syntax-highlighting" \
            "git clone https://github.com/zsh-users/zsh-syntax-highlighting \${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
    fi
    if [ -d "$_omz_custom/plugins/zsh-completions" ]; then
        fpath+=$_omz_custom/plugins/zsh-completions/src
    else
        _zshrc_hint "zsh-completions" \
            "git clone https://github.com/zsh-users/zsh-completions \${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions"
    fi

    autoload -U compinit && compinit
    source "$ZSH/oh-my-zsh.sh"
else
    _zshrc_hint "oh-my-zsh" \
        'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
    autoload -U compinit && compinit
fi

# Conda
_conda_dir=""
for _d in "$HOME/.anaconda3" "$HOME/anaconda3" "$HOME/miniconda3"; do
    [ -d "$_d" ] && _conda_dir="$_d" && break
done

if [ -n "$_conda_dir" ]; then
    __conda_setup="$("$_conda_dir/bin/conda" 'shell.zsh' 'hook' 2>/dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        [ -f "$_conda_dir/etc/profile.d/conda.sh" ] && . "$_conda_dir/etc/profile.d/conda.sh" || export PATH="$_conda_dir/bin:$PATH"
    fi
    unset __conda_setup
    PROMPT=$(echo $PROMPT | sed 's/(base) //')
fi
unset _conda_dir _d

[ -f ~/.alias ] && source ~/.alias

[ -f "$HOME/google-cloud-sdk/path.zsh.inc" ] && . "$HOME/google-cloud-sdk/path.zsh.inc"
[ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ] && . "$HOME/google-cloud-sdk/completion.zsh.inc"

# Machine-specific overrides (not in dotfiles)
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
