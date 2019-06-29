unless Rails.env.test?
  $redis = Redis::Namespace.new("medwing_test", :redis => Redis.new)
else
  $redis = Redis::Namespace.new("medwing_test_test", :redis => MockRedis.new)
end