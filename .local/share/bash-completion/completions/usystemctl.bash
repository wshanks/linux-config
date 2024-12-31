_usystemctl() {
    local cur prev words cword
    _init_completion || return

    COMPREPLY=()

    # Call the original _systemctl function with modified COMP_WORDS
    COMP_WORDS=("systemctl" "--user" "${COMP_WORDS[@]:1}")
    COMP_CWORD=$((COMP_CWORD + 1))
    _systemctl
}

if [[ -r /usr/share/bash-completion/completions/systemctl ]]; then
    . /usr/share/bash-completion/completions/systemctl
    complete -F _usystemctl usystemctl
fi
