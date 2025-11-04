# dotfiles

This repository is meant to manage and configure a personalised dev env setup for MacOS/Linux.

This primarily uses [chezmoi](https://www.chezmoi.io/) to manage dotfiles and a combination of [mise](https://mise.jdx.dev/) and Homebrew to manage package installations.

## Structure

Packages are contained within .chezmoidata/packages.yaml

These are installed whenever the packages.yaml has changed and a `chezmoi apply` is run

## Usage

### Install XCode Command Line Tools if necessary
```
xcode-select --install
```

### Install homebrew
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Install chezmoi
```
brew install chezmoi
```

### Clone the repo and apply the dotfiles
```
chezmoi init https://github.com/jimlawton/dotfiles
```

> [!IMPORTANT]
> Update .chezmoidata/identity.yaml with your personal details

```
chezmoi apply
```

## Acquiring This Repo

This project contains submodules. It is suggested that you clone this into your
home directory, as follows.

```bash
> cd ~
> git clone --recurse-submodules https://github.com/jimlawton/dotfiles
```

## Setup

There is a set up script that establishes the symlinks in your home directory.
If necessary, you can run this:

```bash
> ~/dotfiles/_setupdotfiles.sh
```
