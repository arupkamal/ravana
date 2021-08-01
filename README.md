---
output:
  html_document: default
  pdf_document: default
---
# ravana
  The super simple R library for distributed computing using map-reduce.
  
  
  
  <h3><b>Setup</b></h3>
  <hr>
  1. Install PostgreSQL 13 or greater from https://www.enterprisedb.com/downloads/postgres-postgresql-downloads
  
  2. Install ravana package by using this command in R:
     <b>devtools::install_github("arupkamal/ravana")</b>
  
  3. Create the <b>Ravana database</b> by running this SQL:https://raw.githubusercontent.com/arupkamal/ravana/blob/main/Database%20Setup/01_database_setup.sql
  
  3. Create the <b>Ravana user</b>   by running this SQL:https://raw.githubusercontent.com/arupkamal/ravana/blob/main/Database%20Setup/02_role_setup.sql
  
  4. Create the <b>Ravana tables</b> by running this SQL:https://raw.githubusercontent.com/arupkamal/ravana/blob/main/Database%20Setup/03_table_setup.sql
  
  5. Create the <b>Ravana functions</b> by running this SQL: https://raw.githubusercontent.com/arupkamal/ravana/main/Database%20Setup/04_function_setup.sql
  
  <br>
  <br>
  <br>

  <h3><b>Getting started</b></h3>
  <hr>
  <b>Setting up a Cluster</b>
  
  1. Install R in the master node. 
  
  2. Install ravana package by using this command in R:
     <b>devtools::install_github("arupkamal/ravana")</b>
     
  3. Create the ravana.R file with the following code:

  <br>
  library(ravana)<br>
  init_cluster('Ravana', settingspath  = 'C:/R')<br>
  is_prime <- function(n) {<br>
    n == 2L || all(n %% 2L:max(2,floor(sqrt(n))) != 0)<br>
    }<br>
  #check these numebers if they are primes<br>
  numbers_to_check <- seq(1000001, 1010001, 2)<br>
  #share the function in the cluster<br>
  share_function(is_prime)<br>
  taskid <- ravana_map(is_prime, numbers_to_check)<br>
  res = ravana_reduce(taskid)<br>
  #print all the Prime numbers found through this process<br>
  print(res[res$mappedresults==TRUE,]$mappedparameters)

  
  <hr>
  
  <b>Setting up a Worker node</b>
  <hr>
  1. Install R in the worker node. 
  
  2. Install ravana package by using this command in R:
     <b>devtools::install_github("arupkamal/ravana")</b>
     
  3. Create the worker.R file with the following code:
  
  <br>
  library(ravana)<br>
  init_cluster('Ravana', settingspath  = 'C:/R')<br>
  set_worker()<br>
  run_worker()<br>
  disconnect()
  
  

