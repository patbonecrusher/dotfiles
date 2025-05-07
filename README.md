# ![chezmoi logo](https://github.com/twpayne/chezmoi/blob/master/assets/images/logo-144px.svg) chezmoi dotfiles

Managing my dotfiles, securely using [chezmoi](https://chezmoi.io)

With chezmoi, I can install chezmoi and all my dotfiles on a new, empty machine
with a single command:

```console
$ sh -c "$(curl -fsLS git.io/chezmoi)" -- init --apply patbonecrusher
```

Updating my dotfiles on any machine can be done via single command:

```console
$ chezmoi update
```

and the responsible adult way should be:

```console
$ chezmoi source pull -- --rebase && chezmoi diff
```

If you're happy with the changes, run:

```console
$ chezmoi update
```