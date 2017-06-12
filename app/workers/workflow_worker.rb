
class WorkflowWorker

  @queue = "workflow"

  def self.perform(message)
    puts 'received message'
    puts message

    ##TODO: get model_name
    model_name = 'thesis'

    begin
      if model_name=='thesis'
        ThesisProcessor.process(message)
      end
    rescue Exception => e
      puts e.message
      puts e.backtrace
    end

  end


end
