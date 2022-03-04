class TupleGenerator
  class << self
    def bdd_str(n, n_arity)
      results = []
      n_arity ||= 1

      dicts = Dict.my_dict.rva
      length(dicts)

      n.times do |_|
        bdd_str = ''


        n_arity.times { |_|
          bdd_str = rand(1..)
        }

        results << bdd_str
      end

    end
  end
end
