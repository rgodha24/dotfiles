# my main shell is zsh, but when using nix develop, it automatically uses bash...

eval "$(zoxide init bash)"

printf '\eP$f{"hook": "SourcedRcFileForWarp", "value": { "shell": "bash"}}\x9c'

alias cd="z"
alias ls="eza"
alias lg="lazygit"

ros-shell () {
  echo "Already in the ROS Shell"
}
