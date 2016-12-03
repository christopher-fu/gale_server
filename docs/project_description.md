# Gale

## Introduction
Gale is an application that aims to help people quickly organize events. Often
times, it is difficult to meet up with a group of friends on short notice. For
example, consider a situation where you are going to grab lunch in 30 minutes,
and you want to eat with somebody else, but you haven't made plans with anybody
specific. You would either have to message several friends individually, or if
you and your friends have a group message set up before hand, you could send a
message to that group. This is inconvenient for a few reasons:
  - Messaging everybody individually is a hassle.
  - Messaging a group notifies everybody in the group, not all of whom you may
    want to invite.
  - Invitees in the same group chat who do not want to go continue to receive
    notifications from the group chat.
  - It is difficult to coordinate time and place when everybody has different
    schedules.

Gale tries to solve this by allowing an event creator to specify where and when
he will go. The event invite is then sent out to invitees, who must immediately
respond to the invite with a simple tap. Event creators can choose who to invite
from a list of friends. This way, there is no quibbling about the time and
place: it is set in stone beforehand, and the event owner cannot change it after
the event is made. Gale handles the invitation process for the user so he does
not have to track each invitee down. Invitees who decline an invitation will not
receive any more notifications about it.

## Technical details
Gale currently consists of two parts: the backend (uses Phoenix, a web framework
written in Elixir; backed by Postgres) by Postgres, and the frontend (an iOS
app).

Gale uses Ecto as a DB abstraction layer. Ecto allows use to define schemas for
our models, which then defines the kinds of queries and actions we can perform
with those models. Take, for example, the definition of the `Event` model:

```elixir
schema "events" do
  field :description, :string, default: ""
  field :time, Timex.Ecto.DateTime

  belongs_to :owner, User
  many_to_many :accepted_invitees, User, join_through: AcceptedEventUser
  many_to_many :pending_invitees, User, join_through: PendingEventUser
  many_to_many :rejected_invitees, User, join_through: RejectedEventUser
  timestamps()
end
```

We can define fields on our model for the event description and time. We can
also define relationships between our `Event` model and other models (in this
case, `User`s). `Event`s have a foreign key reference to the event owner, and
they also have a many-to-many relationship with invitees (also `User`) through
three different join tables.

An ER diagram of Gale's entity model is shown below:

![gale-er](gale-er.png)

## Application of concepts learned in class
- SQL queries
- Normalization
  - Join tables are used extensively
