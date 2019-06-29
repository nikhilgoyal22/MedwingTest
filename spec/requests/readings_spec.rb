require 'rails_helper'

RSpec.describe "Readings", type: :request do
  before(:each) do
    @thermostat = create(:thermostat)
  end

  describe "POST /readings" do
    it "should give 422 if missing household token" do
      reading_params = { temperature: 1, humidity: 2, battery_charge: 3 }
      post readings_path, params: reading_params
      expect(response).to have_http_status(422)
      expect(JSON.parse(response.body)['message']).to eq('Missing Token')
    end

    it "should give 401 for invalid household token" do
      reading_params = { temperature: 1, humidity: 2, battery_charge: 3 }
      post readings_path, params: reading_params.merge(household_token: 'invalid')
      expect(response).to have_http_status(401)
      expect(JSON.parse(response.body)['message']).to eq('Unauthorised Token')
    end

    it "should not save reading because of missing attribute" do
      reading_params = { humidity: 2, battery_charge: 3 }
      post readings_path, params: reading_params.merge(household_token: @thermostat.household_token)
      expect(response).to have_http_status(422)
      expect(JSON.parse(response.body)['message']).to eq("Temperature can't be blank and Temperature is not a number")
    end

    it "should not save reading because of invalid type attribute" do
      reading_params = { temperature: 1.5, humidity: 'two', battery_charge: 3 }
      post readings_path, params: reading_params.merge(household_token: @thermostat.household_token)
      expect(response).to have_http_status(422)
      expect(JSON.parse(response.body)['message']).to eq('Humidity is not a number')
    end

    it "should save reading and return sequence number" do
      reading_params = { temperature: 1.5, humidity: 2, battery_charge: 3 }
      post readings_path, params: reading_params.merge(household_token: @thermostat.household_token)
      expect(response).to have_http_status(201)
      expect(JSON.parse(response.body)['reading']['number']).to eq(1)
    end

    it "should return correct sequence number" do
      10.times do
        reading_params = { temperature: rand(100), humidity: rand(100), battery_charge: rand(100) }
        post readings_path, params: reading_params.merge(household_token: @thermostat.household_token)
      end

      reading_params = { temperature: 1.5, humidity: 2, battery_charge: 3 }
      post readings_path, params: reading_params.merge(household_token: @thermostat.household_token)
      expect(response).to have_http_status(201)
      expect(JSON.parse(response.body)['reading']['number']).to eq(11)
    end
  end

  describe "GET /readings" do
    it "should give 422 if missing household token" do
      get readings_path
      expect(response).to have_http_status(422)
      expect(JSON.parse(response.body)['message']).to eq('Missing Token')
    end

    it "should give 401 for invalid household token" do
      get readings_path, params: { household_token: 'invalid' }
      expect(response).to have_http_status(401)
      expect(JSON.parse(response.body)['message']).to eq('Unauthorised Token')
    end

    it "should give 422 for missing sequence number" do
      get readings_path, params: { household_token: @thermostat.household_token }
      expect(response).to have_http_status(422)
      expect(JSON.parse(response.body)['message']).to eq('Missing Reading Number')
    end

    it "should give 404 for invalid sequence number" do
      reading_params = { temperature: 1.5, humidity: 2, battery_charge: 3 }
      post readings_path, params: reading_params.merge(household_token: @thermostat.household_token)

      get readings_path, params: { number: 2, household_token: @thermostat.household_token }
      expect(response).to have_http_status(404)
      expect(JSON.parse(response.body)['message']).to eq('Invalid reading number')
    end 

    it "should give correct reading based on household and sequence number" do
      reading_params = { temperature: 1.5, humidity: 2, battery_charge: 3 }
      post readings_path, params: reading_params.merge(household_token: @thermostat.household_token)
      
      reading_params2 = { temperature: 4.5, humidity: 6.8, battery_charge: 35 }
      post readings_path, params: reading_params2.merge(household_token: @thermostat.household_token)

      get readings_path, params: { number: 2, household_token: @thermostat.household_token }
      expect(response).to have_http_status(200)
      expect(JSON.parse(response.body)['reading']['temperature'].to_f).to eq(reading_params2[:temperature])
    end 
  end

  describe "GET /stats" do
    it "should give 422 if missing household token" do
      get stats_path
      expect(response).to have_http_status(422)
      expect(JSON.parse(response.body)['message']).to eq('Missing Token')
    end

    it "should give 401 for invalid household token" do
      get stats_path, params: { household_token: 'invalid' }
      expect(response).to have_http_status(401)
      expect(JSON.parse(response.body)['message']).to eq('Unauthorised Token')
    end

    it 'should give correct stats' do
      @thermostat2 = create(:thermostat)

      [@thermostat, @thermostat2].each do |thermostat|
        readings = []
        10.times do
          readings << params = { temperature: rand(100), humidity: rand(100), battery_charge: rand(100) }.with_indifferent_access
          post readings_path, params: params.merge(household_token: thermostat.household_token)
        end

        get stats_path, params: { household_token: thermostat.household_token }
        expect(response).to have_http_status(200)

        %w[temperature humidity battery_charge].each do |key|
          arr = readings.map { |reading| reading[key] }
          avg = arr.inject{ |sum, el| sum + el }.to_f / arr.size

          expect(JSON.parse(response.body)['statistics']["min_#{key}"].to_f).to eq(arr.min)
          expect(JSON.parse(response.body)['statistics']["max_#{key}"].to_f).to eq(arr.max)
          expect(JSON.parse(response.body)['statistics']["average_#{key}"].to_f).to eq(avg)
        end
      end
    end
  end
end
