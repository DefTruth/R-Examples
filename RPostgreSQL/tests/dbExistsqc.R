
## dbExistsq test with schema name: reported as Issue 28 at
## http://code.google.com/p/rpostgresql/issues/detail?id=28
##
## Assumes that
##  a) PostgreSQL is running, and
##  b) the current user can connect
## both of which are not viable for release but suitable while we test
##
## Dirk Eddelbuettel, 10 Sep 2009

## only run this if this env.var is set correctly
if (Sys.getenv("POSTGRES_USER") != "" & Sys.getenv("POSTGRES_HOST") != "" & Sys.getenv("POSTGRES_DATABASE") != "") {

    ## try to load our module and abort if this fails
    stopifnot(require(RPostgreSQL))
    stopifnot(require(datasets))

    ## load the PostgresSQL driver
    drv <- dbDriver("PostgreSQL")

    ## connect to the default db
    con <- dbConnect(drv,
                     user=Sys.getenv("POSTGRES_USER"),
                     password=Sys.getenv("POSTGRES_PASSWD"),
                     host=Sys.getenv("POSTGRES_HOST"),
                     dbname=Sys.getenv("POSTGRES_DATABASE"),
                     port=ifelse((p<-Sys.getenv("POSTGRES_PORT"))!="", p, 5432))

    if (dbExistsTable(con, "rock.data")) {
        cat("Removing rock'data\n")
        dbRemoveTable(con, "rock.data")
    }


    dbWriteTable(con, "rock.data", rock)
    ## run a simple dbExists
    cat("Does rock.data exist? \n")
    res <- dbExistsTable(con, "rock.data")
    if(res){
      cat("PASS: true\n")
    }else{
      cat("FAIL: false\n")
    }

    ## 
    cat("create schema testschema and change the search_path\n")

    dbGetQuery(con, 'CREATE SCHEMA testschema')
    dbGetQuery(con, 'SET search_path TO testschema')
    cat("Does rock.data exist? \n")
    res <- dbExistsTable(con, "rock.data")
    if(res){
      cat("FAIL: true despite search_path change\n")
    }else{
      cat("PASS: false as the search_path changed\n")
    }

    cat("Does testschema.\"rock.data\" exist? \n")
    res <- dbExistsTable(con, c('testschema', "rock.data"))
    if(res){
      cat("FAIL: true despite testschema specified\n")
    }else{
      cat("PASS: false as the testschema specified\n")
    }

    cat("Does public.\"rock.data\" exist? \n")
    res <- dbExistsTable(con, c('public', "rock.data"))
    if(res){
      cat("PASS: true despite search_path change\n")
    }else{
      cat("FAIL: false as the search_path changed\n")
    }

    
    cat("write in current schema\n")
    dbWriteTable(con, "rock.data", rock)
    cat("Does rock.data exist? \n")
    res <- dbExistsTable(con, "rock.data")
    if(res){
      cat("PASS: true\n")
    }else{
      cat("FAIL: false\n")
    }

    ## cleanup
    dbGetQuery(con, 'DROP TABLE "public"."rock.data"')
    dbGetQuery(con, 'DROP TABLE "testschema"."rock.data"')
    dbGetQuery(con, 'DROP schema "testschema"')

    ## and disconnect
    dbDisconnect(con)
}
