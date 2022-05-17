DROP FUNCTION listrv(text);


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


CREATE OR REPLACE FUNCTION get_alternatives(rva text, dict_row text)
RETURNS TEXT[]
language plpgsql
as
$$
DECLARE
begin
   return (ARRAY(select distinct unnest(REGEXP_MATCHES(dict_row, '('|| rva || '=\d+)', 'g'))));
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

CREATE OR REPLACE FUNCTION create_worlds(list_of_worlds text[], sentence bdd, dict dictionary)
RETURNS text[]
LANGUAGE PLPGSQL
AS
$$
DECLARE
   alternative text;
   alternative_str text;
   alternatives text[];
   new_alternatives text[];
   i_world text;
   result text[];
   temp text;
   changed boolean;
BEGIN
   result = ARRAY[]::text[];
   new_alternatives = ARRAY[]::text[];
   select rand_vars(sentence) into alternatives;
   temp = array_to_string(list_of_worlds, ',');
   changed = false;
   FOREACH alternative in ARRAY(alternatives)
   LOOP
      alternative_str = alternative || '=';
      raise notice 'exist : %', (temp ~ alternative_str);
      raise notice 'alternative_str %', alternative_str;

      IF NOT (temp ~ alternative_str) THEN
         new_alternatives = new_alternatives || alternative;
         changed = true;
      END IF;
   END LOOP;

   raise notice '% new alternatives: ', new_alternatives;
   select get_alternatives(new_alternatives, dict) into alternatives;
   raise notice '% alternatives: ', alternatives;

   IF not changed THEN
      return list_of_worlds;
   ELSE
      FOREACH alternative in ARRAY(alternatives)
      LOOP
         FOREACH i_world in ARRAY(list_of_worlds)
         LOOP
            result = result || (i_world || ',' || alternative);
         END LOOP;
      END LOOP;

      raise notice '% results: ', result;
      RETURN result;
   END IF;
END
$$;


CREATE OR REPLACE AGGREGATE worlds(sentence bdd, dict dictionary)(
   stype = text[],
   sfunc = create_worlds,
   initcond = '{""}'
);

DROP FUNCTION possible_worlds(text, text[]);

CREATE OR REPLACE FUNCTION possible_worlds(dict_name text, used_rv text[])
RETURNS text[]
language plpgsql
as
$$
DECLARE
  rv_array text[];
  dict_row text;
  rv_str text;
  arr int[];
  possible_worlds int[];
  a int;
  rv_e text;
  possible_worlds_count int;
  n int;
  i int;
  j int;
  sum int;
  return_worlds text[];
begin
   select print(dict) from dicts where name=dict_name into dict_row;
   rv_array = ARRAY(select distinct REGEXP_MATCHES(dict_row, '(['|| array_to_string(used_rv, ',')||']+=\d+)', 'g'));
   rv_array = ARRAY(Select unnest(rv_array));
   rv_str = array_to_string(rv_array, ',');

   FOREACH rv_e in ARRAY used_rv
   LOOP
      SELECT count(*) FROM regexp_matches(rv_str, rv_e || '=', 'g') into a;
      arr = arr || a;
   END LOOP;

   -- raise notice '%', arr;
   possible_worlds = build_possible_worlds(arr);
   -- raise notice 'possible_worlds %', possible_worlds;

   -- raise notice 'rv_array %', (SELECT pg_typeof(rv_array));
   -- raise notice 'rv_array %', rv_array;
   -- raise notice 'rv_array %', rv_array[1];
   -- raise notice 'rv_array %', rv_array[2];

   possible_worlds_count = array_length(possible_worlds, 1);
   n = array_length(arr, 1);
   sum = 0;
   FOR i in 0..possible_worlds_count/n -1
   LOOP
      sum = 1;
      return_worlds[i] = '';
      FOR j in 0..n - 1
      LOOP
         -- raise notice 'n*i+j+1 %', (n*i+j+1);
         -- raise notice 'sum %', sum;
         -- raise notice 'j: %', (sum + possible_worlds[n*i+j+1]);
         -- raise notice 'j element: %',rv_array[sum + possible_worlds[n*i+j+1]];
         return_worlds[i] = return_worlds[i] || rv_array[sum + possible_worlds[n*i+j+1]]|| '&';
         sum = sum + arr[j+1];
      END LOOP;
      -- raise notice 'end';
   END LOOP;

   return return_worlds;
end;
$$;

DROP FUNCTION build_possible_worlds(int[]);

create or replace function build_possible_worlds(arr_of_alternatives int[])
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
   n = array_length(arr_of_alternatives, 1);
   -- raise notice 'n: %', n;
   -- raise notice 'arr: %', arr_of_alternatives;
   -- raise notice 'al[0] %', arr_of_alternatives[0];
   -- raise notice 'al[1] %', arr_of_alternatives[1];
   -- raise notice 'al[2] %', arr_of_alternatives[2];
   -- raise notice 'al[3] %', arr_of_alternatives[3];

   indices = ARRAY[]::integer[];

   FOR i in 0..n-1
   LOOP
      indices[i] = 0;
   END LOOP;

   WHILE 1 LOOP
      FOR i in 0..n-1
      LOOP
         return_worlds = return_worlds || indices[i];
         -- raise notice 'indices %', indices[i];
      END LOOP;

      next = n-1;

      WHILE ((next >= 0) AND (indices[next] + 1 >= arr_of_alternatives[next+1]))
      LOOP
         next = next - 1;
         -- raise notice 'next-- %', next;
      END LOOP;

      IF (next < 0) THEN
        return return_worlds;
      END IF;

      indices[next] = indices[next] + 1;
      -- raise notice 'indices[next] ++ %', indices[next];

      FOR j in next+1..n-1
      LOOP
         indices[j] = 0;
      END LOOP;
   END LOOP;

  return return_worlds;
end;
$$;

create or replace function possible_world_count(equery text, dict_name text)
RETURNS SETOF holder
language plpgsql
as
$$
declare
   record_bdds bdd[];
   current_dicts dictionary[];
   used_rv text[];
   return_worlds text[];
   world bdd;
   i_world text;
   rec1 record;
   r holder%rowtype;
   possible_worlds_count int;
   r_bdd bdd;
   count int;
   i int;
begin
   FOR rec1 in EXECUTE equery
   LOOP
      record_bdds = record_bdds || rec1.sentence;
   END LOOP;


   used_rv = listrv(array_to_string(record_bdds, ','));
   -- raise notice 'used_rv %', used_rv;
   return_worlds = possible_worlds(dict_name, used_rv);
   possible_worlds_count = array_length(return_worlds, 1);
   -- raise notice '%', possible_worlds_count;
   -- raise notice '%', return_worlds;

   FOREACH i_world IN ARRAY(return_worlds)
   LOOP
      world = bdd(rtrim(i_world, '&'));
      count = 0;
      FOREACH r_bdd IN ARRAY(record_bdds)
      LOOP
         -- raise notice 'tostring(bdd(tostring(r_bdd & bdd(world)))) %', tostring(bdd(tostring(r_bdd & world)));
         -- raise notice 'world %', world;
         IF tostring(bdd(tostring(r_bdd & bdd(world)))) = tostring(world) THEN
            count = count + 1;
         END IF;
      END LOOP;
      r.count = count;
      r.sentence = world;
      if not isfalse(r.sentence) THEN
         RETURN NEXT r;
      END IF;
   END LOOP;
end;
$$;
