extends Control
@onready var host: Button = $MarginContainer/VBoxContainer/Host

func _ready() -> void:
	Steam.lobby_joined.connect(_on_lobby_joined)
	host.pressed.connect(_on_host_pressed)
	Steam.lobby_created.connect(_on_lobby_created)

	if SteamManager.invite_lobby_id > 0:
		Steam.joinLobby(SteamManager.invite_lobby_id)
		# Make sure to reset this lobby ID
		SteamManager.invite_lobby_id = 0
		
func _on_lobby_joined(lobby_id: int, _permissions: int, _locked: int, response: Steam.ChatRoomEnterResponse) -> void:
	if response == Steam.ChatRoomEnterResponse.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		print("Lobby %s joined successfully" % lobby_id)
		# Passed to our Steam global or if not needing to store the lobby ID, just saved locally in this script
		# _lobby_id = lobby_id
		SteamManager.lobby_id = lobby_id

		# Swap to the lobby scene here

	else:
		match response:
			Steam.ChatRoomEnterResponse.CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST:
				printerr("Failed joining lobby %s, this lobby no longer exists.")
			Steam.ChatRoomEnterResponse.CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED:
				printerr("Failed joining lobby %s, you don't have permission to join this Lobbies.")
			Steam.ChatRoomEnterResponse.CHAT_ROOM_ENTER_RESPONSE_FULL:
				printerr("Failed joining lobby %s, the lobby is now full.")
			Steam.ChatRoomEnterResponse.CHAT_ROOM_ENTER_RESPONSE_ERROR:
				printerr("Failed joining lobby %s, something unexpected happened!")
			Steam.ChatRoomEnterResponse.CHAT_ROOM_ENTER_RESPONSE_BANNED:
				printerr("Failed joining lobby %s, you are banned from this lobby.")
			Steam.ChatRoomEnterResponse.CHAT_ROOM_ENTER_RESPONSE_LIMITED:
				printerr("Failed joining lobby %s, you cannot join due to having a limited account.")
			Steam.ChatRoomEnterResponse.CHAT_ROOM_ENTER_RESPONSE_CLAN_DISABLED:
				printerr("Failed joining lobby %s, this lobby is locked or disabled.")
			Steam.ChatRoomEnterResponse.CHAT_ROOM_ENTER_RESPONSE_COMMUNITY_BAN:
				printerr("Failed joining lobby %s, this lobby is community locked.")
			Steam.ChatRoomEnterResponse.CHAT_ROOM_ENTER_RESPONSE_MEMBER_BLOCKED_YOU:
				printerr("Failed joining lobby %s, a user in the lobby has blocked you from joining.")
			Steam.ChatRoomEnterResponse.CHAT_ROOM_ENTER_RESPONSE_YOU_BLOCKED_MEMBER:
				printerr("Failed joining lobby %s, a user you have blocked is in the lobby.")
			Steam.ChatRoomEnterResponse.CHAT_ROOM_ENTER_RESPONSE_RATE_LIMIT_EXCEEDED:
				printerr("Failed joining lobby %s, you have exceeded the rate limit.")

func _on_host_pressed() -> void:
	var lobby_type: Steam.LobbyType = Steam.LobbyType.LOBBY_TYPE_PUBLIC
	Steam.createLobby(lobby_type, 4)


func _on_lobby_created(connect_status: Steam.Result, lobby_id: int) -> void:
	if connect_status == Steam.Result.RESULT_OK:
		# Set the lobby ID in our global script (if using one)
		print("Successfully created lobby %s" % lobby_id)
		SteamManager.lobby_id = lobby_id

		# Set the lobby name for displaying in searches, the lobby scene, etc.
		if not Steam.setLobbyData(SteamManager.lobby_id, "lobby_name", "Ezra test"):
			printerr("Failed to set lobby name")

		# We will grab and set all lobby data tags121
		if not Steam.setLobbyData(SteamManager.lobby_id, "id", "1"):
			printerr("Failed to set lobby data")
	else:
		printerr("Failed to create a lobby: %s" % connect_status)
