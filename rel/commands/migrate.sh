#!/bin/sh

release_ctl eval --mfa "Cambiatus.ReleaseTasks.migrate/1" --argv -- "$@"
