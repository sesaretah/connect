class RoomSerializer < ActiveModel::Serializer
  attributes :id, :title, :is_private, :room_id, :pin, :user_uuid, :user_fullname,
             :is_owner, :is_admin

  def room_id
    object.uuid.to_i
  end

  def is_private
    object.private ? true : false
  end

  def user_uuid
    if scope && scope[:user_id]
      user = User.find_by_id(scope[:user_id])
      user.uuid if !user.blank?
    end
  end

  def user_fullname
    if scope && scope[:user_id]
      user = User.find_by_id(scope[:user_id])
      user.profile.fullname if !user.blank? && !user.profile.blank?
    end
  end

  def is_owner
    if scope && scope[:user_id] && object.user_id == scope[:user_id]
      true
    else
      false
    end
  end

  def is_admin
    if scope && scope[:user_id] && !object.moderator_ids.blank? && object.moderator_ids.include?(scope[:user_id].to_i)
      true
    else
      false
    end
  end
end
