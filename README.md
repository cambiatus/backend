# Cambiatus ~ Backend

Welcome to the Application that serves as one of the backends for the Cambiatus Ecosystem, One of the backends since this is the one that contains the data in a manner than is easy to index and search.

In the context of the diagram below which is a high level view of how the data flows in our application this application serves as the datastore using a postgress db and as the API using Phoenix running a Graphql Server

## Dataflow
<img src='https://i.imgur.com/MFfGOe3.png' height='492' alt='Cambiatus Data Flow' />

At a highlevel this is a database that is synced to events on an blockchain which then presents a Graphql API that makes
it simpler to consume the information from the blockhain. At the moment this is a normal database with the the usual
CRUD actions however creation and updating happens as a result of events that trigger writes and updates to our database.

The intention down the line is to make this database a write only database in an Event Sourced structure which will enable us to replay events and give us much more observability.


## Building and running the application locally
To build this backend follow the following
1. Clone this repository by running `git clone git@github.com:cambiatus/backend.git`
2. Change directory into the new repository by `cd backend`
3. Install dependencies by running `mix deps.get`
4. Run tests by running the test command as `mix test`
5. Run the server using `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Contributing

When you are ready to make your first contribution please check out our [Contribution guide](/.github/contributing.md), this will get your up to speed on where and how to start


## License

- TBD
