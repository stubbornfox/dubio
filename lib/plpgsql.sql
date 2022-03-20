create type holder as (count int, sentence bdd);

create or replace function exact_count(osql text)
returns  setof holder
language plpgsql
as
$$
declare
   i integer;
   j integer;

   counter integer;
   count integer;

   total_combination integer;

   record_indexes integer[];
   record_bdds bdd[];

   combination integer[];
   combination_length integer;
   combination_bdd bdd;

   count_bdds bdd[];
   r holder%rowtype;
begin
   EXECUTE osql INTO count;
   total_combination = power(2, count);

   record_indexes = ARRAY(SELECT id from cat_breeds);
   record_bdds = ARRAY(SELECT cat_breeds.sentence from cat_breeds);

   FOR i IN 0..count
   LOOP
      count_bdds[i] = bdd('0');
   END LOOP;

   FOR counter IN 0..total_combination - 1
   LOOP
      combination = ARRAY[]::integer[];

      combination_bdd = bdd('1');
      FOR i IN 0..count-1
      LOOP
         if (counter & (1<<i)) > 0 then
            combination = combination || record_indexes[i+1];
            combination_bdd = bdd(tostring(combination_bdd & record_bdds[i+1]));
         else
            combination_bdd = bdd(tostring(combination_bdd & !record_bdds[i+1]));
         end if;
      END LOOP;

      combination_length = cardinality(combination);
      count_bdds[combination_length] = bdd(tostring(count_bdds[combination_length]|combination_bdd));
   END LOOP;

   FOR i IN 0..count
   LOOP
      r.count = i;
      r.sentence = count_bdds[i];
      RETURN NEXT r;
   END LOOP;
end;
$$;

-- TRASH --

create or replace function exact_count(osql text)
returns  setof holder
language plpgsql
as
$$
declare
   i integer;
   j integer;

   counter integer;
   count integer;

   total_combination integer;

   record_indexes integer[];
   record_bdds text[];

   combination integer[];
   combination_length integer;
   combination_bdd text;

   count_bdds bdd[];
   r holder%rowtype;
begin
   EXECUTE osql INTO count;
   total_combination = power(2, count);

   record_indexes = ARRAY(SELECT id from cat_breeds);
   record_bdds = ARRAY(SELECT tostring(cat_breeds.sentence) from cat_breeds);

   FOR i IN 0..count
   LOOP
      count_bdds[i] = bdd(0);
      raise notice '%', i;
   END LOOP;

   FOR counter IN 0..total_combination - 1
   LOOP
      combination = ARRAY[]::integer[];

      combination_bdd = '';
      FOR i IN 0..count-1
      LOOP
         if (counter & (1<<i)) > 0 then
            combination = combination || record_indexes[i+1];
            combination_bdd = combination_bdd || '&' || '(' || record_bdds[i+1] || ')';
         else
            combination_bdd = combination_bdd || '&' ||  '(!' || '(' || record_bdds[i+1] || '))';
         end if;
      END LOOP;
      combination_bdd = ltrim(combination_bdd, '&');
      raise notice '%', combination;
      raise notice '%', combination_bdd;
      combination_length = cardinality(combination);
      count_bdds[combination_length] = select count_bdds[combination_length] | bdd(combination_bdd);
   END LOOP;

   FOR i IN 0..count
   LOOP
      count_bdds[i] = ltrim(count_bdds[i], '|');
      r.count = i;
      r.sentence = count_bdds[i];
      RETURN NEXT r;
   END LOOP;

   raise notice '%', count_bdds;
end;
$$;
create or replace function exact_count(osql text)
returns  setof holder
language plpgsql
as
$$
declare
   i integer;
   count integer;
   r holder%rowtype;
begin
   EXECUTE osql INTO count;
   select id from cat_breeds into set_id;
   FOR i IN 0..count
   LOOP
     r.count = i << 1;
     r.sentence = bdd('x=1');
     RETURN NEXT r;
   END LOOP;
end;
$$;
create  or replace function exact_count(osql text)
returns table (
   count int,
   sentence bdd
)
language plpgsql
as
$$
declare
   i integer;
begin
   EXECUTE osql INTO count;

   FOR i IN 0..count
   LOOP
     count = i;
     sentence = bdd('x=1');
     RETURN NEXT;
   END LOOP;
end;
$$;


create  or replace function exact_count(osql text)
returns table (
   count int
   sentence bdd,
) 
language plpgsql
as
$$
declare
   result table;
begin
   EXECUTE osql INTO count;
   return count;
end;
$$;

CREATE OR REPLACE FUNCTION public.exec(
text)
RETURNS SETOF RECORD
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN 
    RETURN QUERY EXECUTE $1 ; 
END 
$BODY$;
