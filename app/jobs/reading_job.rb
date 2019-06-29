class ReadingJob < ApplicationJob
  queue_as :default

  def perform(reading_params, thermostat_id, number)
    Reading.create(reading_params.merge(thermostat_id: thermostat_id, number: number))
  end
end
