class UserFJSerializer
  include FastJsonapi::ObjectSerializer
  set_type :user
  attributes :id
  attribute :name do |object|
    "#{object.first_name} #{object.last_name}"
  end
  attribute :given_name, &:first_name
  attribute :surname, &:last_name
  # belongs_to :comment
end

class AuthorFJSerializer < UserFJSerializer
  set_type :author
  attribute :num_posts, if: Proc.new { |object| object.num_posts > 0 }
  attribute :score do |object|
    object.num_posts > 0 ? (object.likes / object.num_posts) : 0
  end
  # belongs_to :post
end

class CommentFJSerializer
  include FastJsonapi::ObjectSerializer
  set_type :comment
  attribute :id
  attribute :body, if: Proc.new { |object| object.body }
  has_one :user, serializer: ::UserFJSerializer
  # belongs_to :post
end

class PostFJSerializer
  include FastJsonapi::ObjectSerializer
  set_type :post
  attributes :id, :title
  attribute :content do |object|
    object.content.slice(0, 100)
  end
  # belongs_to :blog
  has_many :comments, serializer: ::CommentFJSerializer
  has_one :author, serializer: ::AuthorFJSerializer
end

class BlogFJSerializer
  include FastJsonapi::ObjectSerializer
  set_type :blog
  attributes :id, :name
  attribute :url do |object|
    "https://#{object.url}"
  end

  has_many :posts, serializer: ::PostFJSerializer
end
