# dotfiles
[my][author-gh] dotfiles

1. [overview](#overview)
2. [restore](#restore)
3. [backup](#backup)
4. [test](#test)

## overview

dotfiles for:

- zed
- bash
- git 

## restore

```bash 
# clone repo at home directory
git clone <url> ~/.dotfiles
```

<details>
  <summary>installation script</summary>

  ```bash
  # homebrew #
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # symlinks #
  mkdir ~/.config/backups

  # bash_profile
  mv ~/.bash_profile  ~/.config/backups/.bash_profile
  ln -s ~/.dotfiles/.bash_profile ~/.bash_profile

  # git
  mv ~/.gitconfig  ~/.config/backups/.gitconfig
  mv ~/.gitignore_global  ~/.config/backups/.gitignore_global

  ln -s ~/.dotfiles/.gitconfig ~/.gitconfig
  ln -s ~/.dotfiles/.gitignore_global ~/.gitignore_global

  # zed
  mv ~/.config/zed  ~/.config/backups/zed
  ln -s ~/.dotfiles/.config/zed ~/.config

  # restore non-symlinked stuff (MacOS terminal, fonts  etc)
  restore
  ```

</details>

add the following at the top of `.bash_profile`

<details>
  <summary>bootstrap script</summary>

```bash
# custom

# git autompletions
if [ -f ~/.dotfiles/.git-completion.bash ]; then
  . ~/.dotfiles/.git-completion.bash
fi

# utility functions
source ~/.dotfiles/.ps1.bash
source ~/.dotfiles/.porcelain.bash
```
</details>


## backup

@todo

## test

install [bats][bats-core]

```bash
brew install bats-core
```


run them

```bash 
$ bats --verbose-run -r test
```

[testing guidelines](./test)

## license

[MIT-0][lic-mit-0]

<!-- Links -->
  
[author-gh]: https://github.com/nicholaswmin
[bats-core]: https://github.com/bats-core/bats-core
[lic-mit-0]: https://spdx.org/licenses/MIT-0.html
