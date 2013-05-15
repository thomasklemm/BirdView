# == Schema Information
#
# Table name: tweets
#
#  author_id             :integer
#  created_at            :datetime         not null
#  id                    :integer          not null, primary key
#  in_reply_to_status_id :integer
#  in_reply_to_user_id   :integer
#  previous_tweet_ids    :integer
#  project_id            :integer
#  text                  :text
#  twitter_account_id    :integer
#  twitter_id            :integer          not null
#  updated_at            :datetime         not null
#  workflow_state        :text
#
# Indexes
#
#  index_tweets_on_author_id                  (author_id)
#  index_tweets_on_previous_tweet_ids         (previous_tweet_ids)
#  index_tweets_on_project_id                 (project_id)
#  index_tweets_on_project_id_and_author_id   (project_id,author_id)
#  index_tweets_on_project_id_and_twitter_id  (project_id,twitter_id) UNIQUE
#  index_tweets_on_twitter_id                 (twitter_id)
#  index_tweets_on_workflow_state             (workflow_state)
#

class Tweet < ActiveRecord::Base
  include Workflow

  belongs_to :project
  validates :project, presence: true

  belongs_to :author
  validates :author, presence: true

  # Allows us to fetch previous tweets through the same twitter account
  belongs_to :twitter_account
  validates :twitter_account, presence: true

  # States
  scope :incoming,  where(workflow_state: :new)
  scope :answering, where(workflow_state: :open)
  scope :resolved,  where(workflow_state: :closed)

  # Ensures uniquness of a tweet scoped to the project
  validates_uniqueness_of :twitter_id, scope: :project_id

  workflow do
    # Tweets that have been fetched solely to build up conversation histories
    # can be marked with the :none state. They require no action, but an agent
    # may decide to open a case from them.
    # Unless a different state is assigned, all tweets are marked as :none.
    state :none do
      event :open, transitions_to: :open
      event :close, transitions_to: :closed
    end

    # New tweets that require a decision are marked as :new
    state :new do
      event :open, transitions_to: :open
      event :close, transitions_to: :closed
    end

    # Open tweets require an action such as a reply. The :open state
    # marks in essence open cases on our helpdesk.
    state :open do
      event :open, transitions_to: :open
      event :close, transitions_to: :closed
    end

    # Closed tweets are tweets that have been dealt with. They may have
    # marked as :closed after a reply has been sent, or simply been appreciated
    # and marked as :closed without requiring an action.
    state :closed do
      event :open, transitions_to: :open
      event :close, transitions_to: :closed
    end
  end

  # Loads and memoizes the tweet's previous tweets
  # from the array of cached previous tweet ids
  def previous_tweets(reload=false)
    reload ? previous_tweets! : @previous_tweets ||= previous_tweets!
  end

  # Returns the previous tweet from the database
  # or instructs the ConversationWorker to fetch it from Twitter
  def previous_tweet
    return unless in_reply_to_status_id.present?

    previous_tweet = project.tweets.where(twitter_id: in_reply_to_status_id).first

    # Fetch previous tweet and whole conversation if tweets are not in the database already
    ConversationWorker.perform_async(self.id) unless previous_tweet.present?

    previous_tweet
  end

  # Loads and memoizes the tweet's future tweets
  def future_tweets(reload=false)
    reload ? future_tweets! : @future_tweets ||= future_tweets!
  end

  # Assigns a certain workflow state given a symbol or string
  # Knows about a whitelist of valid states
  def assign_state(state)
    state &&= state.to_s
    return unless %w(none new open closed).include?(state)

    # Assigns known states, but only assign none state if there isn't already a state present
    state == 'none' ? self.workflow_state ||= state : self.workflow_state = state
  end

  # Assigns the tweet's fields from a Twitter status object
  # Persists the changes to the database by saving the record
  # Returns the saved tweet record
  def update_fields_from_status(status)
    assign_fields_from_status(status)
    save && self
  end

  def to_param
    twitter_id
  end

  private

  # Assigns the tweet's fields from a Twitter status object
  # Returns the tweet record without saving it and persisting
  # the changes to the database
  def assign_fields_from_status(status)
    self.twitter_id = status.id
    self.text       = status.text
    self.created_at = status.created_at
    self.in_reply_to_status_id = status.in_reply_to_status_id
    self.in_reply_to_user_id   = status.in_reply_to_user_id
  end

  # Loads the previous tweets from the database
  def previous_tweets!
    @previous_tweets = self.class.where(twitter_id: previous_tweet_ids)
  end

  # Loads the future tweets from the database
  def future_tweets!
    @future_tweets = self.class.where('previous_tweet_ids && ARRAY[?]', self.twitter_id).to_a
  end
end
