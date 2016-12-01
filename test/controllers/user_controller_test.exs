defmodule GaleServer.UserControllerTest do
  use GaleServer.ConnCase, async: true
  alias GaleServer.{Repo, User, Friend, FriendReq}
  alias Ecto.Changeset

  setup do
    users = [
      User.changeset(%User{}, %{username: "chris", password: "pass"}),
      User.changeset(%User{}, %{username: "adam", password: "adampass"}),
      User.changeset(%User{}, %{username: "bob", password: "bobpass"})
    ]
    [chris, adam, bob] = Enum.map(users, &Repo.insert!(&1))

    %{"payload" => %{"jwt" => chris_jwt}} = build_conn()
      |> post("/api/login", %{username: "chris", password: "pass"})
      |> json_response(200)
    %{"payload" => %{"jwt" => adam_jwt}} = build_conn()
      |> post("/api/login", %{username: "adam", password: "adampass"})
      |> json_response(200)

    [chris: chris, adam: adam, chris_jwt: chris_jwt, adam_jwt: adam_jwt,
      bob: bob]
  end

  describe "get_user/2" do
    test "responds with the requested user", %{
      chris: chris, chris_jwt: chris_jwt
    } do
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> get("/api/user/chris")
        |> json_response(200)
      expected = %{
        "error" => false,
        "payload" => %{
          "username" => chris.username,
          "name" => chris.name
        }
      }

      assert response == expected
    end

    test "responds with error when user does not exist",
      %{chris_jwt: chris_jwt} do
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> get("/api/user/asdf")
        |> json_response(404)
      expected = %{
        "error" => true,
        "payload" => %{
          "message" => "No user with username asdf exists"
        }
      }
      assert response == expected
    end
  end

  describe "send_friend_req/2" do
    test "sends friend request", %{
      chris: chris, chris_jwt: chris_jwt, adam: adam
    } do
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> post("/api/friendreq", %{username: "adam"})
        |> json_response(200)
      chris_to_adam = Repo.get_by!(FriendReq, user_id: chris.id,
        friend_id: adam.id)
      refute chris_to_adam == nil
      expected = %{
        "error" => false,
        "payload" => %{
          "inserted_at" => Timex.format!(chris_to_adam.inserted_at, "{ISO:Extended:Z}")
        }
      }

      assert response == expected
    end

    test "errors on nonexistent friend", %{chris_jwt: chris_jwt} do
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> post("/api/friendreq", %{username: "asdf"})
        |> json_response(404)
      expected = %{
        "error" => true,
        "payload" => %{
          "message" => "No user with username asdf exists"
        }
      }
      assert response == expected
    end

    test "errors when trying to send a duplicate outgoing friend request", %{
      chris: chris,
      adam: adam,
      chris_jwt: chris_jwt
    } do
      %FriendReq{}
      |> FriendReq.changeset(%{})
      |> Changeset.put_assoc(:user, chris)
      |> Changeset.put_assoc(:friend, adam)
      |> Repo.insert!()
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> post("/api/friendreq", %{username: adam.username})
        |> json_response(400)
      expected = %{
        "error" => true,
        "payload" => %{
          "message" => "You have already sent a friend request to " <>
            "#{adam.username}"
        }
      }
      assert response == expected
    end

    test "errors when trying to send an outgoing friend request when there is
    an existing incoming friend request", %{
      chris: chris,
      adam: adam,
      chris_jwt: chris_jwt
    } do
      %FriendReq{}
      |> FriendReq.changeset(%{})
      |> Changeset.put_assoc(:user, adam)
      |> Changeset.put_assoc(:friend, chris)
      |> Repo.insert!()
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> post("/api/friendreq", %{username: adam.username})
        |> json_response(400)
      expected = %{
        "error" => true,
        "payload" => %{
          "message" => "You already have a friend request from " <>
            "#{adam.username}"
        }
      }
      assert response == expected
    end

    test "errors when trying to send a friend request to an existing friend", %{
      chris: chris,
      adam: adam,
      chris_jwt: chris_jwt
    } do
      %Friend{}
      |> Friend.changeset(%{})
      |> Changeset.put_assoc(:user, chris)
      |> Changeset.put_assoc(:friend, adam)
      |> Repo.insert!()
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> post("/api/friendreq", %{username: adam.username})
        |> json_response(400)
      expected = %{
        "error" => true,
        "payload" => %{
          "message" => "You are already friends with #{adam.username}"
        }
      }
      assert response == expected
    end

    test "errors when trying to send a friend request to yourself", %{
      chris: chris,
      chris_jwt: chris_jwt
    } do
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> post("/api/friendreq", %{username: chris.username})
        |> json_response(400)
      expected = %{
        "error" => true,
        "payload" => %{
          "message" => "You cannot send a friend request to yourself"
        }
      }
      assert response == expected
    end
  end

  describe "get_friend_reqs/2" do
    test "gets all friend requests", %{
      chris: chris, chris_jwt: chris_jwt, adam: adam
    } do
      friend_req = %FriendReq{}
      |> FriendReq.changeset(%{})
      |> Changeset.put_assoc(:user, chris)
      |> Changeset.put_assoc(:friend, adam)
      |> Repo.insert!()
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> get("/api/friendreq")
        |> json_response(200)
      expected = %{
        "error" => false,
        "payload" => [%{
          "id" => friend_req.id,
          "user" => chris.username,
          "friend" => adam.username,
          "inserted_at" => Timex.format!(friend_req.inserted_at, "{ISO:Extended:Z}")
        }]
      }
      assert response == expected
    end
  end

  describe "get_friend_req/2" do
    test "gets a friend request", %{
      chris: chris, chris_jwt: chris_jwt, adam: adam
    } do
      friend_req = %FriendReq{}
        |> FriendReq.changeset(%{})
        |> Changeset.put_assoc(:user, chris)
        |> Changeset.put_assoc(:friend, adam)
        |> Repo.insert!()
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> get("/api/friendreq/#{friend_req.id}")
        |> json_response(200)
      expected = %{
        "error" => false,
        "payload" => %{
          "id" => friend_req.id,
          "user" => chris.username,
          "friend" => adam.username,
          "inserted_at" => Timex.format!(friend_req.inserted_at, "{ISO:Extended:Z}")
        }
      }

      assert response == expected
    end

    test "errors on nonexistent friend request", %{
      chris_jwt: chris_jwt
    } do
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> get("/api/friendreq/10")
        |> json_response(400)
      expected = %{
        "error" => true,
        "payload" => %{
          "message" => "You cannot access friend request id 10"
        }
      }
      assert response == expected
    end

    test "errors when trying to get another user's friend request", %{
      chris_jwt: chris_jwt, adam: adam, bob: bob
    } do
      friend_req = %FriendReq{}
        |> FriendReq.changeset()
        |> Changeset.put_assoc(:user, adam)
        |> Changeset.put_assoc(:friend, bob)
        |> Repo.insert!()
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> get("/api/friendreq/#{friend_req.id}")
        |> json_response(400)
      expected = %{
        "error" => true,
        "payload" => %{
          "message" => "You cannot access friend request id #{friend_req.id}"
        }
      }
      assert response == expected
    end
  end

  describe "update_friend_req/2" do
    test "accepts friend request", %{
      chris: chris, adam_jwt: adam_jwt, adam: adam
    } do
      friend_req = %FriendReq{}
        |> FriendReq.changeset()
        |> Changeset.put_assoc(:user, chris)
        |> Changeset.put_assoc(:friend, adam)
        |> Repo.insert!()
      response = build_conn()
        |> put_req_header("authorization", adam_jwt)
        |> put("/api/friendreq/#{friend_req.id}", %{
          "action" => "accept"
        })
        |> json_response(200)
      friend_rel = Repo.get_by(Friend, user_id: chris.id, friend_id: adam.id)
      expected = %{
        "error" => false,
        "payload" => %{
          "user" => chris.username,
          "friend" => adam.username,
          "inserted_at" => Timex.format!(friend_rel.inserted_at, "{ISO:Extended:Z}")
        }
      }
      refute friend_rel == nil
      assert response == expected
      assert Repo.get_by(Friend, user_id: adam.id, friend_id: chris.id) != nil
    end

    test "rejects friend request", %{
      chris: chris, adam_jwt: adam_jwt, adam: adam
    } do
      friend_req = %FriendReq{}
        |> FriendReq.changeset()
        |> Changeset.put_assoc(:user, chris)
        |> Changeset.put_assoc(:friend, adam)
        |> Repo.insert!()
      response = build_conn()
        |> put_req_header("authorization", adam_jwt)
        |> put("/api/friendreq/#{friend_req.id}", %{
          "action" => "reject"
        })
        |> json_response(200)
      expected = %{"error" => false}

      assert Repo.get_by(Friend, user_id: chris.id, friend_id: adam.id) == nil
      assert Repo.get_by(Friend, user_id: adam.id, friend_id: chris.id) == nil
      assert response == expected
    end

    test "cancels friend request", %{
      chris: chris, chris_jwt: chris_jwt, adam: adam
    } do
      friend_req = %FriendReq{}
        |> FriendReq.changeset()
        |> Changeset.put_assoc(:user, chris)
        |> Changeset.put_assoc(:friend, adam)
        |> Repo.insert!()
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> put("/api/friendreq/#{friend_req.id}", %{
          "action" => "cancel"
        })
        |> json_response(200)
      expected = %{"error" => false}

      assert Repo.get_by(Friend, user_id: chris.id, friend_id: adam.id) == nil
      assert Repo.get_by(Friend, user_id: adam.id, friend_id: chris.id) == nil
      assert response == expected
    end

    test "errors when trying to accept own friend request", %{
      chris: chris, chris_jwt: chris_jwt, adam: adam
    } do
      friend_req = %FriendReq{}
        |> FriendReq.changeset()
        |> Changeset.put_assoc(:user, chris)
        |> Changeset.put_assoc(:friend, adam)
        |> Repo.insert!()
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> put("/api/friendreq/#{friend_req.id}", %{
          "action" => "accept"
        })
        |> json_response(400)
      assert Repo.get_by(Friend, user_id: chris.id, friend_id: adam.id) == nil
      assert Repo.get_by(Friend, user_id: adam.id, friend_id: chris.id) == nil
      expected = %{
        "error" => true,
        "payload" => %{
          "message" => "You cannot accept your own friend request"
        }
      }
      assert response == expected
    end

    test "errors when trying to reject own friend request", %{
      chris: chris, chris_jwt: chris_jwt, adam: adam
    } do
      friend_req = %FriendReq{}
        |> FriendReq.changeset()
        |> Changeset.put_assoc(:user, chris)
        |> Changeset.put_assoc(:friend, adam)
        |> Repo.insert!()
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> put("/api/friendreq/#{friend_req.id}", %{
          "action" => "reject"
        })
        |> json_response(400)
      assert Repo.get_by(Friend, user_id: chris.id, friend_id: adam.id) == nil
      assert Repo.get_by(Friend, user_id: adam.id, friend_id: chris.id) == nil
      expected = %{
        "error" => true,
        "payload" => %{
          "message" => "You cannot reject your own friend request"
        }
      }
      assert response == expected
    end

    test "errors when trying to cancel sender's friend request", %{
      chris: chris, adam_jwt: adam_jwt, adam: adam
    } do
      friend_req = %FriendReq{}
        |> FriendReq.changeset()
        |> Changeset.put_assoc(:user, chris)
        |> Changeset.put_assoc(:friend, adam)
        |> Repo.insert!()
      response = build_conn()
        |> put_req_header("authorization", adam_jwt)
        |> put("/api/friendreq/#{friend_req.id}", %{
          "action" => "cancel"
        })
        |> json_response(400)
      assert Repo.get_by(Friend, user_id: chris.id, friend_id: adam.id) == nil
      assert Repo.get_by(Friend, user_id: adam.id, friend_id: chris.id) == nil
      expected = %{
        "error" => true,
        "payload" => %{
          "message" => "You cannot cancel a friend request that you didn't send"
        }
      }
      assert response == expected
    end

    test "errors when trying to accept somebody else's friend request", %{
      chris_jwt: chris_jwt, adam: adam, bob: bob
    } do
      friend_req = %FriendReq{}
        |> FriendReq.changeset()
        |> Changeset.put_assoc(:user, adam)
        |> Changeset.put_assoc(:friend, bob)
        |> Repo.insert!()
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> put("/api/friendreq/#{friend_req.id}", %{
          "action" => "accept"
        })
        |> json_response(400)
      assert Repo.get_by(Friend, user_id: adam.id, friend_id: bob.id) == nil
      assert Repo.get_by(Friend, user_id: bob.id, friend_id: adam.id) == nil
      expected = %{
        "error" => true,
        "payload" => %{
          "message" => "You cannot access friend request id #{friend_req.id}"
        }
      }
      assert response == expected
    end

    test "errors when trying to reject somebody else's friend request", %{
      chris_jwt: chris_jwt, adam: adam, bob: bob
    } do
      friend_req = %FriendReq{}
        |> FriendReq.changeset()
        |> Changeset.put_assoc(:user, adam)
        |> Changeset.put_assoc(:friend, bob)
        |> Repo.insert!()
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> put("/api/friendreq/#{friend_req.id}", %{
          "action" => "reject"
        })
        |> json_response(400)
      assert Repo.get_by(Friend, user_id: adam.id, friend_id: bob.id) == nil
      assert Repo.get_by(Friend, user_id: bob.id, friend_id: adam.id) == nil
      expected = %{
        "error" => true,
        "payload" => %{
          "message" => "You cannot access friend request id #{friend_req.id}"
        }
      }
      assert response == expected
    end

    test "errors when trying to cancel somebody else's friend request", %{
      chris_jwt: chris_jwt, adam: adam, bob: bob
    } do
      friend_req = %FriendReq{}
        |> FriendReq.changeset()
        |> Changeset.put_assoc(:user, adam)
        |> Changeset.put_assoc(:friend, bob)
        |> Repo.insert!()
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> put("/api/friendreq/#{friend_req.id}", %{
          "action" => "cancel"
        })
        |> json_response(400)
      assert Repo.get_by(Friend, user_id: adam.id, friend_id: bob.id) == nil
      assert Repo.get_by(Friend, user_id: bob.id, friend_id: adam.id) == nil
      expected = %{
        "error" => true,
        "payload" => %{
          "message" => "You cannot access friend request id #{friend_req.id}"
        }
      }
      assert response == expected
    end

    test "errors when action is not \"accept\", \"reject\", or \"cancel\"",
      %{chris_jwt: chris_jwt, adam: adam, chris: chris} do
      friend_req = %FriendReq{}
        |> FriendReq.changeset()
        |> Changeset.put_assoc(:user, chris)
        |> Changeset.put_assoc(:friend, adam)
        |> Repo.insert!()
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> put("/api/friendreq/#{friend_req.id}", %{
          "action" => 123
        })
        |> json_response(400)
      expected = %{
        "error" => true,
        "payload" => %{
          "message" => "action must be \"accept\", \"reject\", or \"cancel\""
        }
      }
      assert response == expected
    end
  end

  describe "get_friends/2" do
    test "gets all friends",
      %{chris: chris, chris_jwt: chris_jwt, adam: adam, bob: bob} do
      %Friend{}
      |> Friend.changeset(%{user_id: chris.id, friend_id: adam.id})
      |> Repo.insert!()
      %Friend{}
      |> Friend.changeset(%{user_id: adam.id, friend_id: chris.id})
      |> Repo.insert!()
      %Friend{}
      |> Friend.changeset(%{user_id: chris.id, friend_id: bob.id})
      |> Repo.insert!()
      %Friend{}
      |> Friend.changeset(%{user_id: bob.id, friend_id: chris.id})
      |> Repo.insert!()

      %{"payload" => friends} = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> get("/api/friend")
        |> json_response(200)

      assert length(Enum.filter(friends, fn (fr) -> fr["username"] == "adam" end)) == 1
      assert length(Enum.filter(friends, fn (fr) -> fr["username"] == "bob" end)) == 1
    end

    test "gets all friends (when non exist)",
      %{chris_jwt: chris_jwt} do
        %{"payload" => friends} = build_conn()
          |> put_req_header("authorization", chris_jwt)
          |> get("/api/friend")
          |> json_response(200)
        assert length(friends) == 0
    end
  end
end
