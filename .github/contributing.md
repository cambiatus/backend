# Contributing to the Cambiatus Backend

First off, thank you so much for taking the time to contribute to this project. With help from people like
you around the world we make Cambiatus what it is.

Following these guidelines while contributing helps us ensure that we can find better and more efficient ways of working together. This in turn helps the whole community collaborate better and achieve higher heights in its endavours.

Our team at Cambiatus loves receiving contributions from the community. It is indeed contributors like you that have enabled us and continue to enable us to build the tools we build. There are many ways of contributing to the Cambiatus Backend you could help with commnunity management, writing manuals, teaching, submitting bug reports and feature request or even writing code that get used by the entire Cambiatus community.

Please don't use Github Issues to get support questions. Check whether the #devs channel on the [Cambiatus Open Source Discord Servers](https://discord.gg/3X58Qvx) can help you get your question answered.

## Your first contribution
First of all take a deep breath and relax, everyone started exactly where you are.

- Unsure where to begin contributing to the Cambiatus backend? You can start by looking through issues tagged with `good-first-issue` these are issues that involve easy tasks that whet your appetite for more and show you around.
- `Help wanted issues` - these are issues that may be a little more involved for a beginner but ultimately also a good foray into the codebase.

Working on your first Open Source contribution? You can learn how from this free series, [How to Contribute to an Open Source Project on GitHub](https://egghead.io/series/how-to-contribute-to-an-open-source-project-on-github).

At this point, you're ready to make your changes! Feel free to ask for help; everyone is a beginner at first 😸

If a maintainer asks you to "rebase" your PR, they're saying that a lot of code has changed, and that you need to update your branch so it's easier to merge.

## Before you get started
0. The very first step to take before submitting a PR is know what constitutes a good PR. So we encourage you to read these articles before making your PR request:
    1. [The anatomy of a perfect pull request](https://medium.com/@hugooodias/the-anatomy-of-a-perfect-pull-request-567382bb6067#:~:text=A%20good%20pull%20request%20will,and%20consequently%20the%20product%20development.)
    2. [How should I write a good pull request?](https://blog.carbonfive.com/why-write-good-pull-requests/)
    3. [Pull Request Etiquette](https://gist.github.com/mikepea/863f63d6e37281e329f8)
1. Fork the repo, this enables you to open PRs and push them.
2. Work the [setup guide](/.github/setup.md)
3. Run the test suite `MIX_ENV=test mix test`. Please note we only accept pull requests with passing tests, and it's awesome to make one pass. Small contributions such as fixing spelling errors, where the content is small enough not be considered intellectual property, can be submitted by a contributor as a patch, without forking the repo. 

If you find a security vulnerability, do NOT open an issue. Inform the #devs on the discord channel.

Bug reports can be filed using the issue template on this projects github repository, This format enables us to respond quicker and clearly to any bug reports.

## When filing an issue, make sure to answer these four questions:
 1. What version of the backend are you using (mix: version)?
 2. What did you do?
 3. What did you expect to see?
 4. What did you see instead?

## How to suggest a feature or enhancement
Many of the features that this backend has today have been added because our users saw the need. Open an issue on our issues list on GitHub which describes the feature you would like to see, why you need it, and how it should work. We tend to prefer that our feature request and enhancements start as issues, formatted this way they make it very clear to the whole community what the aim of the request is and how it will change the work.

# Code review process

The core team looks at Pull Requests on a regular basis in a weekly triage meeting that we hold. The meeting is announced in the weekly status updates that are send on Monday mornings.
After feedback has been given we expect responses within two weeks. After two weeks we may close the pull request if it isn't showing any activity.

## PR review in detail
1. Ensure your PR answers the following questions: 
    1. Summary of the issue being solved. Ideally a link to the issue that's being solved.
    2. How is the issue being solved.
    3. How can we verify the solution.
2. Once a pull request is sent, we will assign a member to review your PR.
3. The reviewer will check for the following items:
    1. There are no merge conflicts.
    2. CI/CD workflow passes all test: `mix test`, `mix credo` and `mix format --check-formatted`.
    3. The issue is resolved.
4. If the criteria for the PR passes it will get merged to into `master`.

# Releases
1. After a PR has been merged into `master`. We will push the change to our [staging server](staging.cambiatus.io) to conduct our integration test.
2. If the integration test passes then will push the change to `production` sever and conduct a final test.
3. If all test passes, then we are live!

# Community
You can chat with the core team on the discord channel linked above. We try to be available on all weekdays.

# Deployment
Oh wow! you are grown now, you even have your very own deployment keys how do you get this to work in the wild?
Well follow the guide below and you should be having lots of fun soon!

We use [distillery](https://hexdocs.pm/distillery/home.html) and docker as our preferred tools for deployment.
and you can bootstrap on this to get a self contained running version easily as follows:

1. You can build a docker image of the version you want by running `make build` in the project's root folder this
invokes a make file that builds a constainer image of a release.
2. You can then run `make push` to upload this image to a registry, if using a different registry rather than the cambiatus one you may need to modify the make file with your own details
3. Ensure to have docker authenticated as your work through this


## Server

Once built and now you intend to run it on a server you can run the following commands

  * `~/cambiatus/cambiatus/bin/cambiatus remote_console` to attach to the running process
  * `~/cambiatus/cambiatus/bin/cambiatus foreground` to run it and keep the output locked to the current session
  * `~/cambiatus/cambiatus/bin/cambiatus start` to start it on the background
  * `~/cambiatus/cambiatus/bin/cambiatus console` for a IEx session

To run migrations you can run:

  * `~/cambiatus/cambiatus/bin/cambiatus migrate` For running migrations
  * `~/cambiatus/cambiatus/bin/cambiatus seed` For adding seeding
	* Note these are now run automatically when starting a release

## To use Docker outide of our make script

### Build image
```
docker build -t 'cambiatus/backend:latest' .
```

The default env will be development, if you want to build it for `prod`:

```
docker build -t 'cambiatus/backend:latest' --build-arg "MIX_ENV=prod" .
```

### Run image
`docker run -t 'cambiatus/backend:latest'`

If you are running in `prod` env you'll also need to set the database env variables:

```sh
docker run -e "DB_HOST=example.host" -e "DB_PORT=5432" -e "DB_USER=user" -e "DB_PASSWORD=123" -e "BESPIRAL_WALLET_PASSWORD=kw123" -t 'cambiatus/backend:latest'
# OR
docker run --env-file=env_file_path -t 'cambiatus/backend:latest'
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


