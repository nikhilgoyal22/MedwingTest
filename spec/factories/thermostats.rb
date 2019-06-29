FactoryBot.define do
  factory :thermostat do
    household_token { Faker::Alphanumeric.unique.alphanumeric 10 }
    location { Faker::Address.full_address }
  end
end