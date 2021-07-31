#' No-operation function. 
NOOP <-function(){NOOP<-T}


#' load_settings
#' 
#' Loads PostgreSQL database connection settings from the settings.json file. 
#' If the file not found, an error will be raised.
#' 
#' @param settingspath Location where the settings.json file is stored.
load_settings <- function(settingspath){
  if (settingspath == ".") settingspath <- getwd()
  
  settings_file <- paste0(settingspath, "/", "settings.json")
  
  message("Reading settings from [",settings_file,"]..")
  
  if (file.exists(settings_file)) {
    settings <- rjson::fromJSON(file = settings_file)
    
    if (!exists("Ravana", where = .GlobalEnv)) stop("Global variable [Ravana] does not exist!")
    Ravana$settings <<- settings
    message("Settings loaded successfully")

  } else {
    stop("settings.json not found")
  }
}



#' connect
#' 
#' Connects to the Ravana database. 
#' Connection settings are retrieved using the load_settings function. 
#' Settings are stored in the settings.json file.
#' @param settingspath Location where the settings.json file is stored.
#' @export 
connect <- function(settingspath){

    if (!exists("Ravana", where = .GlobalEnv)) stop("Global variable [Ravana] does not exist!")
  
    load_settings(settingspath)
    connection = DBI::dbConnect(RPostgres::Postgres(), 
                          host     = Ravana$settings$host,
                          port     = Ravana$settings$port,
                          dbname   = Ravana$settings$database,                                 
                          user     = Ravana$settings$userid, 
                          password = Ravana$settings$password)
      
      Ravana$connection <<- connection
      message("Connected to database successfully") 
}


#' disconnect
#' 
#' Disconnects from the Ravana database.
#' @export 
disconnect <- function(){
    tryCatch({
      DBI::dbDisconnect(Ravana$Connection)
      Ravana$connection <<- NULL}, error = function(c){NOOP()})    
    message("disconnected from the database") 
}
  