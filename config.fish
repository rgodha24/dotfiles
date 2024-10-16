set -x PATH $PATH "$HOME/.cargo/bin/" "$HOME/.bun/bin/" "$HOME/.sst/bin/" "$HOME/.local/bin" "$HOME/.nix-profile/bin/" "/nix/var/nix/profiles/default/bin/"

fnm env --use-on-cd --shell fish | source
starship init fish | source
cryptenv init fish | source
zoxide init fish | source

# starship transient prompt https://starship.rs/advanced-config/#transientprompt-and-transientrightprompt-in-fish
function starship_transient_prompt_func
  starship module character
end
enable_transience

set -lx GPG_TTY "$(tty)"
set -lx CLASSPATH "$(find ~/java-classes/ -name "*.jar" -type f -print0 | xargs -0 realpath | tr '\n' ':' | sed 's/:$//'):."
set -lx ANDROID_HOME "/Volumes/External/Android/sdk/"
set -x fish_greeting ""

# kitty integration
if set -q KITTY_INSTALLATION_DIR
    set --global KITTY_SHELL_INTEGRATION enabled
    source "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_conf.d/kitty-shell-integration.fish"
    set --prepend fish_complete_path "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_completions.d"
end

alias cd="z"
alias ls="eza"
alias lg="lazygit"
alias config="nvim ~/dotfiles/flake.nix && nixup"
alias where="which"

function gc 
  echo "pruning nix store"
  nix store gc
  echo "pruning pnpm store"
  pnpm store prune
  echo "pruning bun cache"
  bun pm cache rm
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
