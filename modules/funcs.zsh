#!/usr/bin/env zsh

minimal_import_env(){
  echo "${1}" | while IFS='=' read -r name value ; do
    eval "export ${name}=${value}"
  done
}

minimal_render_vi_mode(){
  MINIMAL_VI_PROMPT="$(minimal_vi_prompt)"
  export MINIMAL_VI_PROMPT
}

minimal_vi_prompt(){
  case ${KEYMAP} in
    (vicmd)      echo -n "$(minimal_prompt_symbol_nml)" ;;
    (main|viins) echo -n "$(minimal_prompt_symbol_ins)" ;;
  esac
}

minimal-accept-line () {
    export TIMER=$(date +%s)
    zle accept-line
}

minimal_prompt_symbol_ins(){
  echo -ne "%F{8}%K{7}  INS  %k%f"
}

minimal_prompt_symbol_nml(){
  echo -ne "%F{15}%K{1}  CMD  %k%f"
}

minimal_git_left_right(){
  __git_left_right=$(plib_git_left_right)

  __pull=$(echo "$__git_left_right" | awk '{print $2}' | tr -d ' \n')
  __push=$(echo "$__git_left_right" | awk '{print $1}' | tr -d ' \n')

  [[ "$__pull" != 0 ]] && [[ "$__pull" != '' ]] && __pushpull="${__pull}${MINIMAL_GIT_PULL_SYM}"
  [[ -n "$__pushpull" ]] && __pushpull+=' '
  [[ "$__push" != 0 ]] && [[ "$__push" != '' ]] && __pushpull+="${__push}${MINIMAL_GIT_PUSH_SYM}"

  if [[ "$__pushpull" != '' ]]; then
    echo -n "${__pushpull}"
  fi
}

prompt(){
  export VIRTUAL_ENV=$1
  prompt_std=""
  venv=$(plib_venv)
  hostname=$(hostname)
  if [[ -v venv ]] && prompt_std+="%F{$MINIMAL_FADE_COLOR}${venv}%f "
  prompt_std+="%f%F{$MINIMAL_FADE_COLOR}%~%f  "
  prompt_vi='${MINIMAL_VI_PROMPT} '"${prompt_std}"

  echo -n "${prompt_vi}"
}

git_prompt(){
  cd $1
  git_prompt_val=""
  if [[ $(plib_is_git) == 1 ]]; then
    git_prompt_val+="%F{$MINIMAL_FADE_COLOR}[%f "
    git_prompt_val+="%F{foreground}$(plib_git_branch)%f"

    git_status=$(plib_git_status)

    mod_st=$(plib_git_staged_mod "$git_status")
    add_st=$(plib_git_staged_add "$git_status")
    del_st=$(plib_git_staged_del "$git_status")
  
    mod_ut=$(plib_git_unstaged_mod "$git_status")
    add_ut=$(plib_git_unstaged_add "$git_status")
    del_ut=$(plib_git_unstaged_del "$git_status")

    new=$(plib_git_status_new "$git_status")

    [[ mod_st -gt 0 || add_st -gt 0 || del_st -gt 0 ]] && git_prompt_val+=" %F{foreground}${MINIMAL_GIT_STAGE_SYM}%f"
    [[ mod_ut -gt 0 || add_ut -gt 0 || del_ut -gt 0 || new -gt 0 ]] && git_prompt_val+=" %F{foreground}${MINIMAL_GIT_UNSTAGE_SYM}%f"
    [[ $(plib_git_stash) -gt 0 ]] && git_prompt_val+=" ${MINIMAL_GIT_STASH_SYM}"
    [[ ! -z $(minimal_git_left_right) ]] && git_prompt_val+=" %F{red}$(minimal_git_left_right)%f"
    git_prompt_val+=" %F{$MINIMAL_FADE_COLOR}]%f "
  fi
  cd ~
  echo -n ${git_prompt_val}
}

prompt_length(){
  emulate -L zsh
  local COLUMNS=${2:-$COLUMNS}
  local -i x y=$#1 m
  if (( y )); then
    while (( ${${(%):-$1%$y(l.1.0)}[-1]} )); do
      x=y
      (( y *= 2 ));
    done
    local xy
    while (( y > x + 1 )); do
      m=$(( x + (y - x) / 2 ))
      typeset ${${(%):-$1%$m(l.x.y)}[-1]}=$m
    done
  fi
  echo $x
}

s_humanized(){
  local human total_seconds=$1
  local days=$(( total_seconds / 60 / 60 / 24 ))
  local hours=$(( total_seconds / 60 / 60 % 24 ))
  local minutes=$(( total_seconds / 60 % 60 ))
  local seconds=$(( total_seconds % 60 ))

  (( days > 0 )) && human+="${days}d "
  (( hours > 0 )) && human+="${hours}h "
  (( minutes > 0 )) && human+="${minutes}m "
  human+="${seconds}s"

  echo "$human"
}

rprompt(){
  background=$(rprompt_background_jobs $2)
  exit_code=$(rprompt_exit_code)
  execution_time=$(rprompt_execution_time $1)

  echo -n ${background}${execution_time}${exit_code}
}

