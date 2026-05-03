# dots

Personal dotfiles, managed with [yadm](https://yadm.io).

## Bootstrap

On a fresh machine, place your git-crypt key at `$HOME/.git-crypt`, then run:

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/lonetis/dots/main/.init.sh)"
```

If you don't have the key yet, export it from a machine where the repo is already unlocked:

```sh
yadm git-crypt export-key ~/.git-crypt
```
