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
  
  3. Create the <b>Ravana database</b> by running this SQL: https://github.com/arupkamal/ravana/blob/main/Database%20Setup/01_database_setup.sql
  
  3. Create the <b>Ravana user</b>   by running this SQL: https://github.com/arupkamal/ravana/blob/main/Database%20Setup/02_role_setup.sql
  
  4. Create the <b>Ravana tables</b> by running this SQL: https://github.com/arupkamal/ravana/blob/main/Database%20Setup/03_table_setup.sql
  
  5. Create the <b>Ravana functions</b> by running this SQL: https://github.com/arupkamal/ravana/blob/main/Database%20Setup/04_function_setup.sql
  
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
  <pre>
library(ravana)
  
init_cluster('Ravana', settingspath  = 'C:/R')
  
is_prime <- function(n) {
    n == 2L || all(n %% 2L:max(2,floor(sqrt(n))) != 0)
    }

#check these numebers if they are primes
numbers_to_check <- seq(1000001, 1010001, 2)
  
#share the function in the cluster
share_function(is_prime)

#share the object in the cluster
share_object(numbers_to_check)


taskid <- ravana_map(is_prime, numbers_to_check)
res = ravana_reduce(taskid)
  
#print all the Prime numbers found through this process
print(res[res$mappedresults==TRUE,]$mappedparameters)
</pre>
  
  <hr>
  
  <b>Setting up a Worker node</b>
  <hr>
  1. Install R in the worker node. 
  
  2. Install ravana package by using this command in R:
     <b>devtools::install_github("arupkamal/ravana")</b>
     
  3. Create the worker.R file with the following code:
  
  <br>
  <pre>
  library(ravana)
  init_cluster('Ravana', settingspath  = 'C:/R')
  set_worker()
  run_worker()
  disconnect()
  </pre>
  

