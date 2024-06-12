#!/bin/bash

# fail on any error
#set -eu

# install yum-config-manager to manage your repositories

#sudo yum install -y yum-utils

# use yum-config-manager to add the official HashiCorp Linux repository
#sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo

# install terraform
#sudo yum -y install terraform

# verify terraform is installed
#terraform --version


#Install prerequistes
sudo apt-get update
sudo apt-get install -y gnupg software-properties-common curl

#add HarshiCorp Linux Repository
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

#update and install terraform
sudo apt-get update
sudo apt-get install -y terraform
# verify terraform is installed
terraform --version

