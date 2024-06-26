#!/bin/bash

DOTFILESDIR=~/dotfiles
DOTFILES=".bash_logout .bash_profile .bashrc .Brewfile .colordiffrc .colorgccrc .gitconfig .gitignore .hammerspoon .inputrc .iterm2_shell_integration.zsh .p10k.zsh .profile .pythonrc .shellactivities .shellaliases .shellpaths .shellvars .terraformrc .tmux.conf .vimrc .xxdiffrc .zlogout .zprofile .zshenv .zshrc"
DOTDIRS=".vim"
DROPFILES="persistent_history"
DROPDIRS="bin .pip"
SAVEDIR=~/.old/_setupdotfiles

function symlinkifne {
	target=~/$1
	echo "Working on: $target"
	export dotless=`echo $1 | sed s/^\.//`
	if [ ! -e $DOTFILESDIR/$dotless ]; then
		# Check if platform-specific version exists.
		osname=$(uname)
		if [ "$osname" = "Darwin" ]; then
			platform="macos"
		elif [ "$osname" = "Linux" ]; then
			platform="linux"
		else
			echo "ERROR: unsupported OS $osname!"
			exit 1
		fi
		if [ -e $DOTFILESDIR/$dotless-$platform ]; then
			export dotless="$dotless-$platform"
		else
			echo "ERROR: file $DOTFILESDIR/$dotless does not exist, and has no platform-specific variant!"
			exit 1
		fi
	fi
	if [ -e $target ]; then
		if [ ! -L $target ]; then
			# If it's not a symlink, tread carefully.
			echo "  WARNING: $target already exists!"
			if [ "${MOVE:-false}" = "true" ]; then
				echo "  Moving $target to $SAVEDIR/"
				mv $target $SAVEDIR/
				dotless=$(echo $1 | sed s/.//)
				echo "  Symlinking $DOTFILESDIR/$dotless to $1"
				ln -s $DOTFILESDIR/$dotless $target
			else
				echo "  Skipping $1."
			fi
		else
			# Safe to just delete if it is a symlink (or if it doesn't exist).
			rm -f $target
			echo "  Symlinking $DOTFILESDIR/$dotless to $target"
			ln -s $DOTFILESDIR/$dotless $target
		fi
	else
		echo "  Symlinking $DOTFILESDIR/$dotless to $target"
		ln -s $DOTFILESDIR/$dotless $target
	fi
}

echo "This script must be run from the dotfiles directory"
echo "Setting up..."

pushd ~

if [ "${MOVE:-false}" = "true" -a -d $SAVEDIR ]; then
	echo "$SAVEDIR already exists! Please clean up and try again."
	echo "This is used to save old versions of your configuration files."
	exit 1
fi

mkdir -p $SAVEDIR

if [ ! -d dotfiles ]; then
	echo "The dotfiles directory does not exist in your home directory!"
	echo "You need to do:"
	echo "# cd ~"
	echo "# git clone --recurse-submodules https://github.com/jimlawton/dotfiles"
	echo "# cd dotfiles"
	echo "# ./_setupdotfiles.sh"
	exit 1
fi

for dotfile in $DOTFILES; do
	symlinkifne $dotfile
done

for dotdir in $DOTDIRS; do
	symlinkifne $dotdir
done

# Any directories you want linked from Dropbox.
if [ -e ~/Dropbox/ ]; then
    for dropdir in $DROPDIRS; do
        if [ ! -e ~/$dropdir ]; then
            ln -s ~/Dropbox/unixhome/$dropdir ~/
        fi
    done
fi

# Any files you want linked from Dropbox.
if [ -e ~/Dropbox/ ]; then
    for dropfile in $DROPFILES; do
        if [ ! -e ~/$dropfile ]; then
            ln -s ~/Dropbox/$dropfile ~/.$dropfile
        fi
    done
fi

mkdir -p ~/.config
ln -sf ~/dotfiles/hyper-hacks/karabiner ~/.config/karabiner

mkdir -p ~/.terraform.d

popd

echo "Done!"
