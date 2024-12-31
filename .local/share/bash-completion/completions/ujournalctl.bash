_ujournalctl() {
    local cur prev words cword
    _init_completion || return

    if [[ $prev == "--unit" || $prev == "-u" ]]; then
        comps=$(journalctl -F '_SYSTEMD_USER_UNIT' 2>/dev/null)
        COMPREPLY=( $(compgen -o filenames -W '$comps' -- "$cur") )
        return 0
    fi

    COMPREPLY=()

    # Call the original _journalctl function with modified COMP_WORDS
    COMP_WORDS=("journalctl" "--user" "${COMP_WORDS[@]:1}")
    COMP_CWORD=$((COMP_CWORD + 1))
    _journalctl
}

if [[ -r /usr/share/bash-completion/completions/journalctl ]]; then
    . /usr/share/bash-completion/completions/journalctl
    complete -F _ujournalctl ujournalctl
fi
