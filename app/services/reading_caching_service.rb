class ReadingCachingService
  def initialize(reading, thermostat)
    @reading = reading
    @thermostat = thermostat
    @thermostat_id = @thermostat.id
    @number = ($redis.get("#{@thermostat_id}_last_number") || 0).to_i + 1
  end

  def save 
    $redis.set("#{@thermostat_id}_last_number", @number)
    $redis.set("#{@thermostat_id}@#{@number}", @reading)
    update_statistics
    @number
  end

  private

  def update_statistics
    statistics = eval($redis.get("thermo_stats_#{@thermostat_id}") || '{}')
    %w[temperature humidity battery_charge].each do |key|
      val = @reading[key].to_f
      statistics["min_#{key}"] = @reading[key] if statistics["min_#{key}"].blank? || statistics["min_#{key}"].to_f > val
      statistics["max_#{key}"] = @reading[key] if statistics["max_#{key}"].blank? || statistics["max_#{key}"].to_f < val
      current_average = statistics["average_#{key}"].to_f || 0.0
      statistics["average_#{key}"] = (current_average * (@number - 1) + val) / @number
    end
    $redis.set("thermo_stats_#{@thermostat_id}", statistics)
  end
end