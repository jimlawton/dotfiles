{{ if eq .chezmoi.os "darwin" -}}
#!/bin/bash

if ! command -v pyenv &> /dev/null
then
    echo "pyenv could not be found, installing pyenv..."

    brew update
    brew install pyenv

    # Initialize pyenv in the current shell session
    if command -v pyenv &> /dev/null
    then
        echo "pyenv installed successfully."
        eval "$(pyenv init --path)"
        eval "$(pyenv init -)"
    else
        echo "Failed to install pyenv."
        exit 1
    fi
else
    echo "pyenv is already installed."
fi

pyenv install 3.13
pyenv global 3.13

{{ end -}}
