#!/usr/bin/env zsh

function this-script-dir {
    echo "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
}

# Watch and compile the source directory
coffee --output "$(this-script-dir)/Mousetile/" --bare --watch --compile "$(this-script-dir)/src/"
