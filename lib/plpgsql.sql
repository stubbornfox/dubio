create type holder as (count int, sentence bdd);

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

   FOR i IN 0..count
   LOOP
     r.count = i;
     r.sentence = bdd('x=1');
     RETURN NEXT r;
   END LOOP;
end;
$$;

-- TRASH --
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
