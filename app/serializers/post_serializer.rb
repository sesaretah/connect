class PostSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  attributes :id, :title, :draft, :content, :likes, :bookmarks, :follows, :liked, :bookmarked, :followed, :comments, :rating, :rated
  belongs_to :profile,  serializer: ProfileSerializer
  #belongs_to :comments,  serializer: CommentSerializer

  def comments
    comments = object.comments.order('created_at DESC').limit(instance_options[:page].to_i*5)
    return ActiveModel::SerializableResource.new(comments,  each_serializer: CommentSerializer ).as_json
  end 

  def content
    object.send(:content).to_s
  end

  def liked
    object.liked(instance_options[:user_id])
  end

  def bookmarked
    object.bookmarked(instance_options[:user_id])
  end

  def followed
    object.followed(instance_options[:user_id])
  end

  def rating
    object.rating(instance_options[:user_id])
  end

  def rated
    object.rated
  end
end
