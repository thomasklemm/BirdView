# Selects a random Twitter account
# and performs white-listed read-only actions with it.
# Use: '@twitter_client = RandomTwitterClient.new'
class RandomTwitterClient
  attr_reader :twitter_client, :twitter_account

  def initialize
    @twitter_account = TwitterAccount.random
    raise "No TwitterAccount could ne found" unless @twitter_account.present?
    @twitter_client = @twitter_account.client
  end

  # Whitelist read-only Twitter API actions
  # to be performed with the random Twitter account
  delegate :user,
           :user_search,
           to: :twitter_client
end
