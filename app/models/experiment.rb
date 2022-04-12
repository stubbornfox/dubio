class Experiment < ApplicationRecord
  default_scope { order('id desc') }

  belongs_to :algorithm
end
