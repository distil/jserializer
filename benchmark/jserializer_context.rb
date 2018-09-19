class UserSerializer < Jserializer::Base
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

class AuthorSerializer < UserSerializer
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

class CommentSerializer < Jserializer::Base
  attribute :body, key: :comment
  has_one :user, serializer: ::UserSerializer

  def include_body?
    true
  end
end

class PostSerializer < Jserializer::Base
  attributes :id, :title, :content
  has_many :comments, serializer: ::CommentSerializer
  has_one :author, key: :posted_by, serializer: ::AuthorSerializer

  def content
    object.content.slice(0, 100)
  end

  def include_content?
    object.content.length > 100
  end
end

class BlogSerializer < Jserializer::Base
  root :blog
  attributes :id, :name, :url
  has_many :posts, serializer: ::PostSerializer

  def url
    "https://#{object.url}"
  end
end
