class UserAMSerializer < ActiveModel::Serializer
  attributes :id, :name
  attribute :first_name, key: :given_name
  attribute :last_name, key: :surname

  def name
    "#{object.first_name} #{object.last_name}"
  end

  def include_name?
    object.first_name.length < 5 && object.last_name.length < 5
  end
end

class AuthorAMSerializer < UserSerializer
  attribute :num_posts
  attribute :score

  def score
    object.num_posts > 0 ? (object.likes / object.num_posts) : 0
  end

  def include_id?
    false
  end

  def include_name?
    object.first_name.length < 5 && object.last_name.length < 5
  end

  def include_num_posts?
    object.num_posts > 0
  end
end

class CommentAMSerializer < ActiveModel::Serializer
  attribute :body, key: :comment
  has_one :user, serializer: ::UserAMSerializer

  def include_body?
    true
  end
end

class PostAMSerializer < ActiveModel::Serializer
  attributes :id, :title, :content
  has_many :comments, serializer: ::CommentAMSerializer
  has_one :author, key: :posted_by, serializer: ::AuthorAMSerializer

  def content
    object.content.slice(0, 100)
  end

  def include_content?
    object.content.length > 100
  end
end

class BlogAMSerializer < ActiveModel::Serializer
  root :blog
  attributes :id, :name, :url
  has_many :posts, serializer: ::PostAMSerializer

  def url
    "https://#{object.url}"
  end
end
