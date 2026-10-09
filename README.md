# devup
Script for easy downloading repos and choosing branches as shortcut "devup" in terminal.

DEVSTACK – Clone Repo , choose Branch , Docker Compose up
==============================================================

What you need:
- macOS oder Linux (Windows: WSL)
- git
- Docker Desktop (had to run)

Installation:
1. Create folder:
   mkdir -p ~/devstack/repos ~/devstack/configs

2. copy devup.sh to ~/devstack/ then execute:
   chmod +x ~/devstack/devup.sh

3. Set alias:
   echo 'alias devup="$HOME/devstack/devup.sh"' >> ~/.zshrc
   source ~/.zshrc
   (Linux/Bash: ~/.bashrc statt ~/.zshrc)

4. Create List of Repos you want to chose in the shortcut (one URL per Row, # can be used for comments):
   ~/devstack/repos.txt

Structue of the folders and files:
~/devstack/
  devup.sh
  repos.txt
  repos/<name>/                       Clones (don't touch!)
  configs/<name>/.env                 your own .env
  configs/<name>/docker-compose.yml   your own docker-compose file

Usage:
open your Terminal and type the shortcut: 

devup                     

a menu with your repos from repo.txt will appear and you can choose the number of the one you wan't to download

Way to is to open a repo url directly:
devup <url>               
like this you can choose a repo wich isn't in the txt. The script will run beta branch if only beta and master exist. otherwise it will ask.

And at last a way with directly choosing the right branch: 
devup <url> main          will set a specific branch

Stop docker for the choosen Repo/branch:
cd ~/devstack/repos/<name> && docker compose -p <name>-<branch> down

Workflow
- Script will clone or overwrite the coosen repo (git pull --ff-only)
- Script asks for branch. If only master and beta avalible it will chose beta.
- Script will create configs/<name>/.env and copy example.env to the .env file on first run. after that you can exdit the file in confgs folder. It will stay after repo overwrites so you had not to do everytime.
- Script will create configs/<name>/docker-compose.yml as docker-compose.local.yml to repo automativ. You can change the docker-compose file in the config file (similar like the .env)
- Script will start the repo in docker: docker compose up -d --build

First start of a new repo:
- If a .env.example exists, it will be copyed to configs/<name>/.env
  the skript will abort after that for letting you time to modify the .env in config folder. after that you can run "devup" again to start.

Some information:
- Please only store your own data to configs/ and never dirextly to Repo-Folder
  (Repo folder will overwritten on every run!)
- .env and docker-compose.local.yml are in .git/info/exclude
  (they will not be commitet)
- "command not found": will happen if alias is not set ./devup.sh if you don't want to create an alias you can run by ~/devstack/devup.sh
