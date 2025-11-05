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

## Encrypted Files

Some files in this repo are encrypted. This is a good [page](https://www.chezmoi.io/user-guide/frequently-asked-questions/encryption/) that describes managing encrypted files in `chezmoi`.

The general sequence is:

- Use `chezmoi age-keygen` to generate a public/private key pair.
  - The public key is a long string sth like `"age193wd0hfuhtjfsunlq3c83s8m93pde442dkcn7lmj3lspeekm9g7stwutrl"`. This is NOT a secret.
  - The private key is a long string sth like `"AGE-SECRET-KEY-<REDACTED>"`. This IS a secret.
- Use `chezmoi age encrypt` to produce an encrypted private key file, using a passphrase. The encrypted key file is NOT a secret. However, the passphrase IS a secret.
- The FAQ says do this: `chezmoi age-keygen | chezmoi age encrypt --passphrase --output=key.txt.age`, however that never prints the  public key, which you need, so do it in 2 steps:
  - `chezmoi age-keygen -o identity.txt`
  - `cat identity.txt | chezmoi age encrypt --passphrase --output=key.txt.age`
- Add `key.txt.age` to `.chezmoiignore`  so chezmoi doesn't try to manage it.
- Don't leave `identity.txt` lying around, don't check it into Git and don't let chezmoi get its hands on it. Add it to `.gitignore` and `.chezmoiignore` for safety.
- Next, in your `.chezmoi.toml.tmpl` you'll need:

```
{{ $passphrase := promptStringOnce . "passphrase" "Chezmoi passphrase" -}}

encryption = "age"
[age]
    identity = "~/.config/chezmoi/key.txt"
    recipient = "<YOUR-AGE-PUBLIC-KEY-GOES-HERE"
```

- In chezmoi, add `run_onchange_before_decrypt-private-key.sh.tmpl`, with:

```
#!/bin/sh

if [ ! -f "${HOME}/.config/chezmoi/key.txt" ]; then
    mkdir -p "${HOME}/.config/chezmoi"
    chezmoi age decrypt --output "${HOME}/.config/chezmoi/key.txt" --passphrase "{{ .chezmoi.sourceDir }}/key.txt.age"
    chmod 600 "${HOME}/.config/chezmoi/key.txt"
fi
```

- Add/commit `.chezmoi.toml.tmpl`, `.chezmoiignore`,  `key.txt.age`, `run_onchange_before_decrypt-private-key.sh.tmpl`  to Git.
- Finally: `chezmoi init --apply`
- Now, when you want to add files that should be stored encrypted in Git, you do: `chezmoi add --encrypt ~/.some-sensitive-file`.
- When you run `chezmoi init` on a new machine you will be prompted to enter your passphrase once to decrypt `key.txt.age`. 
- Your decrypted private key will be stored on the target machine in `~/.config/chezmoi/key.txt`

## Git Identity Files

There are 2 encrypted Git identity files managed and used by this repo:
- `~/.gitidentity-personal` - for personal Git activity
- `~/.gitidentity-work` - for work Git activity

Each of these files is of the following form:

```
[user]
    name = John Doe
    email = john.doe@example.com
```
