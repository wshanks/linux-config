# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# Usage: pathdrop PATTERN PATH_VARIABLE
#
# Drop any path in PATH_VARIABLE that matches the regular expression in
# PATTERN.
#
# PATTERN: a regular expression to match to the elements of a path variable
# PATH_VARIABLE: the name of the environment variable containing a path (i.e.
#                it is a string of `:` delimited paths, like PATH).
function pathdrop {
    # Input arguments
    local PATTERN=$1
    local PATH_VARIABLE=$2

    # Expand path variable into an array
    local path_array
    IFS=: read -ra path_array <<<"${!PATH_VARIABLE}"

    # Loop over array and remove any item matching pattern
    local item
    for item in ${!path_array[*]}; do
        if [[ "${path_array[$item]}" =~ $PATTERN ]]; then
            unset -v 'path_array['$item']'
        elif [ -z "${path_array[$item]}" ]; then
            unset -v 'path_array['$item']'
        fi
    done

    # Join modified array with `:` and re-export the path variable
    export $PATH_VARIABLE=$(IFS=: ; echo "${path_array[*]}")
}

# Usage: pathadd NEW_ITEM PATH_VARIABLE
#
# Add new item to the path environment variable. First the item is removed from
# the path if it is already present and then it is prepended to the path, so
# this operation is idempotent.
#
# NEW_ITEM: item to prepend to the path variable
# PATH_VARIABLE: name of the path environment variable to modify. This variable
#                should be a `:` delimited string of paths (e.g. the PATH
#                variable).
function pathadd {
    local NEW_ITEM=$1
    local PATH_VARIABLE=$2

    pathdrop ^"$NEW_ITEM"$ $PATH_VARIABLE
    if [ -z "${!PATH_VARIABLE}" ]; then
        export $PATH_VARIABLE="$NEW_ITEM"
    else
        export $PATH_VARIABLE="$NEW_ITEM:${!PATH_VARIABLE}"
    fi
}

pathadd "${HOME}/bin" PATH
pathadd "${HOME}/.local/share/npm/bin" PATH
pathadd "${HOME}/.local/bin" PATH


# User specific aliases and functions
HISTFILESIZE=30000

# For screen?
if [[ $- =~ i ]]; then
    stty -ixon
fi

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
__conda_setup="$("$HOME/.conda/bin/conda" 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    >&2 echo "Problem initializing conda"
fi
unset __conda_setup
if [ -f "$HOME/.conda/etc/profile.d/mamba.sh" ]; then
    . "$HOME/.conda/etc/profile.d/mamba.sh"
fi

# emacs
alias emacs-server='[[ -z $(pgrep -ax -u $UID emacs) ]] && emacs --chdir $HOME --daemon -l $HOME/.emacs.d/desktop_save.el'
alias emacsc='emacsclient -nw'
alias ktab="qdbus $KONSOLE_DBUS_SERVICE $KONSOLE_DBUS_WINDOW newSession"
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
# readline
export INPUTRC="$HOME"/.config/readline/inputrc
# yadm
[ -f /usr/share/doc/yadm/yadm.bash_completion ] && source /usr/share/doc/yadm/yadm.bash_completion
alias pyadm='yadm --yadm-dir "$HOME/.config/pyadm" --yadm-data "$HOME/.local/share/pyadm"'
if [ -z ${_yadm+x} ]; then
    complete -o bashdefault -o default -F _yadm pyadm 2>/dev/null \
        || complete -o default -F _yadm pyadm
fi
# gpg
export GPG_TTY=$(tty)

if [ -f "$HOME/.bashrc_local" ]; then
    . "$HOME/.bashrc_local"
fi
