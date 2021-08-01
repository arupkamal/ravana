
p <- function (x){
  print(names(x))
  print(x)
  message("----------------------------\n")
}


hi <- function() {
  print("Hi")
}

share_function(hi)

init_cluster('Ravana', settingspath = 'C:/R')
#lapply(Ravana$sharedfunctions, p)

for (i in 1:length(Ravana$sharedfunctions)) {
  function_name  <- names(Ravana$sharedfunctions[i])
  function_code  <- deparse1(Ravana$sharedfunctions[[i]], collapse="\n")
  evalcode <- paste(function_name, "<-", function_code)
  eval(parse(text=evalcode), envir=.GlobalEnv)
}