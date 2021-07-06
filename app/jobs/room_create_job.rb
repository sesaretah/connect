class RoomCreateJob < ApplicationJob
  queue_as :default
  URL = "https://sync.ut.ac.ir:8089/janus"

  def perform(room_id)
    room = Room.find_by_id(room_id)
    opts = {
      headers: {
        "Authorization" => "",
        "Content-Type" => "application/json",
      },
      body: {
        "janus" => "create",
        "transaction" => SecureRandom.hex(10),
      }.to_json,
    }
    session = HTTParty.post(URL, opts)

    opts = {
      headers: {
        "Authorization" => "",
        "Content-Type" => "application/json",
      },
      body: {
        "janus" => "attach",
        "plugin" => "janus.plugin.audiobridge",
        "transaction" => SecureRandom.hex(10),
      }.to_json,
    }
    plugin = HTTParty.post(URL + "/" + session["data"]["id"].to_s, opts)

    opts = {
      headers: {
        "Authorization" => "",
        "Content-Type" => "application/json",
      },
      body: {
        "janus" => "message",
        "transaction" => SecureRandom.hex(10),
        "body" => {
          "request" => "create",
          "room" => room.uuid.to_i,
          #"notify_joining" => true,
          "secret" => room.secret,
          "pin" => room.pin,
          #"publishers" => 50,
          "is_private" => true,
          "permanent" => true,
          "audiolevel_event" => true,
          "audio_active_packets" => 1,
          "audio_level_average" => 50,
        },
      }.to_json,
    }
    janus_room = HTTParty.post(URL + "/" + session["data"]["id"].to_s + "/" + plugin["data"]["id"].to_s, opts)
    if janus_room["janus"] && janus_room["janus"] == "success"
      p janus_room
      room.activated = true
      room.save
    end
  end
end
