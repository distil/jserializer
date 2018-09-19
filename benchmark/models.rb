require 'securerandom'
require 'active_model'

class BaseModel
  include ActiveModel::Model
  include ActiveModel::Serialization
end

# A Blog has many posts
# A Post is created by an Author, and has many comments
# A Comment is created by an User
class Blog < BaseModel
  attr_accessor :id, :name, :url, :posts, :post_ids

  def post_ids
    posts.map { |post| post.id }
  end
end

class Post < BaseModel
  attr_accessor :id, :title, :content, :author, :comments, :comment_ids,
                :blog_id

  def author_id
    author.id
  end

  def comment_ids
    comments.map { |comment| comment.id }
  end
end

class Author < BaseModel
  attr_accessor :id, :first_name, :last_name, :company, :likes, :num_posts
end

class User < BaseModel
  attr_accessor :id, :first_name, :last_name, :username, :gender
end

class Comment < BaseModel
  attr_accessor :id, :body, :user

  def user_id
    user.id
  end
end

def rand_str(len)
  range = [('a'..'z'), ('A'..'Z'), (1..9)].map(&:to_a).flatten
  (1..len).map { range[rand(range.length)] }.join
end

def rand_num(n)
  SecureRandom.random_number(n)
end

def build_a_blog(num_posts: 100,
                 num_users: 100,
                 num_authors: 5,
                 num_comments_per_post: 1000)
  # Initialize objects
  blog = Blog.new(id: 1, name: 'New Blog', url: 'www.blog.com')

  authors = num_authors.times.to_a.map do |id|
    Author.new(
      id: id,
      first_name: rand_str(10),
      last_name: rand_str(5),
      company: rand_str(10),
      likes: rand_num(10),
      num_posts: rand_num(20)
    )
  end

  users = num_users.times.to_a.map do |id|
    User.new(
      id: id,
      first_name: rand_str(10),
      last_name: rand_str(5),
      username: rand_str(10),
      gender: rand_num(2)
    )
  end

  blog.posts = num_posts.times.to_a.map do |post_id; post|
    post = Post.new(id: post_id, title: "Post #{post_id}", content: rand_str(200))
    post.blog_id = blog.id
    post.author = authors[rand_num(5)]
    post.comments = num_comments_per_post.times.to_a.map do |comment_id; comment|
      comment = Comment.new(id: comment_id, body: rand_str(100))
      comment.user = users[rand_num(100)]
      comment
    end
    post
  end
  blog
end
