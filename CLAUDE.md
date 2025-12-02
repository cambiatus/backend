# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Cambiatus is an Elixir/Phoenix backend application that serves as a GraphQL API for a regeneration economy platform. It syncs data from an EOS blockchain to a PostgreSQL database, providing a queryable interface for user accounts, communities, objectives, shop functionality, payments, and more.

**Key Links:**
- [Architecture & Data Flow](/.github/deep-dive.md)
- [Contributing Guidelines](./.github/contributing.md)
- [Setup Instructions](./.github/setup.md)

## Technology Stack

- **Language:** Elixir (~> 1.18)
- **Framework:** Phoenix 1.7.0
- **API:** GraphQL via Absinthe 1.7
- **Database:** PostgreSQL via Ecto 3.12
- **Job Queue:** Oban 2.18 (background jobs)
- **Blockchain:** EOS (via eosrpc 0.6.2)
- **File Storage:** AWS S3 (via ex_aws_s3)
- **Email:** Swoosh 1.19
- **Push Notifications:** Web Push Encryption 0.3.1

## Project Structure

The application is organized into logical domains under `lib/cambiatus/`:

- **accounts/** - User account management
- **auth/** - Authentication (sign up, sign in, sessions, invitations)
- **commune/** - Community/network management, transfers, roles
- **objectives/** - Objectives, actions, claims, rewards, validators
- **social/** - News feed and social features
- **shop/** - Products, orders, categories
- **payments/** - Contributions and payment callbacks
- **kyc/** - Know-Your-Customer data (addresses, cities, countries)
- **notifications/** - Push notifications and notification history
- **workers/** - Oban background job workers
- **eos.ex** - EOS blockchain integration

The Phoenix web layer is under `lib/cambiatus_web/`:

- **schema/** - GraphQL type definitions (split by domain: account_types, commune_types, etc.)
- **resolvers/** - GraphQL field resolvers (one per domain)
- **controllers/** - HTTP endpoint handlers (email, rich links, etc.)
- **plugs/** - HTTP middleware
- **channels/** - WebSocket channels for subscriptions

Each domain module exports a `data()` function that provides Dataloader configuration for efficient GraphQL batch loading.

## Essential Commands

### Development

```bash
# Install dependencies
mix deps.get

# Set up database (create, migrate, seed)
mix ecto.setup

# Run development server
mix phx.server
# Server runs on http://localhost:4000

# Run single test file
mix test test/path/to/test.exs

# Run specific test
mix test test/path/to/test.exs:12
```

### Code Quality & Formatting

```bash
# Format code
mix format

# Check formatting (used in CI)
mix format --check-formatted

# Run static analysis (linter)
mix credo

# Run security checks
mix sobelow --config

# Run comprehensive checks (all of the above)
mix check
```

### Database

```bash
# Create database
mix ecto.create

# Run migrations
mix ecto.migrate

# Rollback last migration
mix ecto.rollback

# Reset database (drop, create, migrate, seed)
mix ecto.reset
```

### Testing

```bash
# Run all tests (uses test alias which handles DB reset and migrations)
mix test

# Run tests with verbose output
mix test --verbose

# Run tests matching a pattern
mix test --include tag_name
```

## Key Architectural Patterns

### GraphQL API Design

- **Absinthe + Relay:** The schema uses Absinthe with Relay cursor-based pagination
- **Type Files:** GraphQL types are defined separately (e.g., `CommuneTypes`, `AccountTypes`) and imported into the main schema
- **Dataloader:** All domains provide a `Dataloader` source for N+1 query prevention. Check `lib/cambiatus_web/schema.ex` for how loaders are wired

### Authentication

- Request authentication is handled via middleware in `lib/cambiatus_web/schema/middleware/` (authenticate.ex, admin_authenticate.ex, email_special_authenticate.ex)
- Tokens are stored and managed in `lib/cambiatus_web/auth_token.ex`

### Background Jobs

- Uses Oban for background job processing
- Workers are defined in `lib/cambiatus/workers/` and scheduled through Oban configuration
- Common workers: email notifications (claim_email, transfer_email, digest), contributions (paypal), scheduled news

### Blockchain Integration

- EOS blockchain calls are centralized in `lib/cambiatus/eos.ex`
- Database changes trigger blockchain writes; blockchain events trigger database updates via `DbListener`

### Database Migrations

- Migrations are in `priv/repo/migrations/`
- Seed data is in `priv/repo/seeds.exs` (countries are in `priv/repo/country_seeds.exs`)

## Code Quality Standards

- Code is checked with **Credo** (linter) and **Sobelow** (security scanner)
- All code must pass `mix format --check-formatted` before being merged
- PR process requires review from at least one maintainer and one tester

## Testing Conventions

- Test files mirror source structure (e.g., `test/cambiatus/accounts/user_test.exs` for `lib/cambiatus/accounts/user.ex`)
- Uses `ex_machina` for factory fixtures and `Faker` for generating test data
- `mox` is used for mocking external dependencies
- Database state is reset before each test run (via the test alias)

## Important Notes

- **Database credentials:** Changes to database user/password in `config/dev.exs` and `config/test.exs` must not be committed
- **Environment variables:** Use `config/runtime.exs` for runtime configuration that comes from environment variables
- **External dependencies:** ImageMagick and Exiftool must be installed for image upload functionality
- **Oban:** The job queue needs proper Oban configuration in the supervision tree (see `lib/cambiatus/application.ex`)

## Deployment

- Releases are defined in `mix.exs` (dev, demo, cambiatus)
- See `DEPLOYMENT.md` for deployment-specific information
- Production uses NGINX for reverse proxy and crawler detection for Open Graph rich links
