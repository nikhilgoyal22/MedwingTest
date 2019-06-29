class ReadingsController < ApplicationController
  before_action :find_thermostat
  before_action :find_reading, only: [:index]
  before_action :validate_params, only: [:create]

  def index
    render json: { message: "No data for given reading number" }, status: 404 and return if @reading.nil?
    render json: { reading: @reading }
  end

  def create
    number = ReadingCachingService.new(reading_params, @thermostat).save
    ReadingJob.perform_later(reading_params, @thermostat.id, number)
    render json: { reading: { number: number } }, status: 201
  end

  def stats
    stats = $redis.get("thermo_stats_#{@thermostat.id}")
    statistics = stats.nil? ? {} : eval(stats)
    render json: { statistics: statistics }
  end

  private

  def reading_params
    params.permit(:temperature, :humidity, :battery_charge)
  end

  def find_thermostat
    render json: { message: 'Missing Token' }, status: 422 and return if params[:household_token].blank?
    @thermostat = Thermostat.find_by(household_token: params[:household_token])
    render json: { message: 'Unauthorised Token' }, status: 401 and return if @thermostat.nil?
  end

  def validate_params
    @reading = Reading.new(reading_params.merge({thermostat_id: @thermostat.id}))
    render json: { message: @reading.errors.full_messages.to_sentence }, status: 422 and return unless @reading.valid?
  end

  def find_reading
    reading = $redis.get("#{@thermostat.id}@#{params[:number]}")
    @reading = eval(reading) and return unless reading.nil?
    attrs = "temperature, humidity, battery_charge, number, thermostat_id"
    @reading = Reading.select(attrs).find_by(thermostat: @thermostat, number: params[:number])
  end
end