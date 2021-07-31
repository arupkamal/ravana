#' share_function
#' 
#' Shares an R function in the cluster
#' @param rfunction R function 
#' @export
share_function <- function(rfunction){
  
  if (!exists("Ravana", where = .GlobalEnv)) stop("Global variable [Ravana] does not exist!")
  
  rfunctionname <-deparse(substitute(rfunction))
  
  message("R function:", rfunctionname)

  Ravana$sharedfunctions[[rfunctionname]]  <<- rfunction  
  
  X <- paste(deparse(Ravana$sharedfunctions), collapse = "\n")

  sql <- "UPDATE clusters SET rfunctions=?p1 WHERE clustername=?p2"
  SQL <- DBI::sqlInterpolate(DBI::ANSI(), sql, p1 = X, p2 = Ravana$clustername)
  
  DBI::dbExecute(Ravana$connection, SQL)
  message(sprintf("Function [%s] shared to Cluster [%s]", rfunctionname, Ravana$clustername))
}


#' share_object
#' 
#' Shares an R object (vector, list, matrix, data frame etc.) in the cluster
#' @param robject R object 
#' @export
share_object <- function(robject){
  
  if (!exists("Ravana", where = .GlobalEnv)) stop("Global variable [Ravana] does not exist!")
  
  robjectname <-deparse(substitute(robject))
  Ravana$sharedobjects[[robjectname]]  <<- robject  
  
  X <- paste(deparse(Ravana$sharedobjects), collapse = "\n")
  
  sql <- "UPDATE clusters SET robjects=?p1 WHERE clustername=?p2"
  SQL <- DBI::sqlInterpolate(DBI::ANSI(), sql, p1 = X, p2 = Ravana$clustername)
  
  DBI::dbExecute(Ravana$connection, SQL)
  message(sprintf("%s Object [%s] shared to Cluster [%s]", stringr::str_to_title(class(robject)), robjectname, Ravana$clustername))
}




#' ravana_map
#' 
#' Maps a task expressed as an R function to each element of list.
#' @param rfunction R function
#' @param mappeddata 
#' @return Returns the taskid. 
#' @export

ravana_map <- function(rfunction, datatomap){
  if (!exists("Ravana", where = .GlobalEnv)) stop("Global variable [Ravana] does not exist!")  
  
  rfunctionname <-deparse(substitute(rfunction))
  if (!(rfunctionname %in% names(Ravana$sharedfunctions))) stop(sprintf("Function %s is can't be found!",rfunctionname))  

  options(digits.secs = 6)
  options(scipen=6)
  
  taskid <- as.numeric(Sys.time())*1000000
  
  if (class(datatomap)=="data.frame") {
    mapdata <- split(datatomap, seq(nrow(datatomap)))
  } else {
    mapdata <- as.list(datatomap)
  }

  datalen = length(mapdata)
  for (i in 1:datalen) {
    clustername      <- Ravana$clustername
    createdby        <- paste0(Sys.info()["login"], "@", Sys.info()["nodename"])
    taskseq          <- i
    taskuid          <- uuid::UUIDgenerate()
    mappedrfunction  <- rfunctionname
    mappedparameters <- sub("\n", " ",    deparse1(mapdata[[i]], width.cutoff = 500L))
    mappedparameters <- sub("\t", " ",    mappedparameters)
    mappedparameters <- sub("\r", " ",    mappedparameters)
    mappedparameters <- gsub("\\s+", " ", mappedparameters)    

    sql <- "INSERT INTO mappedtasks(taskid, taskseq, taskuid, clustername, mappedrfunction, mappedparameters, createdby) VALUES (?p1, ?p2, ?p3, ?p4, ?p5, ?p6, ?p7)"
    SQL <- DBI::sqlInterpolate(DBI::ANSI(), sql
                              , p1 = taskid
                              , p2 = taskseq
                              , p3 = taskuid
                              , p4 =clustername
                              , p5 = mappedrfunction
                              , p6 = mappedparameters
                              , p7 = createdby)
    DBI::dbExecute(Ravana$connection, SQL)        
    if (i %% 10 == 0) cat(" ..", i)
  }
  cat(" ..")
  
  message(sprintf("\nMapping completed for [%s] with %d items..", mappedrfunction, datalen))
  return(taskid)
}


#' ravana_reduce
#' 
#' Reduces a task which has been already Mapped.
#' @param rfunction R function
#' @param taskid 
#' @return Returns the results in a list.
#' @export
ravana_reduce <- function (taskid){
  if (!exists("Ravana", where = .GlobalEnv)) stop("Can't [set_worker]. Global variable [Ravana] does not exist!")
  
  sql <- 'SELECT  AVG(progress) as progress FROM mappedtasks WHERE taskid=?p1'
  SQL <- DBI::sqlInterpolate(DBI::ANSI(), sql, p1 = taskid)
  
  progress <- 0
  while(progress < 1){
    res      <- DBI::dbGetQuery(Ravana$connection, SQL)
    progress <- res$progress[1]
    cat(progress)
    Sys.sleep(0.2)
  }
  
  sql <- 'SELECT  mappedparameters, mappedresults FROM mappedtasks WHERE taskid=?p1'
  SQL <- DBI::sqlInterpolate(DBI::ANSI(), sql, p1 = taskid)
  res <- DBI::dbGetQuery(Ravana$connection, SQL)
  
  return (res)
}



execute_task <- function() {
  if (!exists("Ravana", where = .GlobalEnv)) stop("Can't [set_worker]. Global variable [Ravana] does not exist!")
  sql = 'SELECT * FROM collect_task(?p1, ?p2)'  
  SQL = DBI::sqlInterpolate(DBI::ANSI(), sql, p1  = Ravana$clustername, p2= Sys.info()["nodename"])
  
  res  <- DBI::dbGetQuery(Ravana$connection, SQL)
  rows <- length(res[,1])
  
  if (rows>0 && !is.na(res$taskuid[1])){
    parameters <- eval(parse(text=res$mappedparameters[1]))

    result <- Ravana$sharedfunctions[res$mappedrfunction[1]][[1]](parameters)
    
    result <- sub("\n", " ",    deparse1(result, width.cutoff = 500L))
    result <- sub("\t", " ",    result)
    result <- sub("\r", " ",    result)
    result <- gsub("\\s+", " ", result)    
    
    sql = "SELECT * FROM submit_task(?p1, ?p2)"
    SQL = DBI::sqlInterpolate(DBI::ANSI(), sql, p1 = res$taskuid[1], p2 = result)
    res  <- DBI::dbGetQuery(Ravana$connection, SQL)
    rows <- length(res[,1])
    message(sprintf("TaskSeq %s [%s] completed for %s", res$taskseq[1], res$mappedrfunction[1], Ravana$clustername))
  }
  heartbeat()
}

task_loop <- function(){
  while (T){
    execute_task()
    Sys.sleep(0.3)
    heartbeat
  }
}

evtInterrupted <- function(e){
  write_log("Interruption", "Worker terminated by user!")
  message("Ravana: Worker terminated by user!")
  Disconnect()
}

evtError   <- function(e){
  write_log("Error", e)
  message("[Error] ", e)
}

evtFinally <- function(cond){
  NOOP()
}

#' run_worker
#' 
#' Starts processing available tasks as an worker node.
#' 
#' @export
run_worker <- function(){
  tryCatch(task_loop()
           , interrupt = function(c){evtInterrupted(c)}
           #, error     = function(c){evtError(c)}
           , finally   = function(c){evtFinally(c)})  
}
