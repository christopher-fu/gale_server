alias GaleServer.{Repo, User, Friend, FriendReq, Event, EventUser}
alias Ecto.Changeset
import Ecto
import Ecto.Query

{:ok, chris} = User.get_by_username("chris")
{:ok, adam} = User.get_by_username("adam")
