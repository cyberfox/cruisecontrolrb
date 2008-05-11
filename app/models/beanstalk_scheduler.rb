class BeanstalkScheduler

  def initialize(project, client)
    @project = project
    @client = client
  end

  def run
    while (true) do
      begin
        @project.build_if_necessary or check_build_request_until_next_polling
        clean_last_build_loop_error
        throw :reload_project if @project.config_modified?
      rescue => e
        log_error(e) unless (same_error_as_before(e) and last_logged_less_than_an_hour_ago)
        sleep(Configuration.sleep_after_build_loop_error)
      end
    end
  end
  
  def check_build_request_until_next_polling
    @project.build_if_requested
    # Wait and the immediately delete this job.  We currently don't use job data.
    @client.reserve.delete
    @project.build
  end

  def same_error_as_before(error)
    @last_build_loop_error_source and (error.backtrace.first == @last_build_loop_error_source)
  end
  
  def last_logged_less_than_an_hour_ago
    @last_build_loop_error_time and @last_build_loop_error_time >= 1.hour.ago
  end
  
  def log_error(error)
    begin
      CruiseControl::Log.error(error) 
    rescue 
      STDERR.puts(error.message)
      STDERR.puts(error.backtrace.map { |l| "  #{l}"}.join("\n"))
    end
    @last_build_loop_error_source = error.backtrace.first
    @last_build_loop_error_time = Time.now
  end

  def clean_last_build_loop_error
    @last_build_loop_error_source = @last_build_loop_error_time = nil
  end

end