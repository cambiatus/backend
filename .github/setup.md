## Building and running the application locally
To build this backend follow the following
1. Clone this repository by running `git clone git@github.com:cambiatus/backend.git`
2. Change directory into the new repository by `cd backend`
3. Install dependencies by running `mix deps.get`
4. Create a database by running `mix ecto.create` you may need to change the values in `config/test.exs` and `config/dev.es` for this to work. Specifically the database user and password
5. Run the current database migrations using 	`mix ecto.migrate`
6. Run tests by running the test command as `mix test` ideally this should exit with a status of 0
5. Run the server using `mix phx.server`


#Boom! and you can now hack away!

### TODO
- implement git hooks for contributors to ensure stability


