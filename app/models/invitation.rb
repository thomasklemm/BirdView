# == Schema Information
#
# Table name: invitations
#
#  account_id :integer          not null
#  admin      :boolean          default(FALSE)
#  code       :text             not null
#  created_at :datetime         not null
#  email      :text             not null
#  id         :integer          not null, primary key
#  invitee_id :integer
#  issuer_id  :integer          not null
#  updated_at :datetime         not null
#  used_at    :datetime
#
# Indexes
#
#  index_invitations_on_account_id  (account_id)
#  index_invitations_on_code        (code) UNIQUE
#

class Invitation < ActiveRecord::Base
  belongs_to :account
  belongs_to :host, class_name: 'User'
  belongs_to :new_user, class_name: 'User'
  has_and_belongs_to_many :projects

  validates :account, :email, :sender, presence: true
  validates :code, presence: true, uniqueness: true

  after_initialize :generate_code!

  # Deactivate unused invitations after a certain amount of days
  def active?
    new_record? || created_at < 7.days.ago
  end

  def send_mail!
    InvitationMailer.invitation(self).deliver
  end

  # TODO: Specs
  def accept!(invitee)
    return false unless invitee.present?

    membership = create_membership!(invitee)
    mark_as_used!(invitee)
    create_projects!(membership)

    membership
  end

  def account_name
    account.name
  end

  def sender_name
    sender.name
  end

  def to_param
    code
  end

  private

  def generate_code!
    self.code ||= Random.new.code(16)
  end

  def create_membership!(invitee)
    Membership.create! do |membership|
      membership.user    = invitee
      membership.account = account
      membership.admin   = admin
    end
  end

  def mark_as_used!(invitee)
    self.invitee = invitee
    self.used = true
    self.save!
  end

  def create_projects!(membership)
    projects.map { |project| project.permissions.where(membership_id: membership.id).first_or_create! }
  end
end
