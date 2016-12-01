alias GaleServer.{Repo, User, Friend, FriendReq, Event, AcceptedEventUser,
  PendingEventUser, RejectedEventUser}
alias Ecto.Changeset
import Ecto
import Ecto.Query
use Timex

{:ok, adam} = User.get_by_username("adam")
{:ok, chris} = User.get_by_username("chris")
