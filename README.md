# GaleServer

## Setting up Postgres
[Postgres.app](http://postgresapp.com/) is the easiest way to get Postgres on
macOS. Just download the app and open it. To use the command line tools that
come with `Postgres.app`, follow the instructions
[here](http://postgresapp.com/documentation/cli-tools.html).

## Starting Phoenix
  - Install dependencies with `mix deps.get`
  - Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  - Start Phoenix endpoint with `mix phoenix.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## API documentation
All of the API routes are defined in [`web/router.ex`](web/router.ex). All
routes begin with `/api`. For example, the `/login` route can be accessed at
`http://localhost:4000/api/login`. All routes accept JSON post bodies, so make
sure to set the `Content-Type` header of POST requests to `application/json`.

There are two types of responses that API requests return: success and error. A
success response has the following format:

```json
{
  "error": false,
  "payload": {
    "field1": "...",
    "field2": "..."
  }
}
```

A failure response has the following format:

```json
{
  "error": true,
  "payload": {
    "field1": "...",
    "field2": "..."
  }
}
```

### Unauthorized routes
The following routes do not require authorization.

#### POST `/login`
Logs a user in.

The POST body must contain the following fields:
  - `username`
  - `password`

The client receives a success response if there exists a user with the given
username and password. The `payload` of the response will contain the following
fields:
  - `jwt`: A JWT string that can be used for authenticating the user in
    authenticated API requests
  - `exp`: The expiration time of the JWT

The client receives a failure response if login failed or if one of the required
POST fields is missing. The `payload` will contain one field:
  - `message`: An error message

#### POST `/user`
Creates a new user.

The POST body must contain the following fields:
  - `username`: Max length of 256 chars; must not contain whitespace
  - `password`
The following fields are optional:
  - `name` (default: `""`): Max length of 256 chars; must not contain whitespace

The client receives a success response if the given `username` and `name` are
valid and `username` has not been taken. The `payload` of the response will
contain the following fields:
  - `user`: JSON representation of the new user
     - `username`
     - `name`

The client receives a failure response if user creation failed or if one of the
required POST fields is missing. The `payload` will contain one or more fields
whose key is the problematic POST field and whose value is the problem. See the
following example:

```json
{
  "payload": {
    "password": "can't be blank"
  },
  "error": true
}
```

### Authorized routes
The following routes require a JWT to be provided in the `Authorization` header
(with no realm).

#### GET `/user/:username`
Retrieves information about a user with the given username.

The client receives a success response if there exists a user with the given
`username`. The `payload` will contain the following fields:
  - `user`: JSON representation of the new user
     - `username`
     - `name`
     - `id`

On failure, the client receives a response whose payload contains the following
field:
  - `message`: An error message

#### POST `/user/addfriend`
Sends a friend request.

The POST body must contain the following field:
  - `username`: The username of the user to send a friend request to

The client receives a success response if the username corresponds to an
existing user and there does not already exist a friend relation (pending or
accepted) between the two users. The`payload` will contain the following fields:
  - `inserted_at`: The time at which the friend request was made

On failure, the client receives a response whose payload contains the following
field:
  - `message`: An error message
