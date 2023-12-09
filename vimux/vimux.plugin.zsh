function start_vimux_session() {
  if [ $1"" = "" ]; then
    if [[ $VIMUX_WORKSPACE_DIR = "" ]]; then
      echo "Env VIMUX_WORKSPACE_DIR not defined. Using 'cwd'"
      VIMUX_WORKSPACE_DIR=$(pwd)
    fi
    echo "Looking for project folders in workspace: $VIMUX_WORKSPACE_DIR"
    choose_project=$(ls -altr $VIMUX_WORKSPACE_DIR | egrep -v "\.|total" | sed 's/.*:[0-9][0-9] //g' | fzf \
      --prompt="Select folder: " \
      --height 40% --border --margin 5%
    )
    session=$choose_project
  else
    session=$1
  fi
  if [ $session"" = "" ]; then
    echo "No project selected"
    return 0
  fi
  session_wd=$VIMUX_WORKSPACE_DIR/${session}
  if [ ! -d ${session_wd} ]; then
    echo "Working dir for session '$session' does not exist: $session_wd"
    exit 1
  fi
  existing=$(tmux ls -F "#{session_name}" | grep -e ^${session}$)
  if [ "$existing" = "${session}" ]; then
    echo "Session already active"
  else
    echo "Creating new session ${session}"
    pushd `pwd`
    cd $session_wd
    tmux new-session -s ${session} -n editor -d
    tmux split-window -v -t ${session}
    tmux resize-pane -t ${session}:1.1 -D 15
    tmux select-pane -t ${session}:1.1
  
    # detecting python venv
    venv=$(ls -l | grep venv | sed -r 's/(.*)(\ )(.*venv)/\3/g')
    if [[ $venv == "" ]]; then
      tmux send-keys -t ${session}:1.1 "vim" C-m
    else
      echo "Detected Python virtual env, $venv, activating it"
      tmux send-keys -t ${session}:1.1 "source ${venv}/bin/activate && vim" C-m
      tmux send-keys -t ${session}:1.2 "source ${venv}/bin/activate" C-m
    fi
    popd
  fi
}

function _start_vimux_session() {
  local -a commands
  if [[ $VIMUX_WORKSPACE_DIR = "" ]]; then
    VIMUX_WORKSPACE_DIR=$(pwd)
  fi
  commands=($(ls $VIMUX_WORKSPACE_DIR))

  if (( CURRENT == 2 )); then
        _describe -t commands 'commands' commands
  fi

  return 0
}
compdef _start_vimux_session start_vimux_session
zstyle '*:*:*:start_vimux_session:*' file-sort modification 
