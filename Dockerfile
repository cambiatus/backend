#===========
# Build Stage
#===========
# The version of Alpine to use for the final image
ARG ALPINE_VERSION=3.9

FROM elixir:1.9.4-alpine AS builder

# The name of your application/release (required)
ARG APP_NAME=cambiatus
# The version of the application we are building (required)
ARG APP_VSN
# The environment to build with
ARG MIX_ENV=prod

ENV APP_NAME=${APP_NAME} \
    APP_VSN=${APP_VSN} \
    MIX_ENV=${MIX_ENV}

WORKDIR /opt/app

RUN apk update && \
  apk upgrade --no-cache && \
  apk add --no-cache \
    git \
    build-base && \
  mix local.rebar --force && \
  mix local.hex --force

# This copies our app source code into the build container
COPY . .

RUN mix do deps.get --only prod, deps.compile, compile

RUN \
  mkdir -p /opt/built && \
  mix release && \
  cp _build/${MIX_ENV}/prod-${APP_VSN}.tar.gz /opt/built && \
  cd /opt/built && \
  tar -xzf prod-${APP_VSN}.tar.gz && \
  rm prod-${APP_VSN}.tar.gz

#================
# Deployment Stage
#================
FROM alpine:${ALPINE_VERSION}

# The name of your application/release (required)
ARG APP_NAME

RUN apk update && \
    apk add --no-cache \
      bash \
      libssl1.1

ENV REPLACE_OS_VARS=true \
    APP_NAME=${APP_NAME}

WORKDIR /opt/app

COPY --from=builder /opt/built .

RUN mv /opt/app/bin/prod /opt/app/bin/${APP_NAME}

CMD trap 'exit' INT; /opt/app/bin/${APP_NAME} start
