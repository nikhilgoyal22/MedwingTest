class Thermostat < ApplicationRecord
  validates :household_token, presence: true, uniqueness: true
  validates :location, presence: true
  has_many :readings, dependent: :destroy
end
