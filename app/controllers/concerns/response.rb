module Response
  def json_response(object, status = :ok)
    render json: object, status: status
  end

  def error_response(message, status = 422)
    render json: { message: message }, status: status
  end
end