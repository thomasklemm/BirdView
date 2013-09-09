class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable,
         :validatable, :confirmable

  # Memberships and accounts
  has_one :membership
  has_one :account, through: :membership

  # Permissions and projects
  has_many :permissions
  has_many :projects, through: :permissions

  # Activities (Business events)
  has_many :activities

  # Devise validates email on presence and uniqueness
  #  (also when user changes his email)
  # Devise validates password on presence, confirmation, and length
  validates :name, presence: true

  scope :by_date, -> { order(created_at: :asc) }

  def admin_of?(account)
    return false unless account.persisted? && account == membership.try(:account)
    membership.admin?
  end

  def member_of?(account_or_project)
    account_or_project.has_member?(self)
  end

  # TODO: Implement user's first and last name as database fields
  def first_name
    name.split(' ')[0]
  end

  def last_name
    name.split(' ')[1]
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def to_param
    "#{ id }-#{ name.parameterize }"
  end

  def mixpanel_id
    "user_#{ id }"
  end
end
