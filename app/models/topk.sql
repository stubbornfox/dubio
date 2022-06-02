

#list_of_rva ="{'d=0:0.800000; d=1:0.100000; d=2:0.100000;', 'x=0:0.600000; x=1:0.400000;', 'y=0:0.500000; y=1:0.500000;'}";

-- @Jan
-- This function return dictionary in array
-- output example: ['d=0:0.800000; d=1:0.100000; d=2:0.100000', 'x=0:0.600000; x=1:0.400000', 'y=0:0.500000; y=1:0.500000']

create or replace function extract_dict(dict dictionary)
RETURNS text[]
language plpgsql
as
$$
declare
  list_of_rva text[];
  dict_row text;
  rv_e text;
begin
  select print(dict) into dict_row;
  select string_to_array(dict_row, ';'||chr(32)||chr(10)) into list_of_rva;
  -- remove the last empty "";
  list_of_rva = (select list_of_rva[1:array_upper(list_of_rva, 1) - 1]);
  return list_of_rva;
end;
$$;
---
---[[0.800000; 0.100000; 0.100000],..., [0.2, 0.3]]
create type prob as (p float[], rva text[]);
create or replace function extract_prob(dict dictionary)
RETURNS prob[]
language plpgsql
as
$$
declare
  list_of_rva text[];
  temp text[];
  i_rv text;
  i_temp text;
  i int;
  return_prob prob[];
  i_prob float;
  i_rva text;
begin
  list_of_rva = ARRAY(select extract_dict(dict));
  i = 0;
  return_prob = ARRAY[]::prob[];
  FOREACH i_rv in ARRAY(list_of_rva)
  LOOP
    return_prob[i].p = ARRAY[]::float[];
    return_prob[i].rva = ARRAY[]::text[];
    temp = string_to_array(i_rv, '; ', '');
    FOREACH i_temp in ARRAY(temp)
    LOOP
     i_prob = CAST(split_part(i_temp::TEXT,':', 2) as float);
     i_rva = split_part(i_temp::TEXT,':', 1);

     return_prob[i].p = return_prob[i].p || i_prob;
     return_prob[i].rva = return_prob[i].rva || i_rva;
    END LOOP;
    i = i+1;
  END LOOP;

  return return_prob;
end;
$$;

create type world_prob as (indexes int[], sentence text, prob float);
create type heap_worlds as(heap_size int, heap_arr world_prob[]);

create or replace function heap_push(hw heap_worlds, new_world world_prob)
RETURNS heap_worlds
language plpgsql
as
$$
declare
  curr int;
  r record;
BEGIN
  -- hw.heap_arr =  hw.heap_arr || new_world;
  hw.heap_arr[hw.heap_size] = new_world;
  curr = hw.heap_size;

  -- raise notice 'hw.heap_arr[(curr-1)/2].prob %', (hw.heap_arr[(curr-1)/2].prob);
  -- raise notice 'hw.heap_arr[curr].prob %', (hw.heap_arr[curr].prob);

  WHILE(curr > 0 and hw.heap_arr[(curr-1)/2].prob < hw.heap_arr[curr].prob) LOOP

      r = hw.heap_arr[(curr-1)/2];
      hw.heap_arr[(curr-1)/2] = hw.heap_arr[curr];
      hw.heap_arr[curr] = r;

      curr = (curr-1)/2;
  END LOOP;

  hw.heap_size = hw.heap_size + 1;
  return hw;
END
$$;

create or replace function heap_pop(hw heap_worlds, OUT owp world_prob, OUT nhw heap_worlds)
language plpgsql
as
$$
declare
  curr int;
  child int;
  temp record;
