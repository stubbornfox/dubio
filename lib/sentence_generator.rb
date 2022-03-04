class SentenceGenerator
  def initialize(n, n_arity)
    @n= n
    @n_arity= n_arity || 1
    @rva_pairs = Dict.my_dict.rva_pairs.sample(n_arity + 2)
  end

  def make
    results = []
    @n.times do |_|
      begin
        @rva_set = Set.new
        rva_str = "#{single_atom}"

        (@n_arity-1).times do |_|
          rva_str += "#{['&', '|'].sample}#{single_atom}"
        end
      end while rva_str.in? results

      results << rva_str
    end
    results
  end

  def rva
    begin
      pair = @rva_pairs.sample
    end while pair.in? @rva_set

    @rva_set << pair
    pair
  end

  def single_atom
    "#{['', '!'].sample}#{rva}"
  end
end
