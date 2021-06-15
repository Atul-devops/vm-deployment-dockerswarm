printf "\n"
printf "Checking for new images"
printf "\n"
sudo docker pull aditazz/mercury-ahu-router:development -q
sudo docker pull aditazz/mercury-floor-router:development -q 
sudo docker pull aditazz/mercury-shaft-router:development -q
sudo docker pull aditazz/mercury-solver:development -q

sudo docker service update mercury-business_mercury-business --image aditazz/mercury-business:development --with-registry-auth -q
sudo docker service update mercury-visualizer_mercury-visualizer --image aditazz/mercury-visualizer:development --with-registry-auth -q
sudo docker service update mercury-homepage_mercury-homepage --image aditazz/mercury-landing:latest --with-registry-auth -q


printf "\n"
printf "Clearing stopped containers"
printf "\n"
sudo docker container prune -f

printf "\n"
printf "Clearing all but latest images"
printf "\n"
sudo docker images | grep mercury-business | tail -n +2 | awk '{print $3}' | xargs sudo docker rmi >> /dev/null 2>&1
sudo docker images | grep mercury-visualizer | tail -n +2 | awk '{print $3}' | xargs sudo docker rmi >> /dev/null 2>&1
sudo docker images | grep mercury-ahu-router | tail -n +2 | awk '{print $3}' | xargs sudo docker rmi >> /dev/null 2>&1
sudo docker images | grep mercury-floor-router | tail -n +2 | awk '{print $3}' | xargs sudo docker rmi >> /dev/null 2>&1
sudo docker images | grep mercury-shaft-router | tail -n +2 | awk '{print $3}' | xargs sudo docker rmi >> /dev/null 2>&1
sudo docker images | grep mercury-solver | tail -n +2 | awk '{print $3}' | xargs sudo docker rmi >> /dev/null 2>&1

printf "\n"
printf "Exit"

printf "\n\n\n"
