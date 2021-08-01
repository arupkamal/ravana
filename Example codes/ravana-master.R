
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