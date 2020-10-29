<img src="https://cambiatus.github.io/assets/logo-cambiatus.png" alt="logo" width="300"> 

# Backend :wave:


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

Welcome to the Application that serves as one of the backends for the Cambiatus Ecosystem, One of the backends since this is the one that contains the data in a manner than is easy to index and search.

In the context of the diagram below which is a high level view of how the data flows in our application this application serves as the datastore using a postgress db and as the API using Phoenix running a Graphql Server

## Dataflow
<img src='https://i.imgur.com/MFfGOe3.png' height='492' alt='Cambiatus Data Flow' />

At a high level this is a database that is synced to events on an blockchain which then presents a Graphql API that makes
it simpler to consume the information from the blockchain. At the moment this is a normal database with the the usual
CRUD actions however creation and updating happens as a result of events that trigger writes and updates to our database.

The intention down the line is to make this database a write only database in an Event Sourced structure which will enable us to replay events and give us much more observability.

## Technologies

- Language & Framework
   - [Elixir](https://elixir-lang.org/docs.html) language main documentation page 
   - [Phoenix](https://hexdocs.pm/phoenix/Phoenix.html) framework main documentation page 

- Query language
   
	- Intro to [GraphQL](https://graphql.org/learn/)

   - [Ecto](https://hexdocs.pm/ecto/Ecto.html) is Elixir's database wrapper that works around GraphQL
   
   - [Absinthe package](https://hexdocs.pm/absinthe/overview.html) GraphQL toolkit for Elixir

   - Sample Queries & Mutations **(TO DO)**


- Databases

   - [Postgres](https://www.postgresql.org/docs/)
   
   - EOS Blockchain
      
      - Main [documentation](https://developers.eos.io/welcome/latest/overview/index) page
      
      - Here is [our documentation](eos.md) on how we use blockchain

## Building and running the application locally

To build this backend follow the following

1. Clone this repository by running `git clone git@github.com:cambiatus/backend.git`
2. Change into the new repository directory by running `cd backend`
3. Install dependencies by running `mix deps.get`
4. Create a database by running `mix ecto.create` you may need to change the database user and password variables values in the config/test.exs and config/dev.exs for this to work.
5. Run the current database migrations using `mix ecto.migrate`
6. Run tests by running the test command as `mix test` ideally this should exit with a status of 0
7. Run the server using `mix phx.server`
#Boom! and you can now hack away!

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Contributing **(TO DO)**

When you are ready to make your first contribution please check out our [Contribution guide](/.github/contributing.md), this will get your up to speed on where and how to start.

Once done with the contributing guide, here are some developing tips to help you:

1. Commit Practices
		
   - Formatting 
   
      - To ensure code consistency we use [linter](https://en.wikipedia.org/wiki/Lint_(software)) testing, static code analysis for the approval of our Pull Requests. Always run `mix credo` before pushing your commits

	   - Another critical formatting command is `mix format`, which formats a specific file according to the Elixir language formatting rules command. There are IDE specific extensions and settings that you could use to have automated formatting. Here is one [Elixir vscode](https://marketplace.visualstudio.com/items?itemName=JakeBecker.elixir-ls) example for this.
	
   - Local variables (difference between dev.exs and config.exs)**(TO DO)**
	
   - How to dump and restore data for local development **(TO DO)**
	
   - Instructions to don't commit certain files changes (dev.exs and text.exs) **(TO DO)**

## Additional Resources **(TO DO)**

- Here is our [Frontend](https://github.com/cambiatus/frontend) repo. We use Elm which is an awesome functional language to play with!

- Our [wiki](https://cambiatus.github.io/) page has several development resources to help and guide you during your collaboration

## License

- TBD
