#!/bin/bash

# Update the package lists to get the latest available versions
echo "Updating package list..."
sudo apt update

# Install required dependencies for adding new repositories
echo "Installing required dependencies..."
sudo apt install -y software-properties-common wget

# Add the deadsnakes PPA (contains older versions of Python, including 3.10)
echo "Adding the deadsnakes PPA..."
sudo add-apt-repository ppa:deadsnakes/ppa

# Update package list again after adding the repository
echo "Updating package list again..."
sudo apt update

# Install Python 3.10.12
echo "Installing Python 3.10..."
sudo apt install -y python3.10

# Install pip for Python 3.10
echo "Installing pip for Python 3.10..."
sudo apt install -y python3.10-distutils
wget https://bootstrap.pypa.io/get-pip.py
sudo python3.10 get-pip.py

# Setting Python 3.10 as the default python3
echo "Setting Python 3.10 as default..."
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1

# Configure the system to use Python 3.10 by default
echo "Configuring Python 3.10 as the default version..."
sudo update-alternatives --config python3

# Checking the Python version to confirm it switched
echo "Verifying Python version..."
python3 --version

# Checking if pip for Python 3.10 is installed
echo "Verifying pip installation..."
python3 -m pip --version

echo "Python 3.10.12 has been successfully installed and set as default!"

