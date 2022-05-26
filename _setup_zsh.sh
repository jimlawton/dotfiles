#!/bin/bash

if [ -d oh-my-zsh ]; then
    if [ ! -e oh-my-zsh/custom/override_window_title.zsh ]; then
        (cd oh-my-zsh/custom; ln -sf ../../override_window_title.zsh)
    fi
    if [ ! -e oh-my-zsh/custom/plugins/fast-syntax-highlighting ]; then
        (cd oh-my-zsh/custom/plugins; git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git)
    fi
    echo "Done!"
fi
