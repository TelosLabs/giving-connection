class TimezoneDetector
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)

    # Try to get timezone from the cookie if it exists
    timezone = request.cookies["user_timezone"]

    # Store it in the request environment for controllers to access
    env["user_timezone"] = timezone || "UTC"

    @app.call(env)
  end
end
