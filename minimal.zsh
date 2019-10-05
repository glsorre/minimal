#!/usr/bin/env zsh

MINIMAL_PROMPT_SYMBOL=❱
MINIMAL_FADE_COLOR=black
MINIMAL_PROMPT_SEP="|"
MINIMAL_GIT_STASH_SYM='@'
MINIMAL_ENABLE_VI_PROMPT=1
MINIMAL_SPACE_PROMPT=1

THEME_ROOT=${0:A:h}
source "${THEME_ROOT}/libs/promptlib/activate"

minimal_prompt_symbol_ins(){
  echo -ne %F{green}%B%S  INS  %s%b%f
}

minimal_prompt_symbol_nml(){
  echo -ne %F{red}%B%S  CMD  %s%b%f
}

function zle-line-init {
  minimal_render_vi_mode
  zle && zle reset-prompt
}

function zle-keymap-select {
  minimal_render_vi_mode
  zle && zle reset-prompt
}

minimal_render_vi_mode(){
  export MINIMAL_VI_PROMPT="$(minimal_vi_prompt)"
}

minimal_vi_prompt(){
  case "${KEYMAP}" in
    vicmd)
      echo -n "$(minimal_prompt_symbol_nml)"
      ;;
    main|viins)
      echo -n "$(minimal_prompt_symbol_ins)"
      ;;
  esac
}

zle -N zle-line-init
zle -N zle-keymap-select

export KEYTIMEOUT=1

minimal_git_left_right(){
  [[ -z "${AM_GIT_PUSH_SYM}" ]] && AM_GIT_PUSH_SYM='↑'
  [[ -z "${AM_GIT_PULL_SYM}" ]] && AM_GIT_PULL_SYM='↓'

  __git_left_right=$(plib_git_left_right)

  __pull=$(echo "$__git_left_right" | awk '{print $2}' | tr -d ' \n')
  __push=$(echo "$__git_left_right" | awk '{print $1}' | tr -d ' \n')

  [[ "$__pull" != 0 ]] && [[ "$__pull" != '' ]] && __pushpull="${__pull}${AM_GIT_PULL_SYM}"
  [[ -n "$__pushpull" ]] && __pushpull+=' '
  [[ "$__push" != 0 ]] && [[ "$__push" != '' ]] && __pushpull+="${__push}${AM_GIT_PUSH_SYM}"

  if [[ "$__pushpull" != '' ]]; then
    echo -ne "%F{$AM_LEFT_RIGHT_COLOR}${__pushpull}%f"
  fi
}

prompt_reset(){
  PROMPT=""
}

