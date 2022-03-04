class RvaGenerator
  class << self
    def rv_name(n)
      rvs = Set.new
      el = :a

      while rvs.size < n do
        rvs << el
        el = el.next
      end

      rvs
    end

    def rva_str(number_of_random_variables=1, number_of_alternatives=0)
      alternative_arr = []

      if number_of_alternatives.to_i.zero?
        number_of_random_variables.times { alternative_arr << rand(1..3) }
      else
        alternative_arr =  [number_of_alternatives] * number_of_random_variables
      end

      rvs = self.rv_name(number_of_random_variables)
      rva_arr = []

      rvs.each_with_index do |rv, index|
        total_prob = 0
        number_of_alternatives = alternative_arr[index]
        (0...number_of_alternatives).each do |alternative|
          up = 1 - total_prob
          prob = rand(0.0..up)
          rva_arr << "#{rv}=#{alternative}:#{prob}"
          total_prob += prob
        end
      end

      rva_arr.join(';')
    end
  end
end
