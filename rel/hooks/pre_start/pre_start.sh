#!/bin/sh

release_ctl eval --mfa "BeSpiral.ReleaseTasks.migrate/1" --argv -- "$@"
