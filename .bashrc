# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

export PATH="${HOME}/.local/share/npm/bin:${PATH}"

# User specific aliases and functions
HISTFILESIZE=30000

# For screen?
if [[ $- =~ i ]]; then
    stty -ixon
fi

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
alias emacs-server='[[ -z $(pgrep -ax -u $UID emacs) ]] && emacs --chdir $HOME --daemon -l $HOME/.emacs.d/desktop_save.el'
alias emacsc='emacsclient -nw'
# fzf
if [ -f /usr/share/fzf/shell/key-bindings.bash ]; then
    source /usr/share/fzf/shell/key-bindings.bash
elif [ -f ~/.fzf.bash ]; then
    source ~/.fzf.bash
fi
export FZF_DEFAULT_COMMAND='ag -l -g ""'
is_in_git_repo() {
  git rev-parse HEAD > /dev/null 2>&1
}

fzf-down() {
  fzf --height 50% "$@" --border
}

gf() {
  is_in_git_repo || return
  git -c color.status=always status --short |
  fzf-down -m --ansi --nth 2..,.. \
    --preview '(git diff --color=always -- {-1} | sed 1,4d; cat {-1}) | head -500' |
  cut -c4- | sed 's/.* -> //'
}

gb() {
  is_in_git_repo || return
  git branch -a --color=always | grep -v '/HEAD\s' | sort |
  fzf-down --ansi --multi --tac --preview-window right:70% \
    --preview 'git log --oneline --graph --date=short --pretty="format:%C(auto)%cd %h%d %s" $(sed s/^..// <<< {} | cut -d" " -f1) | head -'$LINES |
  sed 's/^..//' | cut -d' ' -f1 |
  sed 's#^remotes/##'
}

gt() {
  is_in_git_repo || return
  git tag --sort -version:refname |
  fzf-down --multi --preview-window right:70% \
    --preview 'git show --color=always {} | head -'$LINES
}

gh() {
  is_in_git_repo || return
  git log --date=short --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)" --graph --color=always |
  fzf-down --ansi --no-sort --reverse --multi --bind 'ctrl-s:toggle-sort' \
    --header 'Press CTRL-S to toggle sort' \
    --preview 'grep -o "[a-f0-9]\{7,\}" <<< {} | xargs git show --color=always | head -'$LINES |
  grep -o "[a-f0-9]\{7,\}"
}

gr() {
  is_in_git_repo || return
  git remote -v | awk '{print $1 "\t" $2}' | uniq |
  fzf-down --tac \
    --preview 'git log --oneline --graph --date=short --pretty="format:%C(auto)%cd %h%d %s" {1} | head -200' |
  cut -d$'\t' -f1
}
if [[ $- =~ i ]]; then
    bind '"\er": redraw-current-line'
    bind '"\C-g\C-f": "$(gf)\e\C-e\er"'
    bind '"\C-g\C-b": "$(gb)\e\C-e\er"'
    bind '"\C-g\C-t": "$(gt)\e\C-e\er"'
    bind '"\C-g\C-h": "$(gh)\e\C-e\er"'
    bind '"\C-g\C-r": "$(gr)\e\C-e\er"'
fi
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
