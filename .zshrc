eval "$(fnm env --use-on-cd)"
eval "$(zoxide init zsh)"

export PATH="$PATH:/Users/rohangodha/.cargo/bin/:/Users/rohangodha/.bun/bin:/Users/rohangodha/.sst/bin"
export PATH="$PATH:/Applications/Sublime Text.app/Contents/SharedSupport/bin:/Users/rohangodha/.local/bin"
export GPG_TTY=$(tty)

export CLASSPATH=$(find ~/java-classes/ -name "*.jar" -type f -print0 | xargs -0 realpath | tr '\n' ':' | sed 's/:$//')
export CLASSPATH=".:$CLASSPATH"

alias cd="z"
alias ls="eza"
alias lg="lazygit"

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

function ros-shell() {
  nix develop ~/dotfiles/ros-shell/
}

_cryptenv_autoload_hook () {
  eval "$(cryptenv load)"
}
add-zsh-hook chpwd _cryptenv_autoload_hook

# workaround for creating a new shell in warp with Cmd + T not calling chpwd
eval $(cryptenv load)


. "$HOME/.cargo/env"
