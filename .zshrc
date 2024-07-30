eval "$(fnm env --use-on-cd)"
eval "$(zoxide init zsh)"

export PATH="$PATH:/Users/rohangodha/.cargo/bin/:/Users/rohangodha/.bun/bin:/Users/rohangodha/.sst/bin"
export GPG_TTY=$(tty)

alias cd="z"
alias ls="eza"
alias lg="lazygit"

if [ -f ~/dotfiles/.zsh-secrets ]; then
  source ~/dotfiles/.zsh-secrets
fi

function gc() {
  echo "pruning nix store"
  nix store gc
  echo "pruning pnpm store"
  pnpm store prune
}

function nixup() {
  nix profile upgrade dotfiles
}
