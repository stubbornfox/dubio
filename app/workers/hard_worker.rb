class HardWorker
  include Sidekiq::Worker

  def perform(algo_id)
    ExperimentsJob.new(algo_id).run
  end
end
