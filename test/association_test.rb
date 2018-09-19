require "test_helper"

class AssociationTest < Minitest::Test
  Comment = Struct.new(:id, :body, :commenter)
  Author = Struct.new(:name)

  Post = Struct.new(:id, :title, :content, :comments, :author) do
    def active_model_serializer
      PostWithKeySerializer
    end
  end

  Account = Struct.new(:id, :name) do
    def active_model_serializer
      BlogAccountSerializer
    end

    def ext_id
      id
    end

    def as_json(_options)
      { id: id, name: name }
    end
  end

  Blog = Struct.new(:name, :url, :posts, :account) do
    def post_ids
      posts.map(&:id)
    end

    def post_codes
      post_ids
    end
  end

  class CommentSerializer < Jserializer::Base
    attributes :id, :body
    attribute :commenter, key: :who
  end

  class AuthorSerializer < Jserializer::Base
    attributes :name
  end

  class PostSerializer < Jserializer::Base
    attributes :title, :content
    has_many :comments, serializer: CommentSerializer
    has_one :author, serializer: AuthorSerializer
  end

  class PostWithKeySerializer < Jserializer::Base
    attributes :title, :content
    has_many :comments, key: :post_comments, serializer: CommentSerializer
    has_one :author, key: :by, serializer: AuthorSerializer
  end

  class PostInheritedSerializer < PostSerializer
  end

  class PostWithFilteredCommentsSerializer < Jserializer::Base
    attributes :title, :content
    has_many :comments, serializer: CommentSerializer

    def comments
      object.comments.take(1)
    end
  end

  class BlogAccountSerializer < Jserializer::Base
    attribute :id, key: :ext_id
    attribute :name, key: :username
  end

  class BlogSerializer < Jserializer::Base
    has_many :posts
    has_one :account
  end

  class BlogEmbedIdAllSerializer < Jserializer::Base
    embed :ids
    has_many :posts
    has_one :account
  end

  class BlogEmbedIdPartialSerializer < Jserializer::Base
    embed :ids
    has_many :posts
    has_one :account, embed: :objects
  end

  class BlogHasManyEmbedIdsSerializer < Jserializer::Base
    has_many :posts, embed: :ids
    has_one :account
  end

  class BlogHasOneEmbedIdsSerializer < Jserializer::Base
    has_many :posts
    has_one :account, embed: :ids
  end

  class BlogEmbedKeyHasManySerializer < Jserializer::Base
    has_many :posts, embed: :ids, embed_key: :code
    has_one :account
  end

  class BlogEmbedKeyHasOneSerializer < Jserializer::Base
    has_many :posts
    has_one :account, embed: :ids, embed_key: :ext_id
  end

  class BlogEmbedKeyWithKeySerializer < Jserializer::Base
    has_many :posts, embed: :ids, embed_key: :code, key: :article_ids
    has_one :account
  end

  describe 'Association' do
    def build_a_blog(total_posts: 4, comments_per_post: 5)
      blog = Blog.new('New Blog', 'www.blog.com')
      blog.posts = (1..total_posts).to_a.map do |i; post|
        post = Post.new(i, "Post #{i}", "Text #{i}")
        post.comments = (1..comments_per_post).to_a.map do |j|
          Comment.new(i, "This is comment ##{j} of Post #{i}", "User #{i}")
        end
        post.author = Author.new("Author #{i}")
        post
      end
      blog.account = Account.new(100, 'Account 0')
      blog
    end

    it 'includes one-to-many associated models through has_many statement' do
      post = Post.new(1, 'A', 'AAA')
      post.comments = (1..3).to_a.map do |i|
        Comment.new(i, "This is comment ##{i}", "User #{i}")
      end

      serializer = PostSerializer.new(post)
      result = serializer.serializable_hash

      assert_equal([:title, :content, :comments, :author], result.keys)
      assert_equal('A', result[:title])
      assert_equal('AAA', result[:content])
      assert_equal(3, result[:comments].length)

      result[:comments].each.with_index(1) do |comment, i|
        assert_equal([:id, :body, :who], comment.keys)
        assert_equal([i, "This is comment ##{i}", "User #{i}"], comment.values)
      end
    end

    it 'filters association by defining a method in the serializer' do
      post = Post.new(1, 'A', 'AAA')
      post.comments = (1..5).to_a.map do |i|
        Comment.new(i, "This is comment ##{i}", "User #{i}")
      end

      serializer = PostWithFilteredCommentsSerializer.new(post)
      result = serializer.serializable_hash
      assert_equal([:title, :content, :comments], result.keys)
      assert_equal(1, result[:comments].length)
    end

    it 'includes one-to-one associated model through has_one statement' do
      post = Post.new(1, 'B', 'PPP')
      post.author = Author.new('Sam')

      serializer = PostSerializer.new(post)
      result = serializer.serializable_hash

      assert_equal([:title, :content, :comments, :author], result.keys)
      assert_equal('B', result[:title])
      assert_equal('PPP', result[:content])
      assert_equal({ name: 'Sam' }, result[:author])
    end

    it 'renames associated models through :key option' do
      post = Post.new(1, 'C', 'CCC')
      post.comments = (1..3).to_a.map do |i|
        Comment.new(i, "This is comment ##{i}", "User #{i}")
      end
      post.author = Author.new('John')

      serializer = PostWithKeySerializer.new(post)
      result = serializer.serializable_hash

      assert_equal([:title, :content, :post_comments, :by], result.keys)
      assert_equal('C', result[:title])
      assert_equal('CCC', result[:content])
      assert_equal(3, result[:post_comments].length)

      result[:post_comments].each.with_index(1) do |comment, i|
        assert_equal([:id, :body, :who], comment.keys)
        assert_equal([i, "This is comment ##{i}", "User #{i}"], comment.values)
      end
      assert_equal({ name: 'John' }, result[:by])
    end

    it 'inherits associations from superclass' do
      post = Post.new(1, 'C', 'CCC')
      post.comments = (1..3).to_a.map do |i|
        Comment.new(i, "This is comment ##{i}", "User #{i}")
      end
      post.author = Author.new('John')

      serializer = PostInheritedSerializer.new(post)
      result = serializer.serializable_hash

      assert_equal([:title, :content, :comments, :author], result.keys)
      result[:comments].each.with_index(1) do |comment, i|
        assert_equal([:id, :body, :who], comment.keys)
        assert_equal([i, "This is comment ##{i}", "User #{i}"], comment.values)
      end
      assert_equal({ name: 'John' }, result[:author])
    end

    it 'finds serializer class in active_model_serializer method' do
      blog = build_a_blog(total_posts: 2, comments_per_post: 3)
      serializer = BlogSerializer.new(blog)
      result = serializer.serializable_hash

      assert_equal([:posts, :account], result.keys)
      assert_equal({ ext_id: 100, username: 'Account 0' }, result[:account])
      assert_equal(2, result[:posts].length)
      result[:posts].each do |post|
        assert_equal([:title, :content, :post_comments, :by], post.keys)
        assert_equal(3, post[:post_comments].length)
      end
    end

    describe 'Embed' do
      it 'include only ids for all associations' do
        blog = build_a_blog(total_posts: 4, comments_per_post: 5)
        serializer = BlogEmbedIdAllSerializer.new(blog)
        result = serializer.serializable_hash
        assert_equal([:post_ids, :account_id], result.keys)
        assert_equal([1, 2, 3, 4], result[:post_ids])
        assert_equal(100, result[:account_id])
      end

      it 'does not use ids when have embed: :objects option' do
        blog = build_a_blog(total_posts: 4, comments_per_post: 5)
        serializer = BlogEmbedIdPartialSerializer.new(blog)
        result = serializer.serializable_hash
        assert_equal([:post_ids, :account], result.keys)
      end

      it 'accepts embed option in has_many statement' do
        blog = build_a_blog(total_posts: 4, comments_per_post: 5)
        serializer = BlogHasManyEmbedIdsSerializer.new(blog)
        result = serializer.serializable_hash
        assert_equal([:post_ids, :account], result.keys)
      end

      it 'accepts embed option in has_one statement' do
        blog = build_a_blog(total_posts: 4, comments_per_post: 5)
        serializer = BlogHasOneEmbedIdsSerializer.new(blog)
        result = serializer.serializable_hash
        assert_equal([:posts, :account_id], result.keys)
      end

      it 'replaces _ids with embed_key option in has_many statement' do
        blog = build_a_blog(total_posts: 4, comments_per_post: 5)
        serializer = BlogEmbedKeyHasManySerializer.new(blog)
        result = serializer.serializable_hash
        assert_equal([:post_ids, :account], result.keys)
        assert_equal([1, 2, 3, 4], result[:post_ids])
      end

      it 'replaces _ids with embed_key option in has_one statement' do
        blog = build_a_blog(total_posts: 4, comments_per_post: 5)
        serializer = BlogEmbedKeyHasOneSerializer.new(blog)
        result = serializer.serializable_hash
        assert_equal([:posts, :account_id], result.keys)
        assert_equal(100, result[:account_id])
      end

      it 'renames attribute key with embed ids' do
        blog = build_a_blog(total_posts: 4, comments_per_post: 5)
        serializer = BlogEmbedKeyWithKeySerializer.new(blog)
        result = serializer.serializable_hash
        assert_equal([:article_ids, :account], result.keys)
        assert_equal([1, 2, 3, 4], result[:article_ids])
      end
    end
  end
end