rprompt_execution_time(){
  started=$1
  now=$(date +%s)
  elapsed=$((now-started))
  if [[ elapsed -ge 5 ]] && echo -ne "%F{8}%K{7} $(s_humanized ${elapsed}) %k%f"
}

rprompt_exit_code(){
  echo -n "%(?..%F{15}%K{1} %? %k%f)"
}

rprompt_background_jobs(){
  n_processes=$1
  if [[ $n_processes -gt 0 ]] &&  echo -n "%F{8}%K{7} ${n_processes}${MINIMAL_BACKGROUND_JOB_SYM} %k%f"
}

prompt_reset(){
  unset PROMPT
  RPROMPT=''
  
  unset VERSION_PROMPT
  unset ENVVAR_PROMPT
  unset GIT_PROMPT
  unset LPROMPT
}

version_prompt(){
  version_prompt_val=""

  minimal_import_env $2

  if [[ -n ${@} ]]; then
    local LOOP_INDEX=0
    for _v in $(echo "${1}"); do
      [[ ${LOOP_INDEX} != "0" ]] && version_prompt_val+="%F{$MINIMAL_FADE_COLOR}${MINIMAL_PROMPT_SEP}%f"
      [[ ${LOOP_INDEX} == "0" ]] && LOOP_INDEX=$((LOOP_INDEX + 1)) && version_prompt_val+="%F{$MINIMAL_FADE_COLOR}[%f"

      [[ ${_v} == "PYTHON" ]]    && version_prompt_val+="${MINIMAL_PY_SYM}$(plib_pyenv_major_version):$(plib_python_version)"
      [[ ${_v} == "RUBY" ]]      && version_prompt_val+="${MINIMAL_RB_SYM}$(plib_rbenv_major_version):$(plib_ruby_version)"
      [[ ${_v} == "JAVA" ]]      && version_prompt_val+="${MINIMAL_JAVA_SYM}$(plib_java_version)"
      [[ ${_v} == "GO" ]]        && version_prompt_val+="${MINIMAL_GO_SYM}$(plib_go_version)"
      [[ ${_v} == "ELIXIR" ]]    && version_prompt_val+="${MINIMAL_ELIXIR_SYM}$(plib_elixir_version)"
      [[ ${_v} == "CRYSTAL" ]]   && version_prompt_val+="${MINIMAL_CRYSTAL_SYM}$(plib_crystal_version)"
      [[ ${_v} == "NODE" ]]      && version_prompt_val+="${MINIMAL_NODE_SYM}$(plib_node_version)"
      [[ ${_v} == "PHP" ]]       && version_prompt_val+="${MINIMAL_PHP_SYM}$(plib_php_version)"
    done

    [[ "$LOOP_INDEX" != "0" ]] && version_prompt_val+="%F{$MINIMAL_FADE_COLOR}]%f"
  fi
  echo -n ${version_prompt_val}
}

envvar_prompt(){
  array=( $@ )
  len=${array[-1]}
  _names=(${array[@]:0:$len})
  _values=(${array[@]:$len:-1})

  envvar_prompt_val=""
  if [[ -n ${_names} ]]; then
    local LOOP_INDEX=0
    for _var in $(echo "${_names}"); do
      [[ ${LOOP_INDEX} != "0" ]] && envvar_prompt_val+="%F{$MINIMAL_FADE_COLOR}${MINIMAL_PROMPT_SEP}%f"
      [[ ${LOOP_INDEX} == "0" ]] && LOOP_INDEX=$((LOOP_INDEX + 1)) && envvar_prompt_val+="%F{$MINIMAL_FADE_COLOR}[%f"
      [[ ${_var} != "" ]] && envvar_prompt_val+="${_var}:${_values[$LOOP_INDEX]}" && LOOP_INDEX=$((LOOP_INDEX + 1))
    done
    [[ "$LOOP_INDEX" != "0" ]] && envvar_prompt_val+="%F{$MINIMAL_FADE_COLOR}]%f"
  fi
  echo -n ${envvar_prompt_val}
}

set_prompt(){
  ASYNC_COUNTER=$(($ASYNC_COUNTER + 1))

  case $1 in
    rprompt*)
      RPROMPT=$3
      ;;
    version_prompt)
      VERSION_PROMPT=$3
      ;;
    envvar_prompt)
      ENVVAR_PROMPT=$3
      ;;
    git_prompt)
      GIT_PROMPT=$3
      ;;
    prompt)
      PROMPT=$3
      zle && zle .reset-prompt
      ;;
  esac

  escaped_prompt="$(prompt_length "${VERSION_PROMPT}${ENVVAR_PROMPT}}")"
  escaped_git="$(prompt_length "${GIT_PROMPT}")"
  right_width=$(($COLUMNS-$escaped_git-$escaped_prompt))

  prompt_info=${VERSION_PROMPT}${ENVVAR_PROMPT}${(l:$right_width:: :)}${GIT_PROMPT}

  if [[ $ASYNC_COUNTER == 5 ]]; then
    PROMPT=$prompt_info$'\n'$PROMPT
    zle && zle .reset-prompt
    async_stop_worker "minimal_renderer"
  fi
}

reset_timer(){
  TIMER=$(date +%s)
}