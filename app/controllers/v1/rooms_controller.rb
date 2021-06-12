class V1::RoomsController < ApplicationController
  def index
    rooms = Room.all
    render json: { data: ActiveModel::SerializableResource.new(rooms, user_id: current_user.id, each_serializer: RoomSerializer).as_json, klass: "Room" }, status: :ok
  end

  def last
    @room = Room.last
    render json: { data: RoomSerializer.new(@room, scope: { user_id: current_user.id }, user_id: current_user.id).as_json, klass: "Room" }, status: :ok
  end

  def show
    @room = Room.find(params[:id])
    render json: { data: RoomSerializer.new(@room, scope: { user_id: current_user.id }, user_id: current_user.id).as_json, klass: "Room" }, status: :ok
  end

  def create
    @room = Room.new(room_params)
    @room.user_id = current_user.id
    if @room.save
      render json: { data: RoomSerializer.new(@room).as_json, klass: "Room" }, status: :ok
    end
  end

  def update
    @room = Room.find(params[:id])
    if @room.update_attributes(room_params)
      render json: { data: RoomSerializer.new(@room, user_id: current_user.id).as_json, klass: "Room" }, status: :ok
    else
      render json: { data: @room.errors.full_messages }, status: :ok
    end
  end

  def destroy
    @room = Room.find(params[:id])
    if @room.destroy
      render json: { data: "OK" }, status: :ok
    end
  end

  def room_params
    params.require(:room).permit!
  end
end
