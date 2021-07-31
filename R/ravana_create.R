#' cluster_exists
#' 
#' Checks if a cluster exists.
#' 
#' @param clustername Name of the cluster
#' @export
cluster_exists <- function(clustername){
  sql  <- "SELECT COUNT(clustername) as cnt FROM clusters WHERE clustername=?p1"
  SQL  <- DBI::sqlInterpolate(DBI::ANSI(), sql, p1 = clustername)
  rows <- DBI::dbGetQuery(Ravana$connection, SQL)
  if (rows$cnt>0) return(T) else return(F)
}



#' resume_cluster
#' 
#' Resumes an existing cluster by loading details from the database.
#' 
#' @param clustername Name of the cluster
#' @export
resume_cluster <- function(clustername){
  
  if (!exists("Ravana", where = .GlobalEnv)) stop("Global variable [Ravana] does not exist!")
  
  sql <- "SELECT * FROM clusters WHERE clustername=?p1 LIMIT 1"
  SQL <- DBI::sqlInterpolate(DBI::ANSI(), sql, p1 = clustername)
  res <- DBI::dbGetQuery(Ravana$connection, SQL)
  
  Ravana$createdby <<- res$createdby
  Ravana$createdon <<- res$createdon
  Ravana$sharedfunctions <<- eval(parse(text=res$rfunctions[1]))
  Ravana$sharedvariables <<- eval(parse(text=res$robjects[1]))
  
  message(sprintf("Cluster [%s] resumed successfully.", clustername))
}



#' init_cluster
#' 
#' Initializes a Ravana cluster and creates an entry in the database. 
#' If a cluster with the same name already exists, this process will load related functions and variables from the database. 
#' 
#' @param clustername Name of the cluster
#' @param settingspath Location where the settings.json file is stored. If no path is provided it will look into the working directory (getwd()).
#' @export
init_cluster <- function(clustername, settingspath = "."){
    R                 <- list()
    R$clustername     <- clustername
    R$nodetype        <- "MASTER"
    R$sharedfunctions <- list()
    R$sharedobjects   <- list()
    assign("Ravana", R, envir = .GlobalEnv)
    connect(settingspath)
    
    if (cluster_exists(clustername)) {
      resume_cluster(clustername)      
    } else{
      sql    <- "INSERT INTO clusters(clustername, createdby) VALUES(?p1, ?p2) "
      UserID <- paste0(Sys.info()["login"], "@", Sys.info()["nodename"])
      Ravana$createdby <<- UserID
      SQL <- DBI::sqlInterpolate(DBI::ANSI(), sql, p1 = clustername, p2=UserID)
      DBI::dbExecute(Ravana$connection, SQL)
      message(sprintf("New Cluster [%s] created successfully.", clustername))
    }
}


#' set_worker
#' 
#' Sets the current computer as a worker node.
#' Workers receive tasks, completes them using suggested functions and return the result back to the database.
#' 
#' @export
set_worker <- function (){
  if (!exists("Ravana", where = .GlobalEnv)) stop("Can't [set_worker]. Global variable [Ravana] does not exist!")
  Ravana$nodetype  <- "WORKER"
  
  nodename    <- Sys.info()["nodename"]
  osname      <- Sys.info()["sysname"]
  osversion   <- paste0(Sys.info()["release"]," - ",Sys.info()["version"])
  machinetype <- Sys.info()["machine"]
  heartbeat   <- as.character(as.POSIXct(Sys.time()))
  memtotal    <- as.numeric((sub(" GiB", "", memuse::Sys.meminfo()[[1]])))*1000
  memfree     <- as.numeric((sub(" GiB", "", memuse::Sys.meminfo()[[2]])))*1000
  cores       <- parallel::detectCores(logical = F)
  speed       <- 87654321 / (mean(microbenchmark::microbenchmark(sqrt(1:100000))$time))

    
  sql = "INSERT INTO nodes(nodename, osname, osversion, speed, machinetype, heartbeat, memtotal, memfree, cores) 
         VALUES (?p1, ?p2, ?p3, ?p4,?p5, CURRENT_TIMESTAMP, ?p7, ?p8, ?p9) 
         ON CONFLICT (nodename) DO UPDATE SET heartbeat=CURRENT_TIMESTAMP, memfree=?p8;" 
  
  SQL = DBI::sqlInterpolate(DBI::ANSI(), sql
                            , p1  = nodename
                            , p2  = osname
                            , p3  = osversion
                            , p4  = speed
                            , p5  = machinetype
                            , p7  = memtotal
                            , p8  = memfree
                            , p9  = cores)
  
  DBI::dbExecute(Ravana$connection, SQL)
  message(sprintf("[%s] is now a worker..", nodename))
}


#' unset_worker
#' 
#' Un-sets the current computer as a worker node.
#' @export
unset_worker <- function (){
  if (!exists("Ravana", where = .GlobalEnv)) stop("Can't [set_worker]. Global variable [Ravana] does not exist!")
  nodename    <- Sys.info()["nodename"]  
  sql = "DELETE FROM nodes WHERE nodename=?p1;" 
  SQL = DBI::sqlInterpolate(DBI::ANSI(), sql, p1  = nodename)
  DBI::dbExecute(Ravana$connection, SQL)  
  Ravana$nodetype  <- "MASTER"
  message(sprintf("[%s] is NOT a worker anymore..", nodename))  
}

#' heartbeat
#' 
#' Sends a heartbeat to the cluster
#' @export
heartbeat <- function() {
  if (!exists("Ravana", where = .GlobalEnv)) stop("Can't [set_worker]. Global variable [Ravana] does not exist!")  
  memfree     <- as.numeric((sub(" GiB", "", memuse::Sys.meminfo()[[2]])))*1000
  sql = "UPDATE nodes SET heartbeat = CURRENT_TIMESTAMP, memfree=?p1 WHERE nodename=?p2;" 
  SQL = DBI::sqlInterpolate(DBI::ANSI(), sql, p1  = memfree, p2 = Sys.info()["nodename"])
  DBI::dbExecute(Ravana$connection, SQL)
  cat("")
}

#' write_log
#' 
#' Write a log record
#' @export
write_log <- function(msgtype, msg){
  if (!exists("Ravana", where = .GlobalEnv)) stop("Can't [set_worker]. Global variable [Ravana] does not exist!")
  sql = " INSERT INTO logs(clustername, nodename, msg, msgtype) VALUES (?p1, ?p2, ?p3, ?p4)"
  SQL = DBI::sqlInterpolate(DBI::ANSI(), sql
                            , p1 = Ravana$clustername
                            , p2 = Sys.info()["nodename"]
                            , p3 = msg
                            , p4 = msgtype)
  
  DBI::dbExecute(Ravana$connection, SQL)
  message(sprintf("[%s] %s", msgtype, msg))
}
