class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def execute_sql(query)
    ActiveRecord::Base.connection.execute(query)
  end
end
