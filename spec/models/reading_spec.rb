require 'rails_helper'

RSpec.describe Reading, type: :model do
  %i[temperature humidity battery_charge].each do |key|
    it { should validate_presence_of(key) }
    it { should validate_numericality_of(key) }
    it { should_not allow_value('test').for(key) }
  end

  it 'should delete data from redis when data is saved in DB' do
    thermostat = create(:thermostat)
    reading_params = { temperature: 1, humidity: 2, battery_charge: 3 }
    $redis.set("#{thermostat.id}@1", reading_params)
    expect(eval($redis.get("#{thermostat.id}@1"))).to eq(reading_params)
  
    Reading.create(reading_params.merge(thermostat_id: thermostat.id, number: 1))
    expect($redis.get("#{thermostat.id}@1")).to be_nil
  end
end
