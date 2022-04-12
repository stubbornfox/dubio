class Algorithm < ApplicationRecord
  default_scope { order('id desc') }
  has_many :experiments, dependent: :destroy

  after_commit :run_experiment, on: [ :create, :update]

  def run_experiment
    HardWorker.perform_async(self.id)
  end
end
