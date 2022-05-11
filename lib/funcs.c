// #include "postgres.h"
// #include "fmgr.h"
#include "pg_config.h"  
#include "bdd.c"

PG_MODULE_MAGIC;

// PG_FUNCTION_INFO_V1(add_one);

// Datum
// add_one(PG_FUNCTION_ARGS)
// {
//     int32   arg = PG_GETARG_INT32(0);

//     PG_RETURN_INT32(arg + 1);
// }


PG_FUNCTION_INFO_V1(random_vars);

Datum
random_vars(PG_FUNCTION_ARGS)
{

}


// CREATE FUNCTION add_one(integer) RETURNS integer
// AS '/Users/sushi/Course/Masterrrrrr/dubio/funcs', 'add_one'
// LANGUAGE C STRICT;
