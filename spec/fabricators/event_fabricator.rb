Fabricator(:event) do
  name
  user
  eventable { Fabricate([:account, :project, :user, :invitation, :twitter_account, :search, :tweet, :status].sample) }
end
