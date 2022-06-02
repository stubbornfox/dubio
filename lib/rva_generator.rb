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

    def rva_arr(number_of_random_variables=1, number_of_alternatives=0)
      alternative_arr = []

      if number_of_alternatives.to_i.zero?
        number_of_random_variables.times { alternative_arr << rand(2..4) }
      else
        alternative_arr =  [number_of_alternatives] * number_of_random_variables
      end

      rvs = self.rv_name(number_of_random_variables)
      rva_arr = []
      rvs.each_with_index do |rv, index|
        total = 0
        rv_ar = []
        number_of_alternatives = alternative_arr[index]
        max_p = 1
        (0...number_of_alternatives).each do |alternative|
          prob = rand(0.0..max_p)
          max_p = prob
          rv_ar  << [rv, alternative, prob]
          total += prob
        end
        rv_ar = rv_ar.each { |x| x[2] = x[2]/total;}.map{|x| "#{x[0]}=#{x[1]}:#{x[2]}"}
        rva_arr << rv_ar
      end

      rva_arr
    end

    def rva_str(number_of_random_variables=1, number_of_alternatives=0)
      alternative_arr = []

      if number_of_alternatives.to_i.zero?
        number_of_random_variables.times { alternative_arr << rand(2..4) }
      else
        alternative_arr =  [number_of_alternatives] * number_of_random_variables
      end

      rvs = self.rv_name(number_of_random_variables)
      rva_arr = []

      rvs.each_with_index do |rv, index|
        up = 1
        number_of_alternatives = alternative_arr[index]
        (0...number_of_alternatives).each do |alternative|
          prob = rand(0.0..up)
          up = prob
          rva_arr << "#{rv}=#{alternative}:#{prob}"
        end
      end

      rva_arr.join(';')
    end
  end
end
