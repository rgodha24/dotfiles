fnm env --use-on-cd --shell fish | source
starship init fish | source
zoxide init fish | source
cryptenv init fish | source

# prefer things in nix-profile over default macos installs
set -x PATH "$HOME/.nix-profile/bin/" "/nix/var/nix/profiles/default/bin/" $PATH "$HOME/.cargo/bin/" "$HOME/.bun/bin/" "$HOME/.sst/bin/" "$HOME/.local/bin" "$HOME/go/bin" 

# starship transient prompt https://starship.rs/advanced-config/#transientprompt-and-transientrightprompt-in-fish
function starship_transient_prompt_func
  starship module character
end
enable_transience

set -x GPG_TTY "$(tty)"
set -x ANDROID_HOME "$HOME/Developer/Android/sdk/"
set -x fish_greeting ""
set -x EDITOR "$(which nvim)"

alias cd="z"
alias ls="eza"
alias lg="lazygit"
alias config="nvim ~/dotfiles/flake.nix && nixup"
alias where="which"
alias n="nvim ."
alias t="eza -T --git-ignore"

function gc 
  echo "pruning nix store"
  nix store gc
  echo "cleaning up home-manager generations"
  home-manager expire-generations "-7 days"
  echo "pruning pnpm store"
  pnpm store prune
  echo "pruning bun cache"
  bun pm cache rm -g
  echo "pruning uv cache"
  uv cache prune
end

function nixup
  nix profile upgrade dotfiles
end

# because `nix shell` doesn't work well with starship https://github.com/NixOS/nix/issues/6677
function shell
  set -x IN_NIX_SHELL "impure"
  set -x name $argv
  nix shell "nixpkgs#$argv[1]" $argv[2..]
  set -e IN_NIX_SHELL
  set -e name
end

function ai
  cryptenv run ai -- $argv
end

function circuitsim
  cd $HOME/Developer/
  java -jar "CS2110-CircuitSim.jar"
end
