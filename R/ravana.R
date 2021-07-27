#' @export
RegObj <- function (CodeObject){
  CodeObjectName <-deparse(substitute(CodeObject))
  Ravana_Cluster$Objects[[CodeObjectName]]  <<- CodeObject
}

#' @export
RegFunc <- function (CodeObject){
  CodeObjectName <-deparse(substitute(CodeObject))
  Ravana_Cluster$Functions[[CodeObjectName]]  <<- CodeObject
}

#' @export
Connect <- function(){
  conn = DBI::dbConnect(RPostgres::Postgres(), 
                   user     = Ravana_Cluster$Settings$userid, 
                   password = Ravana_Cluster$Settings$password, 
                   dbname   = Ravana_Cluster$Settings$database, 
                   host     = Ravana_Cluster$Settings$server)
  Ravana_Cluster$Connection <<- conn
  message(paste0("Connected to ", Ravana_Cluster$Settings$database, "@", Ravana_Cluster$Settings$server))
  return (conn)
}

#' @export
Disconnect <- function(){
  if (!is.null(Ravana_Cluster$Connection)){
    DBI::dbDisconnect(Ravana_Cluster$Connection)
    Ravana_Cluster$Connection <<- NULL
  } else {message("Can't disconnect NULL db connecion..")}
  
}

#' @export
UploadCode <- function(){
  out <- tryCatch(
    {   
      if (exists("Ravana_Cluster")){

        escFunctions = paste(deparse(Ravana_Cluster$Functions), collapse = "\n")
        escObjects   = paste(deparse(Ravana_Cluster$Objects), collapse = "\n")

        sql = "UPDATE clusters SET rfunctions=?p1, robjects=?p2 WHERE clustername=?p3"
        SQL = DBI::sqlInterpolate(DBI::ANSI(), sql
                                  , p1 = escFunctions
                                  , p2 = escObjects
                                  , p3 = Ravana_Cluster$ClusterName)

        DBI::dbExecute(Ravana_Cluster$Connection, SQL)
        
        return(Ravana_Cluster$ClusterName)
      } else {
        message("Ravana_Cluster is not initiated!..")
        return(NA)
      }
    },
    error = function(cond) {
      message(cond)
      return(NA)
    },
    finally = function(cond) {
      message(cond)
    }
  )    
  return(out)  
}

#' Initialize a Cluster
#'
#'
#' @param Name of the cluster
#' @return
#' @export
Init <- function (ClusterName="Ravana"){
  ClustR             <- list()
  ClustR$ClusterName <- ClusterName
  ClustR$Functions   <- list()
  ClustR$Objects     <- list()   
  
  
  settings_file = paste0(getwd(), "/", "settings.txt")
  message("Reading settings from ",settings_file)
  settings <- rjson::fromJSON(file = settings_file)
  ClustR$Settings <- settings

  
  assign("Ravana_Cluster", ClustR, envir = .GlobalEnv)
  
  Ravana_Cluster$Connection <<- Connect()

  
  sql = "DELETE FROM clusters WHERE clustername=?p1"
  SQL = DBI::sqlInterpolate(DBI::ANSI(), sql, p1 = ClusterName)
  DBI::dbExecute(Ravana_Cluster$Connection, SQL)

  sql = "ALTER SEQUENCE mappedtasks_taskseq_seq RESTART 1"
  SQL = DBI::sqlInterpolate(DBI::ANSI(), sql)
  DBI::dbExecute(Ravana_Cluster$Connection, SQL)
  
  sql = "INSERT INTO clusters(clustername, createdby) VALUES(?p1, ?p2) "
  UserID = paste0(Sys.info()["login"], "@", Sys.info()["nodename"])
  SQL = DBI::sqlInterpolate(DBI::ANSI(), sql, p1 = ClusterName, p2=UserID)
  DBI::dbExecute(Ravana_Cluster$Connection, SQL)

}


#' Map a Registered R Function
#'
#' @param Name of the registered R Function
#' @param List containing the data 
#' @param Batch size
#' @return [Void]
#' @export
Map <-function(Function, Data, BatchSize=1){
  FunctionName <-deparse(substitute(Function))
  if (FunctionName %in% names(Ravana_Cluster$Functions)) {
    
    message(paste0("Map Function: [",FunctionName,"]"))

    data = (split(as.list(Data), ceiling(seq_along(as.list(Data))/BatchSize)))

    
    taskid = floor(as.numeric(Sys.time()))
    for (i in 1:length(data)) {
       clustername = Ravana_Cluster$ClusterName
       mappedrfunction = FunctionName
       mappedparameters = sub("\n", " ",deparse1(data[[i]], width.cutoff = 500L))
       mappedparameters = sub("\t", " ", mappedparameters)
       mappedparameters = sub("\r", " ", mappedparameters)
       mappedparameters = gsub("\\s+", " ", mappedparameters)
       message((mappedparameters))
       createdby = paste0(Sys.info()["login"], "@", Sys.info()["nodename"])
       sql = "INSERT INTO mappedtasks(taskid, clustername, mappedrfunction, mappedparameters, createdby) VALUES (?p1, ?p2, ?p3, ?p4, ?p5)"
       SQL = DBI::sqlInterpolate(DBI::ANSI(), sql
                                 , p1 = taskid
                                 , p2 = clustername
                                 , p3 = mappedrfunction
                                 , p4 = mappedparameters
                                 , p5 = createdby)
       DBI::dbExecute(Ravana_Cluster$Connection, SQL)
    }
    message(sprintf("Mapping completed for [%s] with %d items..", FunctionName, length(data)))
    return(list(taskid, FunctionName))
    } else {message("Function not found!")}
  
  }


#' @export
Reduce <- function (T){
  sql = 'SELECT  AVG(progress) as progress FROM mappedtasks WHERE taskid=?p1'
  SQL = DBI::sqlInterpolate(DBI::ANSI(), sql, p1 = T[[1]])
  
  p<-0
  while(p<1){
    res  <- DBI::dbGetQuery(Ravana_Cluster$Connection, SQL)
    p<-res$progress[1]
    Sys.sleep(0.5)
  }
  
  sql = 'SELECT  mappedresults FROM mappedtasks WHERE taskid=?p1'
  SQL = DBI::sqlInterpolate(DBI::ANSI(), sql, p1 = T[[1]])
  res  <- DBI::dbGetQuery(Ravana_Cluster$Connection, SQL)
  
  return (list(res$mappedresults))
}