BEGIN
  owp := hw.heap_arr[0];
  hw.heap_arr[0] = hw.heap_arr[hw.heap_size - 1];
  hw.heap_size = hw.heap_size - 1;

  curr = 0;

  while((2*curr+1) < hw.heap_size) LOOP
      IF((2*curr+2) = hw.heap_size) THEN
          child = 2*curr+1;
      ELSE
        IF (hw.heap_arr[2*curr+1].prob > hw.heap_arr[2*curr+2].prob) THEN
          child = 2*curr+1;
        ELSE
          child = 2*curr+2;
        END IF;
      END IF;


      IF (hw.heap_arr[curr].prob < hw.heap_arr[child].prob) THEN
          temp = hw.heap_arr[curr];
          hw.heap_arr[curr] = hw.heap_arr[child];
          hw.heap_arr[child] = temp;
          curr = child;
      ELSE
        EXIT;
      END IF;
  END LOOP;

  nhw := hw;
  return;
END
$$;

create or replace function get_alter(indexes int[], probs prob[])
RETURNS text
language plpgsql
as
$$
declare
  count int;
  ind int;
  rvas text[];
BEGIN
  count = 0;

  FOREACH ind in ARRAY(indexes) LOOP
    count =  count + 1;
    rvas = rvas || probs[count].rva[ind];
  END LOOP;

  RETURN array_to_string(rvas, '&');
END
$$;

-- This return the top possible worlds
-- Required!: dictionary is sorted by prob
-- Input: dict & k
-- Output example:
-- {{prob: 0.4, bdd(a=1&b=1&c=0)}, {prob: 0.35, bdd(a=1&b=1&c=2)},...}



create or replace function top_k_worlds(dict dictionary, k int)
RETURNS SETOF world_prob
language plpgsql
as
$$
declare
  list_of_rva text[];
  lists text[][];
  list_of_length int[];

  i_rv text;
  i int;
  n_of_rv int;
  heap_list world_prob[];
  wp world_prob;
  lwp world_prob;
  temp text[];
  i_prob_f float;
  rva text;
  probs prob[];
  xprobs prob[];
  i_prob prob;
  i_k int;
  hw heap_worlds;
  r record;
  ind int[];
  next_ind int[];
  next_wp world_prob;
  seens text[];
BEGIN
  list_of_rva = ARRAY(select extract_dict(dict));
  xprobs = ARRAY[]::prob[];
  probs = ARRAY(select extract_prob(dict));
  i = 0;

  wp.prob = 1;
  -- wp.sentence = bdd('1');
  FOREACH i_prob in ARRAY(probs)
  LOOP
    xprobs = xprobs || i_prob;
    i = i+1;
    i_prob_f = i_prob.p[1];
    wp.indexes = wp.indexes || 1;
    wp.prob = wp.prob * i_prob_f;
    -- wp.sentence = wp.sentence & bdd(i_prob.rva[1]);
    list_of_length[i] = cardinality(i_prob.p);
  END LOOP;

  n_of_rv = i;

  hw.heap_size = 0;
  hw.heap_arr = ARRAY[]::world_prob[];

  hw = heap_push(hw, wp);

  i_k = 0;
  seens = seens || array_to_string(wp.indexes, ',');
  WHILE i_k < k and hw.heap_size > 0
  LOOP
    select * from heap_pop(hw) into r;
    -- raise notice 'hw after pop: %', hw.heap_arr[:hw.heap_size];
    lwp = r.owp;
    hw = r.nhw;

    ind = lwp.indexes;

    FOR i IN 1..n_of_rv
    LOOP

      IF list_of_length[i] >= ind[i] + 1 THEN
        next_ind = ind;
        next_ind[i] = next_ind[i] + 1;
        i_prob = xprobs[i];
      ELSE
        CONTINUE;
      END IF;

      IF NOT (array_to_string(next_ind, ',') = ANY (seens)) THEN
        next_wp.indexes = next_ind;
        next_wp.prob = (lwp.prob * xprobs[i].p[next_ind[i]]) / xprobs[i].p[next_ind[i]-1];
        hw = heap_push(hw, next_wp);
        seens = seens || array_to_string(next_ind, ',');
      END IF;
        -- raise notice 'hw: %', hw.heap_arr[:hw.heap_size];
    END LOOP;
    lwp.sentence = get_alter(lwp.indexes, xprobs);
    RETURN NEXT lwp;
    i_k := i_k + 1;
  END LOOP;
END;
$$;