if [[ ${precmd_functions[(ie)prompt_reset]} -le ${#precmd_functions} ]]; then
    echo version_prompt already loaded
else
    precmd_functions+=(prompt_reset)
fi

version_prompt(){
  version_prompt_val=""
  if [[ -n ${MINIMAL_VERSION_PROMPT} ]]; then
    local LOOP_INDEX=0
    for _v in $(echo "${MINIMAL_VERSION_PROMPT}"); do
      [[ ${LOOP_INDEX} != "0" ]] && version_prompt_val+="%F{$MINIMAL_FADE_COLOR}${MINIMAL_PROMPT_SEP}%f"
      [[ ${LOOP_INDEX} == "0" ]] && LOOP_INDEX=$((LOOP_INDEX + 1)) && version_prompt_val+="%F{$MINIMAL_FADE_COLOR}[%f"

      [[ ${_v} == "PYTHON" ]]    && version_prompt_val+="$(plib_python_version)"
      [[ ${_v} == "RUBY" ]]      && version_prompt_val+="$(plib_ruby_version)"
      [[ ${_v} == "JAVA" ]]      && version_prompt_val+="$(plib_java_version)"
      [[ ${_v} == "GO" ]]        && version_prompt_val+="$(plib_go_version)"
      [[ ${_v} == "ELIXIR" ]]    && version_prompt_val+="$(plib_elixir_version)"
      [[ ${_v} == "CRYSTAL" ]]   && version_prompt_val+="$(plib_crystal_version)"
      [[ ${_v} == "NODE" ]]      && version_prompt_val+="$(plib_node_version)"
      [[ ${_v} == "PHP" ]]       && version_prompt_val+="$(plib_php_version)"
    done

    [[ "$LOOP_INDEX" != "0" ]] && version_prompt_val+="%F{$MINIMAL_FADE_COLOR}]%f"
  fi
  PROMPT="${PROMPT}${version_prompt_val}"
}

if [[ ${precmd_functions[(ie)version_prompt]} -le ${#precmd_functions} ]]; then
    echo version_prompt already loaded
else
    precmd_functions+=(version_prompt)
fi

envvar_prompt(){
  envvar_prompt_val=""
  if [[ -n ${MINIMAL_ENVVAR_PROMPT} ]]; then
    local LOOP_INDEX=0
    for _var in $(echo "${MINIMAL_ENVVAR_PROMPT}"); do
      [[ ${LOOP_INDEX} != "0" ]] && envvar_prompt_val+="%F{$MINIMAL_FADE_COLOR}${MINIMAL_PROMPT_SEP}%f"
      [[ ${LOOP_INDEX} == "0" ]] && LOOP_INDEX=$((LOOP_INDEX + 1)) && envvar_prompt_val+="%F{$MINIMAL_FADE_COLOR}[%f"
      [[ ${_var} != "" ]] && envvar_prompt_val+="${_var}:${(P)_var}"
    done
    [[ "$LOOP_INDEX" != "0" ]] && envvar_prompt_val+="%F{$MINIMAL_FADE_COLOR}]%f"
  fi
  PROMPT="${PROMPT}${envvar_prompt_val}"
}

if [[ ${precmd_functions[(ie)envvar_prompt]} -le ${#precmd_functions} ]]; then
    echo envvar_prompt already loaded
else
    precmd_functions+=(envvar_prompt)
fi

git_prompt(){
  if [[ $(plib_is_git) == 1 ]]; then
    git_prompt_val="%F{$MINIMAL_FADE_COLOR}[%f "
    git_prompt_val+="%f$(plib_git_branch)"
    if [[ $(plib_git_stash) == 1 ]]; then
      git_prompt_val+=" ${MINIMAL_GIT_STASH_SYM}"
    fi
    if [[ $(plib_git_left_right) == 1 ]]; then
      git_prompt_val+="$(minimal_git_left_right)"
    fi
    git_prompt_val+=" %F{$MINIMAL_FADE_COLOR}]%f"
  fi
  PROMPT="${PROMPT}${git_prompt_val}"
}

if [[ ${precmd_functions[(ie)git_prompt]} -le ${#precmd_functions} ]]; then
    echo envvar_prompt already loaded
else
    precmd_functions+=(git_prompt)
fi

function prompt(){
    [[ ${MINIMAL_ENABLE_VI_PROMPT} == 1 ]] && minimal_render_vi_mode
    [[ ${MINIMAL_SPACE_PROMPT} == 1 ]] && echo
    
    venv=$(plib_venv)
    if [[ -v venv ]] && prompt_std="%F{black}${venv}%f "
    prompt_std+="%f%F{black}%~%f "
    prompt_vi='${MINIMAL_VI_PROMPT} '"${prompt_std}"
    PROMPT=${PROMPT}${prompt_vi}

    if [[ "$MINIMAL_HIDE_EXIT_CODE" == '1' ]]; then
      RPROMPT=''
    else
      RPROMPT="%(?..%F{red}%B%S  $?  %s%b%f)"
    fi
}

if [[ ${precmd_functions[(ie)prompt]} -le ${#precmd_functions} ]]; then
  echo envvar_prompt already loaded
else
  precmd_functions+=(prompt)
fi
