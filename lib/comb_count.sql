create or replace function comb_count(equery text, dict dictionary)
RETURNS SETOF count_prob
language plpgsql
as
$$
declare
   i integer;
   j integer;

   counter integer;
   count integer;

   total_combination integer;
   record_bdds bdd[];

   combination_length integer;
   combination_bdd bdd;
   textbdd bdd;

   count_bdds bdd[];
   r count_prob%rowtype;
   rec1 record;
begin
   EXECUTE 'SELECT ARRAY('||equery ||')' INTO record_bdds;
   count = CARDINALITY(record_bdds);
   raise notice 'count %', count;
   total_combination = power(2, count);


   FOR counter IN 0..total_combination - 1
   LOOP
      combination_length = 0;
      combination_bdd = bdd('1');
      FOR i IN 0..count-1
      LOOP
         if (counter & (1<<i)) > 0 then
            combination_length = combination_length + 1;
            combination_bdd = _op_bdd_by_text('&', combination_bdd, record_bdds[i+1]);
         else
            combination_bdd = _op_bdd_by_text('&', combination_bdd, !record_bdds[i+1]);
         end if;
      END LOOP;
      r.count = combination_length;
      r.sentence = tostring(combination_bdd);
      -- and prob(dict,combination_bdd) > 0
      IF not isfalse(combination_bdd) then
         return next r;
      end If;
   END LOOP;
end;
$$;

