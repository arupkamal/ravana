#' Shares an R function in the cluster
#' @param function R function 
#' @export
share_function <- function(rfunction){
  
  if (!exists("Ravana", where = .GlobalEnv)) stop("Global variable [Ravana] does not exist!")
  
  rfunctionname <-deparse(substitute(rfunction))
  Ravana$sharedfunctions[[rfunctionname]]  <<- rfunction  
  
  X = paste(deparse(Ravana$sharedfunctions), collapse = "\n")

  sql = "UPDATE clusters SET rfunctions=?p1 WHERE clustername=?p2"
  SQL = DBI::sqlInterpolate(DBI::ANSI(), sql, p1 = X, p2 = Ravana$clustername)
  
  DBI::dbExecute(Ravana$connection, SQL)
  message(sprintf("Function [%s] shared to Cluster [%s]", rfunctionname, Ravana$clustername))
}


#' Shares an R object (vector, list, matrix, data frame etc.) in the cluster
#' @param robject R object 
#' @export
share_object <- function(robject){
  
  if (!exists("Ravana", where = .GlobalEnv)) stop("Global variable [Ravana] does not exist!")
  
  robjectname <-deparse(substitute(robject))
  Ravana$sharedobjects[[robjectname]]  <<- robject  
  
  X = paste(deparse(Ravana$sharedobjects), collapse = "\n")
  
  sql = "UPDATE clusters SET robjects=?p1 WHERE clustername=?p2"
  SQL = DBI::sqlInterpolate(DBI::ANSI(), sql, p1 = X, p2 = Ravana$clustername)
  
  DBI::dbExecute(Ravana$connection, SQL)
  message(sprintf("%s Object [%s] shared to Cluster [%s]", stringr::str_to_title(class(robject)), robjectname, Ravana$clustername))
}

