require 'rails_helper'

RSpec.describe ReadingJob, type: :job do
  describe "#perform_later" do
    it "creates reading" do
      reading_params = { temperature: 1, humidity: 2, battery_charge: 3 }
      ActiveJob::Base.queue_adapter = :test

      expect {
        ReadingJob.perform_later(reading_params, 1, 1)
      }.to have_enqueued_job
    end
  end
end
