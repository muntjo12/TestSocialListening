########################################
# Twitter Word Counter
#
# Connects to twitter's streaming API
# and recieves tweets containing words
# from [Keywords] table in DB.
# 
# Also counts each time any of the
# words appears in tweets, makes
# appropriate changes to the DB
#
########################################


#Database
require 'sqlite3'
#Twitter gem
require 'tweetstream'

#TweetStream gem connection keys, tokens, secrets
TweetStream.configure do |config|
  config.consumer_key       = 'FwagvzNoy7CfnkfZJkdBQ4RLL'
  config.consumer_secret    = 'LzySWk4kBsiZBKt6uzPgtF0kDL9tCAKTbZTIWATjmtPDMeIuC5'
  config.oauth_token        = '4135857079-SkvJUl8V6exuydQAxAsCWXvOmNNajsS6Q2WTMyt'
  config.oauth_token_secret = 'HJAohEy8NkJTnyBQ4lvewNunjArwHSd0VFF8H3PHkfHCs'
  config.auth_method        = :oauth
end

#Connect to the Database
DB = SQLite3::Database.open "db/development.sqlite3"
tweets = Queue.new

#tweetstream thread for recieving tweets containing words from keywords database
tweetStreamThread = Thread.new {
  TweetStream::Client.new.track(DB.execute( "SELECT word from keywords" ).flatten.join(", ")) do |status|
  tweets.enq(status.text)
end}

#check topics occurences in each tweet
occurThread = Thread.new {
  while true do
    if !tweets.empty?
        tweet = tweets.deq
        DB.execute( "SELECT word from keywords" ).each {|word|
        word = word.to_s[2..-3].downcase
        if tweet.downcase.include? word
        #visual
        print "."
        DB.execute( "UPDATE keywords
                    SET count = (select count+1 FROM keywords WHERE word = '#{word}')
                    WHERE word = '#{word}'" )
        end}
    end
  end
}

#initiate all threads
tweetStreamThread.join
occurThread.join
