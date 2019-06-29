class Reading < ApplicationRecord
  belongs_to :thermostat

  validates :temperature, :humidity, :battery_charge, presence: true, numericality: { only_float: true }
  
  after_create :delete_redis_record

  def delete_redis_record
    $redis.del("#{thermostat_id}@#{number}")
  end
end
