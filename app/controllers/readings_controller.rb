class ReadingsController < ApplicationController
  before_action :find_thermostat
  before_action :find_reading, only: [:index]
  before_action :validate_params, only: [:create]

  def index
    error_response("Invalid reading number", 404) and return if @reading.nil?
    json_response({ reading: @reading })
  end

  def create
    number = ReadingCachingService.new(reading_params, @thermostat).save
    ReadingJob.perform_later(reading_params, @thermostat.id, number)
    json_response({ reading: { number: number } }, 201)
  end

  def stats
    stats = $redis.get("thermo_stats_#{@thermostat.id}")
    statistics = stats.nil? ? {} : eval(stats)
    json_response({ statistics: statistics })
  end

  private

  def reading_params
    params.permit(:temperature, :humidity, :battery_charge)
  end

  def find_thermostat
    error_response('Missing Token') and return if params[:household_token].blank?
    @thermostat = Thermostat.find_by(household_token: params[:household_token])
    error_response('Unauthorised Token', 401) and return if @thermostat.nil?
  end

  def validate_params
    @reading = Reading.new(reading_params.merge({thermostat_id: @thermostat.id}))
    error_response(@reading.errors.full_messages.to_sentence) and return unless @reading.valid?
  end

  def find_reading
    error_response('Missing Reading Number') and return if params[:number].blank?
    reading = $redis.get("#{@thermostat.id}@#{params[:number]}")
    @reading = eval(reading) and return unless reading.nil?
    attrs = %w[temperature humidity battery_charge]
    @reading = Reading.find_by(thermostat: @thermostat, number: params[:number]).attributes.slice(*attrs)
  end
end