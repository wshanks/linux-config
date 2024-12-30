#!/bin/bash

# Add the default pixi environment to the path, assuming they are stored
# detached in ~/.conda/envs
function add_pixipath() {
    local project="$(basename "${PWD}")"
    local pixienvs="${HOME}/.conda/envs"
    for pixibinpath in ${pixienvs}/*/envs/default/bin/; do
        pixibinpath="${pixibinpath%*/}"  # Remove trailing /
        envname="${pixibinpath%*/envs/default/bin}"  # Remove trailing /envs/default/bin
        envname="${envname##*/}"  # Remove everything before final /
        if [[ $envname =~ ^"$project"-.*$ ]]; then
            PATH_add "$pixibinpath"
            break
        fi
    done
}
