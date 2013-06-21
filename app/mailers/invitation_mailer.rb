class InvitationMailer < ActionMailer::Base
  # Send out a mail with a link that allows new users
  # to accept an invitation
  def invitation(invitation)
    @invitation = invitation.decorate

    mail from: mail_from,
         to: mail_to,
         subject: mail_subject,
         reply_to: mail_reply_to
  end

  private

  def mail_subject
    "Join Tweetbox - Here's your invitation."
  end

  def mail_from
    "Tweetbox <#{ InvitationMailer.support_email }>"
  end

  def mail_to
    @invitation.email
  end

  def mail_reply_to
    @invitation.issuer_email
  end

  def self.support_email
    'help@tweetbox.dev'
  end
end
