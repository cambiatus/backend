#!/bin/bash

command_log() { printf "LOG: %b\n" "$*"; }
run_command() { command_log "COMMAND $1"; $1; }

[ -z $APP_VERSION ] && printf "APP_VERSION is missing" && exit 1

if [ ! -d ../_build/prod/rel/backend/releases/$APP_VERSION ]
then
  command_log "install dependencies"
  run_command "mix do local.hex --force, local.rebar --force"
  run_command "mix do deps.get --only prod, deps.compile"

  command_log "compile app"
  run_command "mix compile"

  command_log "create release"
  run_command "mix release cambiatus"
fi
