#' Checks if a cluster exists.
#' @param clustername Name of the cluster
#' @export
cluster_exists <- function(clustername){
  sql = "SELECT COUNT(clustername) as cnt FROM clusters WHERE clustername=?p1"
  SQL = DBI::sqlInterpolate(DBI::ANSI(), sql, p1 = clustername)
  rows   <- DBI::dbGetQuery(Ravana$connection, SQL)
  if (rows$cnt>0) return(T) else return(F)
}



#' Resumes an existing cluster by loading details from the database.
#' @param clustername Name of the cluster
#' @export
resume_cluster <- function(clustername){
  
  if (!exists("Ravana", where = .GlobalEnv)) stop("Global variable [Ravana] does not exist!")
  
  sql = "SELECT * FROM clusters WHERE clustername=?p1 LIMIT 1"
  SQL = DBI::sqlInterpolate(DBI::ANSI(), sql, p1 = clustername)
  res   <- DBI::dbGetQuery(Ravana$connection, SQL)
  
  Ravana$createdby <<- res$createdby
  Ravana$createdon <<- res$createdon
  Ravana$sharedfunctions <<- eval(parse(text=res$rfunctions[1]))
  Ravana$sharedvariables <<- eval(parse(text=res$robjects[1]))
  
  message(sprintf("Cluster [%s] resumed successfully.", clustername))
}



#' Initializes a Ravana cluster and creates an entry in the database. 
#' If a cluster with the same name already exists, this process will load related functions and variables from the database. 
#' 
#' @param clustername Name of the cluster
#' @param settingspath Location where the settings.json file is stored. If no path is provided it will look into the working directory (getwd()).
#' @export
init_cluster <- function(clustername, settingspath = "."){
    R <- list()
    R$clustername <- clustername
    R$sharedfunctions  <- list()
    R$sharedobjects    <- list()
    assign("Ravana", R, envir = .GlobalEnv)
    connect(settingspath)
    
    if (cluster_exists(clustername)) {
      resume_cluster(clustername)      
    } else{
      sql = "INSERT INTO clusters(clustername, createdby) VALUES(?p1, ?p2) "
      UserID = paste0(Sys.info()["login"], "@", Sys.info()["nodename"])
      Ravana$createdby <<- UserID
      SQL = DBI::sqlInterpolate(DBI::ANSI(), sql, p1 = clustername, p2=UserID)
      DBI::dbExecute(Ravana$connection, SQL)
      message(sprintf("New Cluster [%s] created successfully.", clustername))
    }
}



