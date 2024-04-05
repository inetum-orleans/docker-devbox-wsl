# Docker Devbox with WSL2
You know the Docker Devbox with Vagrant.

If you want learn more on Docker Devbox, you can read this article: [Docker Devbox](https://github.com/inetum-orleans/docker-devbox)

But now, with WSL2, you can have a Docker Devbox without the overhead of a VM. This is a simple and lightweight setup to get you started.

Less space allowed, less memory used, less CPU used, less overhead.

And you don't even have to install Docker Desktop and therefore without license limitation linked to Docker Desktop.

## Requirements
WSL2 with Ubuntu and check if git is installed, if not install it.

## Installation
Clone this project inside your WSL and run the following command in the project directory:
```bash
git clone https://github.com/inetum-orleans/docker-devbox-wsl.git

cd docker-devbox-wsl

./install.sh
```
The script will ask you for your password only once to install docker and docker-compose and Docker Devbox.

And tada 🎉 you have a Docker Devbox running on WSL2.

Happy coding!
