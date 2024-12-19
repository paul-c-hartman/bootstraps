#!/bin/bash

# Safety check
read -p "Did you mean to run this script? (running as $USER) [Yn] " -r
if [[ $REPLY =~ [Yy]$ ]]; then
  echo -e "Continuing."
else
  echo -e "To run this script as a different user, try:"
  echo -e "  sudo -u <user> bash"
  echo -e "  ./boostrap.sh"
  echo
  echo -e "Aborting."
  exit 1
fi

# Check for dependencies
sudo apt install git openssh-client -y

# Pull setup scripts
cd ~
# Check if ssh key already exists
if ! [ -f ~/.ssh/id_ed25519 ]; then
  echo -ne "SSH key not found, generating..."
  ssh-keygen -f ~/.ssh/id_ed25519 -t ed25519 -N "" &> /dev/null
  echo -e " Done."
else
  echo SSH key found: ~/.ssh/id_ed25519
fi
echo Verify public key is added to Github
echo repo as read-only deploy key:
echo
cat ~/.ssh/id_ed25519.pub
echo
read -p "Press Enter to continue once key is added"
# Add github.com as a known host
ssh-keyscan -H github.com >> ~/.ssh/known_hosts
eval `ssh-agent -s`
ssh-add
git clone git@github.com:paul-c-hartman/testbox.git

# Branch check
read -p "What branch to pull from? Leave blank for 'main': " -r branch
if [ -z "$branch" ]; then
  branch= "main"
fi
echo -e "Using branch '$branch'"

# Run setup scripts
cd testbox
git checkout $branch
echo
echo ====================
echo Running setup script
echo ====================
echo -e "(logging to ~/setup.log)"
./setup/init.sh 2>&1 | tee ~/setup.log

# Cleanup from bootstrap
echo -ne "Cleaning up bootstrap script..."
eval `ssh-agent -k` # Kill agent
rm -r ~/testbox
echo -e " Done."
