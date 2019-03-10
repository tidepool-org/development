#!/bin/bash -x
# Check for Homebrew and install if we don't have it
if test ! $(which brew); then
  echo "Installing homebrew..."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Make sure we are using the latest Homebrew.
brew update
 
if brew ls --versions myformula > /dev/null; then
  echo "minikube already installed"
else
  echo "Installing Minikube to run a single-node Kubernetes Cluster locally..."
  brew cask install minikube
fi

echo "Configuring minikube"
minikube config set kubernetes-version v1.11.5
minikube config set memory 8192
minikube config set cpus 4
echo "Minikube Installation and Configuraiton complete"
