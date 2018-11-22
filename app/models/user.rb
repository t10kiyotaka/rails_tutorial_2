class User < ApplicationRecord
  has_many :microposts, dependent: :destroy
  has_many :active_relationships, class_name: "Relationship",
                                    foreign_key: "follower_id",
                                    dependent: :destroy
  has_many :passive_relationships, class_name: "Relationship",
                                    foreign_key: "followed_id",
                                    dependent: :destroy
  has_many :following, through: :active_relationships, source: :followed
  has_many :followers, through: :passive_relationships, source: :follower
  attr_accessor :remember_token, :activation_token, :reset_token
  before_save :downcase_email
  before_create :create_activation_digest
  validates :name, presence: true, length: { maximum: 50 }
  VALID_EMAIL_REGEX =/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
              format: { with: VALID_EMAIL_REGEX },
              uniqueness: { case_sensitive: false }
  has_secure_password
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true

  # return hashed value of passed string
  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  # return random token
  def User.new_token
    SecureRandom.urlsafe_base64
  end

  # memorize user to the database for eternal session
  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  # return true when the passed token coincide with the digest
  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

  # destory user's login information
  def forget
    update_attribute(:remember_digest, nil)
  end

  # Activate an account
  def activate
    update_columns(activated: true, activated_at: Time.zone.now)
  end

  # Send a email for activation
  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  # Set attributes for password reset
  def create_reset_digest
    self.reset_token = User.new_token
    update_columns(reset_digest: User.digest(reset_token), reset_sent_at: Time.zone.now)
  end

  # Send email for password reset
  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  # Return true if password reset is expired
  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end

  # Definition of feed
  def feed
    Micropost.where("user_id = ?",id)
  end

  # follow a user
  def follow(other_user)
    following << other_user
  end

  # unfollow a user
  def unfollow(other_user)
    active_relationships.find_by(followed_id: other_user.id).destroy
  end

  # Return true if current_user followd other_user
  def following?(other_user)
    following.include?(other_user)
  end

  private

    # Make email downcase
    def downcase_email
      self.email.downcase!
    end

    # Make activation_token and activation_digest then substitute
    def create_activation_digest
      self.activation_token = User.new_token
      self.activation_digest = User.digest(activation_token)
    end


end
