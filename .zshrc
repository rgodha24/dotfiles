export PATH="$PATH:/Users/rohangodha/.cargo/bin/:/Users/rohangodha/.bun/bin:/Users/rohangodha/.sst/bin"
export PATH="$PATH:/Applications/Sublime Text.app/Contents/SharedSupport/bin:/Users/rohangodha/.local/bin"
. "$HOME/.cargo/env"

eval "$(fnm env --use-on-cd)"
eval "$(zoxide init zsh)"
eval "$(cryptenv init zsh)"

export GPG_TTY=$(tty)

export CLASSPATH=$(find ~/java-classes/ -name "*.jar" -type f -print0 | xargs -0 realpath | tr '\n' ':' | sed 's/:$//')
export CLASSPATH=".:$CLASSPATH"

export ANDROID_HOME="/Volumes/External/Android/sdk/"

alias cd="z"
alias ls="eza"
alias lg="lazygit"
alias config="nvim ~/dotfiles/flake.nix && nixup"

function gc() {
  echo "pruning nix store"
  nix store gc
  echo "pruning pnpm store"
  pnpm store prune
  echo "pruning bun cache"
  bun pm cache rm
}

function nixup() {
  nix profile upgrade dotfiles
}
