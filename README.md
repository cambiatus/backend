<img src="https://cambiatus.github.io/assets/logo-cambiatus.png" alt="logo" width="300"> 

# Backend :wave:

[![Elixir CI](https://github.com/cambiatus/backend/actions/workflows/test.yml/badge.svg)](https://github.com/cambiatus/backend/actions/workflows/test.yml)

### New Organizations for the planet regeneration. Clear Objectives. Impactful Collaboration.

**For more information on us:**

- [Wiki](https://cambiatus.github.io/)
- [Blog](https://medium.com/cambiatus)
- [Communities](https://www.cambiatus.com/pilots)
- [FAQs](https://www.cambiatus.com/faq2)

## Table of Contents

- **[General Information](#general-information)**
- **[Technologies](#technologies)**
- **[Development Environment Setup](#development-environment-setup)**
- **[Contributing](#contributing)**
- **[Additional Resources](#additional-resources)**
- **[License](#license)**

## General Information

Welcome to the Application that serves as one of the backends for the Cambiatus Ecosystem. One of the backend since this is the one that contains the data in a manner than is easy to index and search.

In the context of the diagram below which is a high level view of how the data flows in our application this application serves as the datastore using a Postgres db and as the API using Phoenix running a Graphql Server

## Dataflow

<img src='https://i.imgur.com/MFfGOe3.png' height='492' alt='Cambiatus Data Flow' />

At a high level this is a database that is synced to events on an blockchain which then presents a Graphql API that makes
it simpler to consume the information from the blockchain. At the moment this is a normal database with the the usual
CRUD actions however creation and updating happens as a result of events that trigger writes and updates to our database.

The intention down the line is to make this database a write only database in an Event Sourced structure which will enable us to replay events and give us much more observability.

## Technologies

Here we have information on the type of technologies we use on our project, enjoy!

**Language & Framework**

- [Elixir](https://elixir-lang.org/docs.html) language main documentation page 
- [Phoenix](https://hexdocs.pm/phoenix/Phoenix.html) framework main documentation page 

**Query language**
   
- Intro to [GraphQL](https://graphql.org/learn/)

Here are some notable packages related to GraphQL:
   - [Ecto](https://hexdocs.pm/ecto/Ecto.html) is Elixir's database wrapper that works around GraphQL
   
   - [Absinthe package](https://hexdocs.pm/absinthe/overview.html) GraphQL toolkit for Elixir

Here is our [GraphQL wiki](https://cambiatus.github.io/onboarding.md) page

**Databases**

- Postgres main [documentation](https://www.postgresql.org/docs/) page
   
- EOS Blockchain main [documentation](https://developers.eos.io/welcome/latest/overview/index) page
   ## TODO fix link
   - Here is [our documentation](eos.md) on how we use EOS blockchain

## Development Environment Setup

To build and run this application locally follow the following steps!

**Step 1**

Clone this repository by running 
```
git clone git@github.com:cambiatus/backend.git
```
**Step 2**

Change into the new repository directory by running 
```
cd backend
```
**Step 3**

The system uses [ImageMagick](https://imagemagick.org/) for ensuring that the process of image uploads runs properly and [Mogrify](https://hex.pm/packages/mogrify) (dependency package) is dependent on this. [Here](https://imagemagick.org/script/download.php) are instructions for installing it.  

Install dependencies by running 
```
mix deps.get
```
**Step 4** 

Create a database by running 
```
mix ecto.create
``` 
*Note: you may need to change the database user and password variables values in the `config/test.exs` and `config/dev.exs` to ensure proper connection with Postgres.*

Then, run the current database migrations using 
```
mix ecto.migrate
```
**Step 5**

Once the ecto migration is done successfully, run tests via the test command below 
```
mix test
```
Note: Ideally the test results should exit with a status of `0 failed tests`

**Step 6** 

Lastly, run the server using the following command
```
mix phx.server
```
Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

#Boom! Now you can hack away!

## Contributing

When you are ready to make your first contribution please check out our [contribution guide](/.github/contributing.md), this will get your up to speed on where and how to start.

Once done with the contributing guide, here are some developing tips to help you:
		
**Code Formatting** 
   
   - To ensure code consistency we use [linter](https://en.wikipedia.org/wiki/Lint_(software)) testing, static code analysis for the approval of our Pull Requests. Always run `mix credo` before pushing your commits.

   - Another critical formatting command is `mix format`, which formats a specific file according to the Elixir language formatting rules command. There are IDE specific extensions and settings that you could use to have automated formatting. Here is one [Elixir vscode](https://marketplace.visualstudio.com/items?itemName=JakeBecker.elixir-ls) example for this.
		
**Files Not To Commit**

Changes related to local Postgres database credentials must not be commited to the repo

Here one way of how to not commit changes related to your local database connection credentials (user & password) to `dev.exs` and `text.exs` files:

- After you **finished working on a development** and **before you commit your changes**, select `dev.exs` and `text.exs` files on your IDE or Git Desktop. 
   - **IF** the only changes to these files are related to the local database connection credentials.
      - Then, revert all the changes on these two files (`dev.exs` and `text.exs`).
   - **ELSE** 
      - ONLY revert the changes related to the local database connection credentials on these two files (`dev.exs` and `text.exs`).

   - [HERE](https://stackoverflow.com/questions/1753070/how-do-i-configure-git-to-ignore-some-files-locally) is another alternative using the `exclude` command.  

## Additional Resources

- Here is our [Frontend (Elm)](https://github.com/cambiatus/frontend) repo. We use Elm which is an awesome functional language to play with!

- Here is our [Smart Contract (EOS)](https://github.com/cambiatus/contracts) repo. We use EOS which is an awesome blockchain and uses C++ as language to play with!

- Our [wiki](https://cambiatus.github.io/) page has several development resources to help you during your collaboration.
