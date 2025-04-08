# Giving Connection - Event Functionality Collaboration with Hack4Impact Rutgers

Most of the team used Docker to run the project locally. Matthew added this to make it easier for everyone since we are a team with a wide variety of personal laptops (Mac, Windows), so dependency conflicts are highly likely from one device to the next.

## Docker Installation Instructions

1. Install Docker Desktop. You won't be interacting with the application directly, but it installs the shell as well which we will be using more often. Make sure you do this before you use VSCode or any other Terminal. If you know what you're doing, you can skip this step.

2. Run the setup script in PowerShell/WSL (Windows) or Terminal (Mac/Linux):
```
bash setup-docker.sh
```

3. Once the output has stopped scrolling super fast, go to [http://localhost:3000](http://localhost:3000) in your browser and see it up and running!

4. You can stop following the logs at any time with <kbd>Ctrl</kbd> + <kbd>C</kbd>. This doesn't shut down the container though. See the next section for that.

### Running After Setup
You can stop running the project at any time by typing
```bash
docker-compose down
```

And then restart at any time with
```bash
docker-compose up -d
# If you want to follow the logs again (recommended)
docker-compose logs -f web
```

You can also use the in-built start/stop buttons in the Docker Desktop UI.

### Also Useful
If you ever need to remove existing volumes from Docker (this removes everything!)
```bash
docker system prune -a --volumes
``` 
