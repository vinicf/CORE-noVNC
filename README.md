# IRC PL code base

## Repository content
1. run-docker.sh - Shell script to run a dockerized version of [Common Open Research Emulator (CORE)](https://coreemu.github.io/core/).
2. Dockerfile - The dockerfile used to generate the CORE docker
3. password.txt - Text file used on image build to create a password for root user in CORE docker image 

### run-docker.sh
The run-docker.sh script uses by default the [vinicf/core-9.0.3:latest](https://hub.docker.com/r/vinicf/core-9.0.3) CORE image. 

The image has CORE 9.0.3 installed with all IRC TP dependencies (check the Dockerfile for reference).

The script  runs a container and it also does the following:
- Creates a shared volume defined in *SHARED* variable ($SHARED:/shared).
- Shares the host display to run core-gui.
- Forwards the host's *2000* port to container's 22, enabling external ssh access.
- Injects the *~/.ssh/id_ed25519.pub* as an authorized host key (it does not create the keypair previously).

#### How to run it
- Clone the repo into your home directory (it uses $HOME as a path reference for the shared directory):
    - `git clone https://github.com/vinicf/IRC.git`
- Step into the cloned directory:
    - `cd ./IRC/`
- If you do not have an id_ed25519 and id_ed25519.pub key pairs, create it using the command:
    - `ssh-keygen -t ed25519`
- Make sure the run-docker.sh has execute permissions, recommended permissions:
    - `chmod 740 run-docker.sh`
- Run the run-docker.sh script:
    - `./run-docker.sh`
- ENJOY

#### What else
- You can access the container via ssh, using the ~/.ssh/id_ed25519 key. E.g. if you are running it in your localhost:
    - `ssh -i ~/.ssh/id_ed25519 root@127.0.0.1 -p 2000`
- The default container's root password is **core**
- You can exchange files between container and host machine using the shared volume. Anything in your host $SHARED dir is accessible via container's /shared dir, and vice-versa.

### Dockerfile
- You can use the Dockerfile to create your own image, adding more libs, software, etc. Just remember to update the image in run-docker.sh script to run your custom one.
- This Dockerfile uses docker buildx to enable multi-platform building and uses a secret to configure the user password, which is stored in password.txt file.
- To build it for a specific platform, use the --platform option and use the password.txt file as a secret. To build for amd64 and arm64:
    - `docker buildx build --secret id=my_password,src=password.txt --platform linux/amd64,linux/arm64 .`
