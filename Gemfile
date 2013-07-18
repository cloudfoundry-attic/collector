source "https://rubygems.org"

gem "rake"
gem "nats"
gem "vcap_common", "~> 2.2.1", git: "https://github.com/cloudfoundry/vcap-common.git"
gem "aws-sdk", :require => false
gem "dogapi", "~> 1.6.0"
gem "steno"

group :test do
  gem "rspec"

  gem "ci_reporter"

  gem "timecop"

  gem "rcov", :platforms => :ruby_18
  gem "rcov_analyzer", ">= 0.2", :platforms => :ruby_18

  gem "simplecov", :platforms => :ruby_19
  gem "simplecov-clover", :platforms => :ruby_19
  gem "simplecov-rcov", :platforms => :ruby_19
end
