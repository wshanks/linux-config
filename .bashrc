# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific aliases and functions
HISTFILESIZE=30000

# For screen?
stty -ixon

# Why did I need this?
# XDG_DATA_DIR=$XDG_DATA_DIR:$HOME/.local/share

# git bash prompt
GIT_PS1_SHOWDIRTYSTATE=1
GIT_PS1_SHOWSTASHSTATE=1
GIT_PS1_SHOWUNTRACKEDFILES=1
GIT_PS1_SHOWUPSTREAM=verbose
GIT_PS1_SHOWCOLORHINTS=1
source /usr/share/git-core/contrib/completion/git-prompt.sh
CLEAN_PS1="$PS1"
__my_git_ps1 ()
{
    local g
    if [ -z ${__gitdir+x} ]; then
        g="$(git rev-parse --git-dir --is-inside-git-dir \
             --is-bare-repository --is-inside-work-tree \
             --short HEAD 2>/dev/null)"
    else
        g="$(__gitdir)"
    fi
    if [ -z "$g" ] ||
       [ "$(git config --bool bash.hideGitPrompt)" == "true" ]
    then
        PS1="$CLEAN_PS1"
    else
        if [ "$(git config --bool bash.hideGitPrompt)" != "true" ]; then
            __git_ps1 "\w " "\n$(date '+%R') \\\$ "
        fi
    fi
}
PROMPT_COMMAND='__my_git_ps1'

# autojump
source /etc/profile.d/autojump.sh
# conda
[ -f ~/conda/etc/profile.d/conda.sh ] && source ~/conda/etc/profile.d/conda.sh
# emacs
alias emacs-server='[ -z $(pgrep -ax -u $UID emacs) ] && emacs --chdir $HOME --daemon -l $HOME/.emacs.d/desktop_save.el'
alias emacsc='emacsclient -nw'
# fzf
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
# git
alias gdiff='git difftool -t vimdiff'
# git-annex
alias ga='git-annex'
complete -o bashdefault -o default -o filenames -F _git-annex ga
# readline
export INPUTRC="$HOME"/.config/readline/inputrc
# yadm
[ -f /usr/share/doc/yadm/yadm.bash_completion ] && source /usr/share/doc/yadm/yadm.bash_completion
alias pyadm='yadm --yadm-dir "$HOME/.pyadm"'
if [ -z ${_yadm+x} ]; then
    complete -o bashdefault -o default -F _yadm pyadm 2>/dev/null \
        || complete -o default -F _yadm pyadm
fi

if [ -f "$HOME/.bashrc_local" ]; then
    . "$HOME/.bashrc_local"
fi
