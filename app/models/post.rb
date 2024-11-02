class Post < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy

  validates :content, presence: true
  validates :user, presence: true

  def comment_count
    comments.count
  end

  def self.filter_by_username(username)
    where(users: { username: username })
  end
end
