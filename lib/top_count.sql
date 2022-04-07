create type topholder as (count text, sentence bdd, prob float);
-- DROP FUNCTION hist_count(text);

create or replace function top_count(equery text, topk integer)
RETURNS SETOF topholder
language plpgsql
as
$$
declare
   i integer;
   j integer;

   counter integer;
   count integer;

   total_combination integer;

   -- record_indexes integer[];
   record_bdds bdd[];

   -- combination integer[];
   combination_length integer;
   combination_bdd bdd;

   count_bdds bdd[];
   result topholder[];
   r topholder%rowtype;
   rec1 record;
   mydict dictionary;
begin
   EXECUTE equery INTO rec1;
   select dict from dicts WHERE dicts.name='mydict' into mydict;
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


   FOR counter IN 0..total_combination - 1
   LOOP
      -- combination = ARRAY[]::integer[];
      combination_length = 0;
      combination_bdd = bdd('1');
      FOR i IN 0..count-1
      LOOP
         if (counter & (1<<i)) > 0 then
            combination_length = combination_length + 1;
            combination_bdd = bdd(tostring(combination_bdd & record_bdds[i+1]));
         else
            combination_bdd = bdd(tostring(combination_bdd & !record_bdds[i+1]));
         end if;
      END LOOP;

      count_bdds[combination_length] = bdd(tostring(count_bdds[combination_length]|combination_bdd));
   END LOOP;

   FOR i IN 0..count
   LOOP
      result[i].count = i;
      result[i].sentence = count_bdds[i];
      result[i].prob = prob(mydict,r.sentence);
   END LOOP;

   FOR i IN 0..count
   LOOP
      r.count = i;
      r.sentence = count_bdds[i];
      r.prob = prob(mydict,r.sentence);
      raise notice '%', r.prob;
      RETURN NEXT r;
   END LOOP;
end;
$$;

