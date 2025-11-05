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

chezmoi apply
```
