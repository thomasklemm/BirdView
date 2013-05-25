class Status
  include Reformer

  attribute :project, Project
  attribute :user, User
  attribute :twitter_account_id, Integer
  attribute :text, String

  attr_accessor :old_tweet
  attr_reader   :new_tweet

  validates :project,
            :user,
            :twitter_account_id,
            :text, presence: true

  def tweet=(tweet)
    self.old_tweet = tweet
  end

  def save
    # Generates code and posted text
    if valid? && valid_tweet?
      post!
      true
    else
      false
    end
  end

  private

  ##
  # Prerequisites

  def valid_tweet?
    !Twitter::Validation.tweet_invalid?(posted_text)
  end

  def twitter_account
    @twitter_account ||= project.twitter_accounts.find(twitter_account_id) if twitter_account_id
  end

  def code
    @code ||= RandomCode.new.code(8)
  end

  def posted_text
    @posted_text ||= posted_text!
  end

  def posted_text!
    return text if tweet_length(text) <= 140

    virtual_text = text.slice(0, 225)
    parts = [virtual_text, ellipsis_and_public_url]

    while tweet_length(parts.join) > 140
      parts = [virtual_text.slice(0, -2), ellipsis_and_public_url]
    end

    parts.join
  end

  def tweet_length(text)
    Twitter::Validation.tweet_length(text)
  end

  def ellipsis_and_public_status_url
    "...\n#{ public_url }"
  end

  def public_status_url
    "http://birdview.dev/read-more/#{ code }"
  end

  ##
  # Posting

  # Returns a tweet record
  def post!
    status = twitter_account.client.update(posted_text, update_status_options)
    @new_tweet = project.create_tweet_from_twitter(status, twitter_account: twitter_account, state: :posted)
  end

  def update_status_options
    old_tweet.present? ? { in_reply_to_status_id: old_tweet.twitter_id } : {}
  end
end
