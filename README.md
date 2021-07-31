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
  
  
  <b>Setting up a Worker node</b>
  <hr>
  1. Install R in the worker node. 
  
  2. Install ravana package by using this command in R:
     <b>devtools::install_github("arupkamal/ravana")</b>
     
  3. Create the worker.R file with the following code:
  <code>
  <br>
  library(ravana)<br>
  init_cluster('Ravana', settingspath  = 'C:/R')<br>
  set_worker()<br>
  run_worker()<br>
  disconnect()
  </code>
  

