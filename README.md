# Setting up the Giving Connection Project
Welcome Hack4Impact team! Please follow these instructions to set up the Giving Connection project on your local machine. If you have any questions, please reach out to one of the directors. <br>

Note: These intructions were written based on fresh installations of Mac and Windows operating systems, to curate best for all skill levels. It is possible that you may already have some of the required software installed during these instructions. If so, you can most likely skip those steps if you see some kind of success message.

## Click to see instructions for your operating system:
- [Mac](#mac)
- [Windows](#windows)

## Mac
Note: The project will require about 13GB of free space on your machine.

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

## Windows/Linux
Space Needed: 

I've tried for hours to try to get it to work natively with Windows, but unfortunately, it's just not possible. The project uses a lot of tools that are not compatible with Windows, and it's just not worth the effort to try to get it to work. However, you can still run the project on Windows by using the Windows Subsystem for Linux (WSL). Here's how to set it up:

Note: These instructions are for WSL 2, which is only available on Windows 10 version 1903 or higher, or any version of Windows 11. If you have an older version of Windows, you'll need to update it to use WSL 2. If you're already using a Linux distribution, you can skip the WSL 2 setup part. You can optionally use a virtual machine, if you have access to one, but it might be a bit more inconvenient.

### Setting up WSL 2
1. Open PowerShell as an administrator and run the following command to enable WSL:
```powershell
wsl --install
```
The command will take a while to run, as it will download and install the necessary components. Once completed, you'll be prompted to restart your computer.

2. After restarting, you'll be able to access WSL by searching for "Ubuntu" in the start menu. Click on it to open the Ubuntu terminal.

3. When prompted to create a new user, enter a username and password. This will be your Ubuntu username and password, not your Windows username and password. Please don't forget it!

3. Run the following command to update the Ubuntu packages:
```bash
sudo apt update && sudo apt upgrade -y
```

### Node.js
Node.js is a JavaScript runtime that allows you to run JavaScript on the server side. We will use it to run the Giving Connection project.
If you already have Node.js, note that version `v20.17.0` is required, which we will be installing.

We will be using `nvm`, or Node Version Manager, to manage multiple versions of Node.js on your machine. This will allow you to install the correct version of Node.js for the project without interfering with your current version.

1. Run the following command to install `nvm`:
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
```

2. Close and reopen Ubuntu to apply the changes. Verify installation by running:
```bash
nvm --version
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
node --version
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

3. Initialize rbenv and add it to your path by running:
```bash
rbenv init && echo 'eval "$(rbenv init -)"' >> ~/.bashrc
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
PostgreSQL is a powerful, open-source object-relational database system. We will use it to store the data for the Giving Connection project. **Regardless of team (frontend/backend), you will need to install PostgreSQL.** If you already have PostgreSQL installed, you can skip this step.

1. Run the following command to install PostgreSQL:
```bash
sudo apt install postgresql -y
```

2. Confirm that PostgreSQL is running by running:
```bash
sudo systemctl status postgresql
```
You should see a message that says `active (running)` if PostgreSQL is running.

3. Alter the PostgreSQL configuration to allow passwordless access. Run the following command to open the configuration file:
```bash
sudo nano /etc/postgresql/16/main/pg_hba.conf
```

4. Use down arrows keys to navigate to the bottom of the file. Replace any occurence of `peer` or `scram-sha-256` with `trust`. Save the file by pressing <kbd>Ctrl</kbd> + <kbd>O</kbd>, then press enter, then exit by pressing <kbd>Ctrl</kbd> + <kbd>X</kbd>.

5. Restart PostgreSQL by running:
```bash
sudo systemctl restart postgresql
```

#### Setting up Git with your Github Account
**If you already have Github Desktop installed and set up with your Github account, you can skip this step.**
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

7. A browser window will open, asking you to log in to your Github account. Log in, enter the code, click on `Authorize github` and close the browser window.

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

8. Close and reopen the Ubuntu terminal to make the rails command available.


9. Create the database:
```bash
rails db:create
```

10. Associate postgres with PostGIS:
```bash
psql -d giving_connection_development
```
then run:
```sql
CREATE EXTENSION IF NOT EXISTS PostGIS;
exit
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

### Running the project
Finally, start the server!
```bash
bin/dev
```

Wait until you stop seeing the output scroll, then visit `localhost:3000` in your browser to see the project running! To stop the project at any time, press <kbd>Ctrl</kbd> + <kbd>C</kbd> in the terminal.
