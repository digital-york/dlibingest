class WorkflowWorker

  @queue = "workflow"

  def self.perform(message)
    puts "In Web app, processing job: #{message}"
  end

end
