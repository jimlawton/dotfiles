# dotfiles

## What is this?

These are Jim's shell configuration dot files. The goal is to increase CLI
productivity on Linux (mainly Ubuntu) and OSX, though many scripts run just fine
on any POSIX implementation.

## Focus

The focus is on Zsh support. This used to work with Bash, but I switched and
don't support that any more.

## Inspirations

The contents of this repo are based on Matthew McCullough's [original](https://github.com/matthewmccullough/dotfiles).
Other bits have been added over the years.

## Acquiring This Repo

This project contains submodules. It is suggested that you clone this into your
home directory, as follows.

```bash
> cd ~
> git clone --recurse-submodules https://github.com/jimlawton/dotfiles
```

## Setup

Personalisation settings are in `personalisation`. Replace the values with your own.

There is a set up script that establishes the symlinks in your home directory.
Run this once.

```bash
> ~/dotfiles/_setupdotfiles.sh
```

> NOTE: Some of my personal configuration will remain after setup. You should fork and tweak to your specific needs.

## Non-automated, non-captured config

Reminder-to-self: Some additional personalization lives in the `~/.config/`
directory. Specifically, the `~/.config/gh/config.yml` file for [`gh`](https://cli.github.com).
It is not yet in scope for capture or copy, but some users have
[shared their configuration in a Gist](https://gist.github.com/vilmibm/a1b9a405ac0d5153c614c9c646e37d13).

## Contributions

Contributions are always welcome in the form of pull requests with explanatory comments.
