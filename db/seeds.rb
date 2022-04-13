# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
Dict.find_or_create_by(name: 'mydict')
Dict.my_dict.clear
Dict.my_dict.add_rva(RVA_50_WITH_PROB.flatten.join(';'))

# Generate database for experiment a
cats = []
RVA_50.each_with_index do |rv, name_index|
  rv.each_with_index do |rva, breed_index|
    cats << [CAT_NAME[name_index], CAT_BREED[breed_index], rva]
  end
end

puts cats


# Generate database for experiment b

# NUMBER_OF_TUPLES = 50
# n_rv = 1
# n_tuples = 0
# cats = []

# while n_rv < 3
#   while n_tuples < NUMBER_OF_TUPLES
#     RVA_50[0..n_rv].each_with_index do |rv, name_index|
#       rv.each_with_index do |rva, breed_index|
#         cats << [CAT_NAME[name_index], CAT_BREED[breed_index], rva]
#       end
#       n_tuples += rv.size
#     end
#   end
#   puts n_rv
#   puts cats[0..NUMBER_OF_TUPLES]
# end


