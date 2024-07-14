eval "$(fnm env --use-on-cd)"
eval "$(zoxide init zsh)"

alias cd="z"

function gc() {
  echo "pruning nix store"
  nix store gc
  echo "pruning pnpm store"
  pnpm store prune
}

function nixup() {
  nix profile upgrade dotfiles
}
