#!/bin/bash

DOTFILESDIR=~/dotfiles
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

echo "Creating Terraform directory..."
mkdir -p ~/.terraform.d

popd

echo "Done!"
