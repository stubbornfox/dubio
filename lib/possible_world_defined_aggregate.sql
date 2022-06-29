--https://www.postgresql.org/docs/current/xaggr.html


CREATE OR REPLACE FUNCTION rand_vars(bdd bdd)
RETURNS text[]
language plpgsql
as
$$
DECLARE
  rv_array text[];
begin
   rv_array = ARRAY(select distinct REGEXP_MATCHES(tostring(bdd), '(\w+)=', 'g') order by 1 asc);
   return ARRAY(Select unnest(rv_array));
end;
$$;

CREATE OR REPLACE FUNCTION get_alternatives(rva text[], dict dictionary)
RETURNS TEXT[]
language plpgsql
as
$$
DECLARE
   rv_e text;
   alternatives_arr text[];
   alternative_i text;
   alternatives_str text;
   result text[];
begin
   result = ARRAY[]::text[];
   FOREACH rv_e in ARRAY(rva)
   LOOP
      select alternatives(dict, CAST (rv_e AS cstring)) into alternatives_str;
      alternatives_arr = string_to_array(alternatives_str, ',');
      FOREACH alternative_i in ARRAY(alternatives_arr)
      LOOP
         result = result || (rv_e || '=' || alternative_i);
      END LOOP;
   END LOOP;
   return ARRAY(select unnest(result));
end;
$$;

CREATE OR REPLACE FUNCTION count_on_worlds(list_of_worlds count_prob[], sentence bdd, dict dictionary)
RETURNS wholder[]
LANGUAGE PLPGSQL
AS
$$
DECLARE
   alternative text;
   alternative_str text;
   alternatives text[];
   new_alternatives text[];
   i_world wholder;
   result wholder[];
   temp text;
   changed boolean;
   r count_prob%rowtype;
BEGIN
   result = ARRAY[]::wholder[];
   new_alternatives = ARRAY[]::text[];
   select rand_vars(sentence) into alternatives;
   temp = array_to_string(list_of_worlds, ',');

   changed = false; -- THIS TO CHECK IF THE WORLD WILL CHANGE WHEN THE NEW SENTENCE COMING

   FOREACH alternative in ARRAY(alternatives)
   LOOP
      alternative_str = alternative || '=';
      -- raise notice 'exist : %', (temp ~ alternative_str);
      -- raise notice 'alternative_str %', alternative_str;

      IF NOT (temp ~ alternative_str) THEN
         new_alternatives = new_alternatives || alternative;
         changed = true;
      END IF;
   END LOOP;

   -- raise notice '% new alternatives: ', new_alternatives;
   select get_alternatives(new_alternatives, dict) into alternatives;
   -- raise notice '% alternatives: ', alternatives;

   -- raise notice 'arr length low: %', array_length(list_of_worlds, 1);

   IF array_length(list_of_worlds, 1) IS NULL THEN
      r.count = 0;
      r.sentence = bdd('1');
      list_of_worlds = list_of_worlds || r;
   end IF;
   -- result = list_of_worlds;
   -- raise notice 'list_of_worlds: %', list_of_worlds;

   IF not changed THEN -- IF THE WORLDS DO NOT CHANGE THEN JUST CALCULATE THE SENTENCE IN EACH WORLDS
      FOREACH i_world in ARRAY(list_of_worlds)
      LOOP
         r.sentence = i_world.sentence;
         IF bdd_equal(sentence&i_world.sentence, i_world.sentence) THEN
            r.count = i_world.count + 1;
         ELSE
            r.count = i_world.count;
         END IF;
         result = result || r;
      END LOOP;

      -- raise notice '% results: ', result;
      RETURN result;
   ELSE -- IF THE WORLDS CHANGE, THEN CALCULATE THE WORLD, AND THE SENTENCE IN EACH WORLDS
      FOREACH i_world in ARRAY(list_of_worlds)
      LOOP
         FOREACH alternative in ARRAY(alternatives)
         LOOP
            r.sentence = i_world.sentence & bdd(alternative);

            IF bdd_equal(sentence&r.sentence, r.sentence) THEN -- IF THE SENTENCE IS TRUE IN THIS WORLD, INCREASE IT COUNTS
               r.count = i_world.count + 1;
            ELSE
               r.count = i_world.count;
            END IF;
            result = result || r;
         END LOOP;
      END LOOP;

      -- raise notice '% results: ', result;
      RETURN result;
   END IF;
END
$$;


CREATE OR REPLACE AGGREGATE count_worlds(sentence bdd, dict dictionary)(
   stype = table,
   sfunc = count_on_worlds,
   initcond = '{}'
);


