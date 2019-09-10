# BeSpiral

[![CircleCI](https://circleci.com/gh/BeSpiral/backend/tree/master.svg?style=svg&circle-token=0dde8b1ae9164d53b9d0e624b25cff89e2718ead)](https://circleci.com/gh/BeSpiral/backend/tree/master)

To start your Phoenix server in development:

  * Install dependencies with `mix deps.get`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Deploy

We use [distillery](https://hexdocs.pm/distillery/home.html) and docker for deploy.

  * Build the release `make build`
  * Deploy it to the registry `make push`
  <!-- * Run it on production `` -->

## Server

Once in the server you can run the following commands

  * `~/bespiral/bespiral/bin/bespiral remote_console` to attach to the running process
  * `~/bespiral/bespiral/bin/bespiral foreground` to run it and keep the output locked to the current session
  * `~/bespiral/bespiral/bin/bespiral start` to start it on the background
  * `~/bespiral/bespiral/bin/bespiral console` for a IEx session
  
To run migrations you can run:

  * `~/bespiral/bespiral/bin/bespiral migrate` For running migrations
  * `~/bespiral/bespiral/bin/bespiral seed` For adding seeding

## Docker

### Build image
```
docker build -t 'bespiral/backend:latest' .
```

The default env will be development, if you want to build it for `prod`:

```
docker build -t 'bespiral/backend:latest' --build-arg "MIX_ENV=prod" .
```

### Run image
`docker run -t 'bespiral/backend:latest'`

If you are running in `prod` env you'll also need to set the database env variables:

```sh
docker run -e "DB_HOST=example.host" -e "DB_PORT=5432" -e "DB_USER=user" -e "DB_PASSWORD=123" -e "BESPIRAL_WALLET_PASSWORD=kw123" -t 'bespiral/backend:latest'
# OR
docker run --env-file=env_file_path -t 'bespiral/backend:latest'
```

If you are using docker-compose:

```yml
version: '3'

services:
  x:
    image: 'someimage:latest'
    env_file: env_file_path
    -- or
    environment:
      - BESPIRAL_WALLET_PASSWORD=123
      - DB_HOST=example.host
      - DB_PORT=5432
      - DB_USER=user
```
