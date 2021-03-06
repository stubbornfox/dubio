DROP FUNCTION listrv(text);

-- List all random variables in the sentence, Ex:
-- select * from list_rv('b=2&a=1&!a=2');
-- return {a, b}

CREATE OR REPLACE FUNCTION list_rv(bdd_str text)
RETURNS cstring[]
language plpgsql
as
$$
DECLARE
  rv_array cstring[];
begin
   rv_array = ARRAY(select distinct REGEXP_MATCHES(bdd_str, '(\w+)=', 'g') order by 1 asc);
   return ARRAY(Select unnest(rv_array));
end;
$$;

-- Ref source https://www.geeksforgeeks.org/combinations-from-n-arrays-picking-one-element-from-each-array/

-- List all combinations from array of alternatives, Ex:
-- dict = {a=1, a=2; b=1, b=2, b=3;} => a has 2 alternatives, b has 3 alternatives
-- select combination_from_alternatives('{2, 3}')
-- returns {0,0,0,1,0,2,1,0,1,1,1,2}
-- which can be interpreted as {[0,0], [0,1], [0,2], [1,0], [1,1], [1,2]}
-- presenting a combination of indexes for each alternatives

CREATE OR REPLACE FUNCTION combination_from_alternatives(no_of_alternatives_arr int[])
RETURNS int[]
language plpgsql
as
$$
DECLARE
   return_worlds int[];
   n int;
   indices int[];
   j int;
   i int;
   next int;
begin
   n = array_length(no_of_alternatives_arr, 1);
   indices = ARRAY[]::integer[];

   FOR i in 0..n-1
   LOOP
      indices[i] = 0;
   END LOOP;

   WHILE 1 LOOP
      FOR i in 0..n-1
      LOOP
         return_worlds = return_worlds || indices[i];
      END LOOP;

      next = n-1;

      WHILE ((next >= 0) AND (indices[next] + 1 >= no_of_alternatives_arr[next+1]))
      LOOP
         next = next - 1;
      END LOOP;

      IF (next < 0) THEN
        return return_worlds;
      END IF;

      indices[next] = indices[next] + 1;

      FOR j in next+1..n-1
      LOOP
         indices[j] = 0;
      END LOOP;
   END LOOP;

  return return_worlds;
end;
$$;

-- Build possible worlds from dictionary & used random variables(variables appear in the table)
-- This extract the number of alternatives of each random variables
-- mapping the index from combination_from_alternatives() to the real value of alternatives. Ex:

-- select possible_worlds(dict, '{a, b}') from dicts where dicts.name='mydict';
-- return {a=0&b=0,a=0&b=1,a=0&b=2,a=1&b=0,a=1&b=1,a=1&b=2}

DROP FUNCTION possible_worlds(text, cstring[]);
CREATE OR REPLACE FUNCTION possible_worlds(dict dictionary, used_rv cstring[])
RETURNS text[]
language plpgsql
as
$$
DECLARE
  rv_array text[];
  -- rv_str text;
  arr int[];
  combinations int[];
  rv_e text;
  no_of_possible_worlds int;
  no_of_used_rv int;
  i int;
  j int;
  offset_index int;
  return_worlds text[];
  alternatives_str text;
  alternatives_arr text[];
  alternative_i text;
begin
   FOREACH rv_e in ARRAY used_rv
   LOOP
      select alternatives(dict, CAST (rv_e AS cstring)) into alternatives_str;
      alternatives_arr = string_to_array(alternatives_str, ',');
      FOREACH alternative_i in ARRAY(alternatives_arr)
      LOOP
         rv_array = rv_array || (rv_e || '=' || alternative_i);
      END LOOP;
      arr = arr || array_length(alternatives_arr, 1);
   END LOOP;
   raise notice 'rv_array %', rv_array;

   combinations = combination_from_alternatives(arr);
   no_of_used_rv = array_length(used_rv, 1);
   no_of_possible_worlds = array_length(combinations, 1) / no_of_used_rv;


   FOR i in 0..no_of_possible_worlds - 1
   LOOP
      offset_index = 1;
      return_worlds[i] = '';
      FOR j in 1..no_of_used_rv
      LOOP
         return_worlds[i] = return_worlds[i] || rv_array[offset_index + combinations[no_of_used_rv*i+j]] || '&';
         offset_index = offset_index + arr[j];
      END LOOP;
      return_worlds[i] = rtrim(return_worlds[i], '&');
   END LOOP;

   return return_worlds;
end;
$$;

--  select dict, * from dicts, count_on_possible_worlds('select * from cat_breeds', dict) where dicts.name='mydict';
-- return
-- (1,"Bdd((a=0&b=0))",{65945})
-- (2,"Bdd((a=0&b=1))","{65945,65948}")
-- (1,"Bdd((a=0&b=2))",{65945})

create type wholder as (count int, sentence bdd, ids int[]);

create or replace function count_on_possible_worlds(equery text, dict dictionary)
RETURNS SETOF wholder
language plpgsql
as
$$
declare
   record_bdds bdd[];
   current_dicts dictionary[];
   used_rv cstring[];
   return_worlds text[];
   world_str text;
   world_bdd bdd;
   rec1 record;
   r wholder%rowtype;
   r_bdd bdd;
   count int;
   i int;
   ids bigint[];
   record_ids bigint[];
   id int;
begin
   FOR rec1 in EXECUTE equery
   LOOP
      record_bdds = record_bdds || rec1.sentence;
      record_ids = record_ids ||rec1.id;
   END LOOP;

   used_rv = list_rv(array_to_string(record_bdds, ','));

   return_worlds = possible_worlds(dict, used_rv);

   FOREACH world_str IN ARRAY(return_worlds)
   LOOP
      world_bdd = bdd(world_str);
      count = 0;
      id = 0;
      ids = ARRAY[]::integer[];
      FOREACH r_bdd IN ARRAY(record_bdds)
      LOOP
         id = id + 1;
         IF bdd_equal(r_bdd&world_bdd, world_bdd) THEN
            count = count + 1;
            ids = ids || record_ids[id];
         END IF;
      END LOOP;
      r.count = count;
      r.sentence = world_bdd;
      r.ids = ids;
      if not isfalse(r.sentence) THEN
         RETURN NEXT r;
      END IF;
   END LOOP;
end;
$$;
