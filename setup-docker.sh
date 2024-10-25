#!/bin/bash

echo "Giving Connection Docker Method Setup Script started."
sleep 1
echo "This command will take at least 2 full minutes to complete."
sleep 1

echo -e "\033[1;34mMaking necessary file changes...\033[0m"
# Make necessary file changes
sed -i '' 's|redis://localhost:6379|redis://redis:6379|g' .env
sed -i '' 's|ruby "3.1.0"|ruby "~> 3.1.0"|g' Gemfile

sed -i '' 's|#username: giving_connection|username: postgres|g' config/database.yml
sed -i '' 's|#host: localhost|host: db|g' config/database.yml

sed -i '' '62i\
  host: db' config/database.yml
sed -i '' '63i\
  username: postgres' config/database.yml

echo "Appending modified files to .gitignore..."
echo ".env" >> .gitignore
echo "config/database.yml" >> .gitignore
echo "Gemfile" >> .gitignore


echo -e "\033[1;34mPulling the image and initializing the container (this will take some time!)...\033[0m"
sleep 1
echo ""

if docker-compose build --no-cache; then
    echo ""
    echo -e "\033[1;32mImage built successfully!\033[0m"
    sleep 1
else
    echo ""
    echo -e "\033[1;31mError building the image.\033[0m"
    exit 1
fi

echo -e "\033[1;34mStarting the container...\033[0m"
sleep 1

if docker-compose up -d; then
    echo ""
    echo -e "\033[1;32mContainer started successfully!\033[0m"
    sleep 1
else
    echo ""
    echo -e "\033[1;31mError starting the container.\033[0m"
    exit 1
fi

# Corrected the logging command to ensure proper script execution
docker-compose logs -f web
