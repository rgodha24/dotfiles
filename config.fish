# prefer things in nix-profile over default installs
set -l path_extra "$HOME/.cargo/bin/" "$HOME/.bun/bin/" "$HOME/.sst/bin/" "$HOME/.local/bin" "$HOME/go/bin"
if test (uname) = "Darwin"
  set -a path_extra "/Applications/Tailscale.app/Contents/MacOS/"
end
set -x PATH "$HOME/.nix-profile/bin/" "/nix/var/nix/profiles/default/bin/" $PATH $path_extra

fnm env --use-on-cd --shell fish | source
starship init fish | source
zoxide init fish | source
if type -q cryptenv
  cryptenv init fish | source
end

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
if test (uname) = "Linux"
  alias reboot-windows='sudo bootctl set-oneshot auto-windows && sudo reboot'
end

function gc 
  echo "pruning nix store"
  nix store gc
  if type -q home-manager
    echo "cleaning up home-manager generations"
    home-manager expire-generations "-7 days"
  end
  echo "pruning pnpm store"
  pnpm store prune
  echo "pruning bun cache"
  bun pm cache rm -g
  echo "pruning uv cache"
  uv cache prune
end

function nixup
  if test (uname) = "Darwin"
    home-manager switch --flake ~/dotfiles#mac
  else
    sudo nixos-rebuild switch --flake ~/dotfiles#nixos
  end
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

function oc 
  cryptenv run ai -- opencode $argv
end

# worktrunk shell integration:
function wt
  set -l WORKTRUNK_BIN (type -P wt)
  set -l directive_file (mktemp)

  WORKTRUNK_DIRECTIVE_FILE=$directive_file command $WORKTRUNK_BIN $argv
  set -l exit_code $status

  if test -s "$directive_file"
    eval (cat "$directive_file" | string collect)
    if test $exit_code -eq 0
      set exit_code $status
    end
  end

  rm -F "$directive_file"
  return $exit_code
end
