# Setting up the Giving Connection Project
Welcome Hack4Impact team! Please follow these instructions to set up the Giving Connection project on your local machine. If you have any questions, please reach out to one of the directors. <br>

Note: These intructions were written based on fresh installations of Mac and Windows operating systems, to curate best for all skill levels. It is possible that you may already have some of the required software installed during these instructions. If so, you can most likely skip those steps if you see some kind of success message.

## Click to see instructions for your operating system:
- [Mac](#mac)
- [Windows](#windows)

## Mac

### Setup

#### Homebrew
Homebrew is a package manager for macOS that allows you to install software packages easily from the command line. It is a prerequisite for installing other software packages that we will need for the project. To install Homebrew, follow the instructions below:

1. Open Terminal and run the following command:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
Terminal will ask for your sudo password, which is just your computer password. Type it in and press enter, then enter again. The installation will take a few minutes. It will also install the Xcode Command Line Tools if you don't already have it.
You'll also see a red warning message, but that will be fixed in the next step.

2. Homebrew will then give you 3 commands to run once the command completes, which should look similar to:
```bash
# Don't copy these! They are just an example.
==> Next steps:
    echo >> /Users/yourname/.zprofile
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/yourname/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
```
Note that they won't generate any output, this is normal. 
This adds homebrew to your path so that you can run the `brew` command from anywhere in your terminal, regardless of your current directory.

3. Once completed, verify installation by running:
```bash
brew --version
```
You should see a version number if the installation was successful.

#### Node.js
Node.js is a JavaScript runtime that allows you to run JavaScript on the server side. We will use it to run the Giving Connection project.
If you already have Node.js, note that version `v20.17.0` is required, which we will be installing. Later versions *may* work, but I haven't tested it.

We will be using `nvm`, or Node Version Manager, to manage multiple versions of Node.js on your machine. This will allow you to install the correct version of Node.js for the project without interfering with your current version.

1. Run the following command to install `nvm`:
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
```

2. Quit (<kbd>⌘</kbd> + <kbd>Q</kbd>) and reopen Terminal to apply the changes. Verify installation by running:
```bash
nvm -v
```

3. Now, we'll install the correct version of Node.js for the project. Run the following command to install Node.js `v20.17.0`:
```bash
nvm install 20.17.0
```

4. To tell `nvm` to use this version of Node.js, run:
```bash
nvm use 20.17.0
```

5. Verify that the correct version of Node.js was installed by running:
```bash
node -v
```

Confirm that the version number is `v20.17.0`. If it is, you can continue.

#### Ruby
Ruby is the main programming language used in the project. It uses Ruby on Rails, a web application framework written in Ruby. We will use Ruby to run the Giving Connection project.
MacOS comes with Ruby pre-installed, but the version is too old to use with Ruby on Rails. You'll see this if you check the version by running:
```bash
ruby -v
```
Note that some of you may have already installed another version of Ruby your machine. If the version is **exactly** `3.1.0`, you can skip this section. Most likely, though, you'll need to install that version, as the Giving Connection project specifically requires that version. Here's how:

1. Run the following command to install rbenv, a Ruby version manager:
```bash
brew install rbenv
```

2.  Install version `3.1.0` of Ruby by running:
```bash
rbenv install 3.1.0
```

3. Initialize rbenv by running:
```bash
rbenv init
```

4. Set the global version of Ruby to `3.1.0` by running:
```bash
rbenv global 3.1.0
```

5. Quit (<kbd>⌘</kbd> + <kbd>Q</kbd>) and reopen Terminal to apply the changes. Verify installation by running:
```bash
ruby -v
```
You should see a version number that contains `3.1.0`, like `ruby 3.1.0p0 ...` if the installation was successful.

#### PostgreSQL
PostgreSQL is a powerful, open-source object-relational database system. We will use it to store the data for the Giving Connection project. **Regardless of team (frontend/backend), you will need to install PostgreSQL.** If you already have PostgreSQL installed, you can skip this step.

1. Run the following command to install PostgreSQL:
```bash
brew install postgresql
```

2. Start the PostgreSQL server by running:
```bash
brew services start postgresql
```

### Setting up the project
Next, we will clone the project and set up the dependencies.

#### Setting up Git with your Github Account
**If you already have Github Desktop installed and set up with your Github account, you can skip this step. You can also just install Github Desktop, and skip this step, but here's an alternative in case you want it.**
Since our project is private, we can't just clone it without setting up Git with your Github account. Here's how to do that:

1. Install the Github CLI by running:
```bash
brew install gh
```

2. Start the log in process:
```bash
gh auth login
```

3. Confirm that the `Github.com` option is selected, and press enter.

4. Confirm that the `HTTPS` option is selected, and press enter.

5. When asked if you want to Authenticate Git with your Github credentials, type `Y` and press enter.

6. Confirm that the `Login with a web browser` option is selected, and press enter.

7. Github will present a one-time code. Copy it, then press enter.

7. A browser window will open, asking you to log in to your Github account. Log in, enter the code, click on `Authorize github` and close the browser window.

#### Cloning the project
1. Navigate to the directory where you want to store the project. You can do this by running:
```bash
cd path/to/directory
```
Replace `path/to/directory` with the path to the directory where you want to store the project. For example, if you want to store the project in your `Documents` folder, you would run:
```bash
cd ~/Documents
```

2. Clone the project by running:
```bash
git clone https://github.com/Hack4ImpactRutgers/gc.git
```
If you get an error message, it's likely that you don't have access to the Hack4ImpactRutgers organization. Please reach out to one of the directors to get access before proceeding.

3. Navigate into the project directory by running:
```bash
cd gc
```

**For the remainer of these instructions, please keep your terminal at this directory. To confirm your current directory in case you need to restart your terminal later, please run `pwd` now and you'll see the current direcory that your terminal is in. You can also just open the project in Visual Studio Code, if you want, and start a Terminal session there.**

#### Installing dependencies
Finally, we will install the project dependencies and run any other required commands.

1. Install bundler with gem:
```bash
gem install bundler
```

2. Install redis:
```bash
brew install redis
```

3. Start the redis server:
```bash
brew services start redis
```
This will start the redis server in the background, and at login. You'll know this worked because you'll see a notification from the MacOS Settings app that says:
`Background Items Added`
`"redis-server" is an item that can run in the background. You can manage this in Login Items & Extensions.`.

4. Install the Ruby Dependencies:
```bash
bundle install
```

5. Install the global npm dependency, Yarn:
```bash
npm install -g yarn
```

6. Install the Yarn Dependencies:
```bash
yarn install
```

7. Install PostGIS (this is different than postgres):
```bash
brew install postgis
```
*This command will take a while to run.*

8. Install rails:
```bash
gem install rails
```

9. Quit (<kbd>⌘</kbd> + <kbd>Q</kbd>) and reopen Terminal to make the rails command available. You're using VSCode, quit it and reopen it.


10. Create the database:
```bash
rails db:create
```

11. Associate postgres with PostGIS:
```bash
psql -d giving_connection_development
```
then run:
```sql
CREATE EXTENSION IF NOT EXISTS PostGIS;
exit
```

12. Setup rake tasks:
```bash
rake db:gis:setup
```

13. Migrate the database:
```bash
rails db:migrate
```

14. Seed the database:
```bash
rails db:seed
```

### Running the project
Finally, start the server!
```bash
bin/dev
```

Wait until you stop seeing the output scroll, then visit `localhost:3000` in your browser to see the project running! To stop the project at any time, press <kbd>Ctrl</kbd> + <kbd>C</kbd> in the terminal. To run it again in the future, just run `bin/dev` again.

## Windows
Extensive efforts were made to try to get the Giving Connection project to run on Windows *natively*. The project uses a lot of tools that are not compatible with Windows, and it's just not worth the effort to try to get it to work. However, you can still run the project on Windows by using the Windows Subsystem for Linux (WSL). Here's how to set it up:

Note: These instructions are for WSL 2, which is only available on Windows 10 version 1903 or higher, or any version of Windows 11 (you're probably good if you've updated your PC in the last 4 years 😊). If you have an older version of Windows, you'll need to update it to use WSL 2. If you're already using a Linux distribution, you can skip the WSL 2 setup part. You can optionally use a virtual machine, if you have access to one, but it might be a bit more inconvenient.

Don't worry, WSL doesn't use much space on its own, maybe only 1-2GB for this part.

### Setting up WSL 2
1. Open PowerShell as an administrator and run the following command to enable WSL:
```powershell
wsl --install
```
The command will take a while to run, as it will download and install the necessary components. Accept any prompts to make changes to your computer. Once completed, you'll be prompted to restart your computer.  Seeing "Updates are underway" is normal.

In order to run WSL, you need to have virtualization enabled in your BIOS. Most modern computers have this enabled by default, but if you're having trouble, [you may need to enable it](https://support.microsoft.com/en-us/windows/enable-virtualization-on-windows-c5578302-6e43-4b4b-a449-8ced115f58e1). You'll see an error message after Windows restarts if you don't have it enabled.

2. After restarting, you'll be able to access WSL by searching for **Ubuntu** in the start menu. Click on it to open the Ubuntu terminal.

3. When prompted to create a new user, enter a username and password. This will be your Ubuntu username and password, not your Windows username and password. Please don't forget it!

3. Run the following command to update the Ubuntu packages:
```bash
sudo apt update && sudo apt upgrade -y
```
Note that this is the first time you're using the `sudo` keyword. This is used to run a command as the superuser, which is similar to running a command as an administrator on Windows. You'll need to enter your Ubuntu password to run a command with sudo. You won't see any characters as you type your password, but it's still being entered. Once you enter your password, press enter.

Also, if, at any time, you prefer to browse the Ubuntu file system, just open File Explorer like you normally would. There should be a new tab on the left side that says `Ubuntu`. Click on it to browse the Ubuntu file system. If for some reason you don't see it, you can also navigate to `\\wsl$\Ubuntu` in the address bar.

### Node.js
Node.js is a JavaScript runtime that allows you to run JavaScript on the server side. We will use it to run the Giving Connection project.
If you already have Node.js, note that version `v20.17.0` is required, which we will be installing. It's not guranteed that later versions will work, but you can try it.

We will be using `nvm`, or Node Version Manager, to manage multiple versions of Node.js on your machine. This will allow you to install the correct version of Node.js for the project without interfering with your current version.

1. Run the following command to install `nvm`:
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
```

2. Close and reopen Ubuntu to apply the changes. Verify installation by running:
```bash
nvm -v
```

3. Now, we'll install the correct version of Node.js for the project. Run the following command to install Node.js `v20.17.0`:
```bash
nvm install 20.17.0
```

4. Verify that the correct version of Node.js was installed by running:
```bash
node -v
```

Confirm that the version number is  `v20.17.0`. If it is, you can continue.

### Ruby
Ruby is the main programming language used in the project. It uses Ruby on Rails, a web application framework written in Ruby. We will use Ruby to run the Giving Connection project.

1. Run the following command to install rbenv, a Ruby version manager:
```bash
sudo apt install rbenv -y
```

2.  Install version `3.1.0` of Ruby by running:
```bash
rbenv install 3.1.0
```
*Note: This command takes a few minutes to run.*

3. Initialize rbenv and add it to your path by running:
```bash
rbenv init
```
```bash
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
```

4. Set the global version of Ruby to `3.1.0` by running:
```bash
rbenv global 3.1.0
```

5. Close and reopen Ubuntu to apply the changes. Verify installation by running:
```bash
ruby -v
```
You should see a version number that contains `3.1.0`, like `ruby 3.1.0p0 ...` if the installation was successful.

#### PostgreSQL
PostgreSQL is a powerful, open-source object-relational database system. We will use it to store the data for the Giving Connection project. **Regardless of team (frontend/backend), you will need to install PostgreSQL.** 

1. Run the following command to install PostgreSQL:
```bash
sudo apt install postgresql -y
```

2. Modify the configuration to listen to all IP addresses. 
    a. Run the following command to open the configuration file:
    ```bash
    sudo nano +$(cat /etc/postgresql/16/main/postgresql.conf | grep -n 'listen' | cut -d: -f1) /etc/postgresql/16/main/postgresql.conf
    ```
    b. You cursor should already be at the line `#listen_addresses = 'localhost'`. Uncomment the line by removing the `#` at the beginning of the line, and change `'localhost'` to `'*'`. Save the file by pressing <kbd>Ctrl</kbd> + <kbd>X</kbd>, then <kbd>Y</kbd>, then finally <kbd>Enter</kbd>.

3. Alter the PostgreSQL configuration to allow passwordless authentication:
    a. Run the following command to open the configuration file:
    ```bash
    sudo nano +$(cat /etc/postgresql/16/main/pg_hba.conf | grep -n 'host' | cut -d: -f1) /etc/postgresql/16/main/pg_hba.conf
    ```
    b. Use the arrow keys to move the cursor around. Replace any occurence of `peer` with `trust`. Save the file by pressing <kbd>Ctrl</kbd> + <kbd>X</kbd>, then <kbd>Y</kbd>, then finally <kbd>Enter</kbd>. You can ignore the permission denied message that appears after you save the file. 

4. Restart PostgreSQL by running:
```bash
sudo systemctl restart postgresql
```

5. Confirm that you can access the postgres command line by running:
```bash
psql -U postgres
```
You should see a prompt that looks like `postgres=#`. 

6. Create a test user so that the installation scripts later will work:
```sql
CREATE USER test WITH SUPERUSER;
```
Then, exit the postgres command line by running:
```sql
exit
```

#### Setting up Git with your Github Account
**Note: You can't skip this step if you have Github Desktop installed, since it's on Windows, not Ubuntu.**
Since our project is private, we can't just clone it without setting up Git with your Github account. Here's how to do that:

1. Install the Github CLI by running:
```bash
sudo apt install gh -y
```

2. Start the log in process:
```bash
gh auth login
```

3. Confirm that the `Github.com` option is selected, and press enter.

4. Confirm that the `HTTPS` option is selected, and press enter.

5. When asked if you want to Authenticate Git with your Github credentials, type `Y` and press enter.

6. Confirm that the `Login with a web browser` option is selected, and press enter.

7. Github will present a one-time code. Copy it, then press enter.

8. You'll get an error that you don't have a web broswer. This is fine, just use your typical web browser on WIndows to go to the URL that's provided, enter the code, and authorize the connection. 

#### Cloning the project
1. Navigate to the directory where you want to store the project. You can do this by running:
```bash
cd path/to/directory
```
2. Clone the project by running:
```bash
git clone https://github.com/Hack4ImpactRutgers/gc.git
```

3. Navigate into the project directory by running:
```bash
cd gc
```

**For the remainer of these instructions, please keep your terminal at this directory. To confirm your current directory in case you need to restart your terminal later, please run `pwd` now and you'll see the current direcory that your terminal is in.**

FYI: When you use VSCode, you should use the [WSL extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl) to connect to your WSL instance. Install it, type <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>P</kbd>, and search for `Connect to WSL`. Then, you can use *File* -> *Open Folder* to navigate to your preferred working directory like you would on Windows. To get back to your Windows file system, click on *WSL: Ubuntu* at the very bottom left, then click *Close Remote Connection*. This is similar to Remote SSH, if you've used it before.

#### Installing dependencies
Finally, we will install the project dependencies and run any other required commands.

1. Install bundler with gem:
```bash
gem install bundler
```

2. Install redis, cmake, and libpq-dev:
```bash
sudo apt install redis cmake libpq-dev -y
```

3. Install the Ruby Dependencies:
```bash
bundle install
```
*Ignore any warnings at the very end, this is ok.*

4. Install the global npm dependency, Yarn:
```bash
npm install -g yarn
```

5. Install the Yarn Dependencies:
```bash
yarn install
```
*You can ignore unmet peer dependency warnings.*

6. Install PostGIS (this is different than postgres):
```bash
sudo apt install postgis -y
```
*This command will take a bit longer to run.*

7. Install rails:
```bash
gem install rails
```
When asked if you want to overwrite the existing executable, type `y` and press enter.

8. Close and reopen the Ubuntu terminal to make the rails command available (make sure you `cd` back to the repository!).

9. Create the database:
```bash
rails db:create
```

11. Setup rake tasks:
```bash
rake db:gis:setup
```

12. Migrate the database:
```bash
rails db:migrate
```

13. Seed the database:
```bash
rails db:seed
```

14. Install puma:
```bash
gem install puma
```

15. Install foreman:
```bash 
gem install foreman
```

16. Restart the Ubuntu Terminal to apply the changes, then navigate back to the project directory.

17. Create this directory:
```bash
mkdir tmp/pids
```

18. Add the appropriate permissions:
```bash
chmod -R 775 tmp/pids
```

### Running the project
Finally, start the server!
```bash
bin/dev
```

If you see an error message claiming that `foreman` does not exist, close and reopen the terminal, then run `bin/dev` again.

Wait until you stop seeing the output scroll, then visit `localhost:3000` in your browser to see the project running! To stop the project at any time, press <kbd>Ctrl</kbd> + <kbd>C</kbd> in the terminal.

*Time to sleep 😑🛏️*.