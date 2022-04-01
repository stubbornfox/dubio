create type binholder as (count text, sentence bdd);
-- DROP FUNCTION hist_count(text);

create or replace function hist_count(equery text, bin integer)
RETURNS SETOF binholder
language plpgsql
as
$$
declare
   i integer;
   j integer;

   counter integer;
   count integer;

   start_bin integer;
   end_bin integer;
   bin_size integer;

   total_combination integer;

   -- record_indexes integer[];
   record_bdds bdd[];

   -- combination integer[];
   combination_length integer;
   combination_bdd bdd;

   count_bdds bdd[];
   r binholder%rowtype;
   rec1 record;
begin
   EXECUTE equery INTO rec1;
   count = 0;
   record_bdds = ARRAY[]::bdd[];

   FOR rec1 in EXECUTE equery
   LOOP
      -- raise notice '%', rec1.id;
      -- record_indexes = record_indexes || rec1.id;
      record_bdds = record_bdds || rec1.sentence;
      count_bdds[count] = bdd('0');
      count = count + 1;
   END LOOP;
   count_bdds[count] = bdd('0');
   total_combination = power(2, count);

   if (bin = 0) then
      raise exception 'Bin is zero';
   end if;

   if (bin > count) then
      bin = count;
   end if;

   bin_size = (count+1)/bin;
   start_bin = 0;
   end_bin = bin_size - 1;
   raise notice '%', start_bin;
   raise notice '%', end_bin;


   FOR counter IN 0..total_combination - 1
   LOOP
      -- combination = ARRAY[]::integer[];
      combination_length = 0;
      combination_bdd = bdd('1');
      FOR i IN 0..count-1
      LOOP
         if (counter & (1<<i)) > 0 then
            -- combination = combination || record_indexes[i+1];

            -- raise notice '%', tostring(combination_bdd & record_bdds[i+1]);
            -- raise notice '%', bdd(tostring(combination_bdd & record_bdds[i+1]));
            combination_length = combination_length + 1;
            combination_bdd = bdd(tostring(combination_bdd & record_bdds[i+1]));
         else
            combination_bdd = bdd(tostring(combination_bdd & !record_bdds[i+1]));
            -- raise notice '%', tostring(combination_bdd & !record_bdds[i+1]);
            -- raise notice '%', bdd(tostring(combination_bdd & !record_bdds[i+1]));
         end if;
      END LOOP;

      -- combination_length = cardinality(combination);
      -- raise notice '%', tostring(count_bdds[combination_length]|combination_bdd);
      -- raise notice '%', bdd(tostring(count_bdds[combination_length]|combination_bdd));
      count_bdds[combination_length] = bdd(tostring(count_bdds[combination_length]|combination_bdd));
   END LOOP;
   j = 0;
   FOR i IN 1..bin
   LOOP
      combination_bdd = bdd('0');
      raise notice 'i: %', i;

      FOR j IN start_bin..end_bin
      LOOP
         raise notice 'bdd j: %', count_bdds[j];
         raise notice 'bdd string: %', tostring(combination_bdd | count_bdds[j]);
         raise notice 'bdd: %',  bdd(tostring(combination_bdd | count_bdds[j]));
         combination_bdd = bdd(tostring(combination_bdd | count_bdds[j]));
      END LOOP;

      r.count =  start_bin ||' - '|| end_bin;
      r.sentence = combination_bdd;
      RETURN NEXT r;
      start_bin = end_bin + 1;
      end_bin = least(end_bin + bin_size, count);
   END LOOP;
end;
$$;

