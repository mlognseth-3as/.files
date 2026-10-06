# Dotfiles

## Setup

```bash
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- init --apply git@github.com:mlognseth-3as/.files.git
```

## Common commands

```bash
# Add/update a local file in chezmoi
chezmoi add ~/.zshrc

# Edit the chezmoi version
chezmoi edit ~/.zshrc

# See what chezmoi would change locally
chezmoi diff

# Apply changes
chezmoi apply

# Pull latest changes and apply
chezmoi update

# Open the dotfiles repo
chezmoi cd
```

Update Brewfile:

```bash
brew bundle dump --file="$HOME/Brewfile" --force
chezmoi add "$HOME/Brewfile"
```
