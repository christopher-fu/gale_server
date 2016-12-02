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
  - `username`: Max length of 255 chars; must not contain whitespace
  - `password`
The following fields are optional:
  - `name` (default: `""`): Max length of 255 chars; must not contain whitespace

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

On failure, the client receives a response whose payload contains the following
field:
  - `message`: An error message

#### GET `/friendreq`
Retrieves all of the user's friend requests.

This request never fails. The `payload` will be an array of objects with the
following schema:
  - `user`: Username of the request sender
  - `friend`: Username of the request recipient
  - `inserted_at`: ISO-8601 timestamp of when the request was made

#### GET `/friendreq/:id`
Gets a friend request by id.

If successful, returns a response with a payload with the following schema:
  - `id`: Friend request id
  - `user`: Username of sender
  - `friend`: Username of recipient
  - `inserted_at`: When the friend request was made

#### POST `/friendreq`
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


#### DELETE `/friendreq`
Responds to a friend request. The client must pass a request body with an
`action` field. `action` can be one of the following values:
  - `accept`: Can only be passed by the recipient of the friend request
  - `reject`: Can only be passed by the recipient of the friend request
  - `cancel`: Can only be passed by the sender of the friend request

If the action was `accept`, the success response payload has the following
schema:
  - `user`: Original sender of the friend request
  - `friend`: Original recipient of the friend request
  - `inserted_at`: When the friend request was accepted

If the action was `reject` or `cancel`, the success response will not have a
payload.

#### GET `/friend`
Retrieves all of the user's friends.

This request never fails. The `payload` will be an array of objects with the
following schema:
  - `username`
  - `name`
  - `inserted_at`: ISO-8601 timestamp of when the friend was added (the friend
    request was accepted)

#### GET `/event`
Gets a list of the users events. Only events that have not yet occurred are
returned.

The success response payload has the following schema:
  - `owned_events`: Array of events that the user owns
  - `accepted_events`: Array of events that the user has accepted
  - `pending_events`: Array of events that the user has been invited to but not
    yet responded to
  - `rejected_events`: Array of events that the user has rejected

An `event` has the following schema:
  - `id`
  - `description`
  - `time`: ISO-8601 Z timestamp (YYYY-MM-DDThh:mm:ssZ) of when the event will
    occur
  - `owner`: Username of the owner
  - `owner_name`
  - `accepted_invitees`: Array of users who have accepted the event, sorted by
    username
  - `pending_invitees`: Array of users who have been invited to the event but
    have not yet accepted or rejected the invitation, sorted by username
  - `rejected_invitees`: Array of users who have rejected the event, sorted by
    username

A `user` in the `accepted_invitees`, `pending_invitees`, and `rejected_invitees`
fields has the following schema:
  - `username`
  - `name`

#### GET `/event/:id`
Gets an event by id. Users may only get events that they own or have been
invited to.

The success response payload is the requested event. The event has the schema
described in GET `/event`.

#### POST `event`
Creates a new event.

The post body must contain the following fields:
  - `description`: Maximum of 1000 characters
  - `time`: ISO-8601 Z timestamp (YYYY-MM-DDThh:mm:ssZ). Must be in the future.
  - `invitees`: An array of usernames to invite

The success response payload will be the event, which follows the schema
described in GET `/event`

#### PUT `/event/:id`
Responds to an event invitation. Only users who have been invited to an event
can respond to the invitation. The event owner cannot respond to his own event.

The request body must contain an `action` field, which must either be `accept`
or `reject`.

The success payload is the event that was responded to. The event has the schema
described in GET `/event`.

#### DELETE `/event/:id`
Cancels an event. Only the event owner can cancel the event. When canceled, the
event is deleted and will no longer show up in any other requests.

The success response has no payload.
