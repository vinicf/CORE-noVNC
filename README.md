# CORE-noVNC

# Repository content
The repository is meant to run CORE with a noVNC web UI, either from a published GHCR image or from a local Docker build.

The image has CORE 9.2.1 installed with dependencies for running several services, such as SSH, HTML, FTP, telnet, etc.
It has been created using the Dockerfile available in this repo.

Scripts:
- manage-container.sh starts, stops, inspects, and tails the running container.

The runtime script does the following:
- Creates a shared volume defined in SHARED variable ($SHARED:/shared).
- Exposes the CORE GUI through noVNC on http://127.0.0.1:6080/vnc.html.
- Can optionally forward the host's 2022 port to container's 22 when started with `--ssh`.


## How to run it
- Clone the repository anywhere you want.
- Make sure the script has execute permissions: chmod 740 manage-container.sh
- Show the available commands and usage: `./manage-container.sh --help`
- Run the container with the default GHCR image: `./manage-container.sh start`
- Run the container with optional SSH access: `./manage-container.sh start --ssh`
- Stop the running container cleanly: `./manage-container.sh stop`
- Check whether the container is running: `./manage-container.sh status`
- Follow the container logs again later: `./manage-container.sh logs`
- ENJOY

## Image selection
- By default, `manage-container.sh` uses `ghcr.io/vinicf/core-novnc:latest`.
- Override the image at runtime with `CORE_IMAGE=<image-ref>`.
- The script automatically tries `docker pull` when the selected image is not present locally.

## Local build workflow
- Build a local image from this repository with:
    - `docker build -t core-novnc:local .`
- Run that local image with:
    - `CORE_IMAGE=core-novnc:local ./manage-container.sh start`
- You can also combine it with SSH:
    - `CORE_IMAGE=core-novnc:local ./manage-container.sh start --ssh`

## Publishing to GHCR
- Authenticate Docker to GHCR:
    - First, create a [Personal Access Token (classic)](https://github.com/settings/tokens/new) with the `write:packages` and `read:packages` scopes.
    - `echo <github-token> | docker login ghcr.io -u <github-user> --password-stdin`
- Build the image with the GHCR tag:
    - `docker build -t ghcr.io/vinicf/core-novnc:latest .`
- Push it:
    - `docker push ghcr.io/vinicf/core-novnc:latest`
- For versioned releases, tag explicitly before pushing, for example:
    - `docker tag ghcr.io/vinicf/core-novnc:latest ghcr.io/vinicf/core-novnc:9.2.1`
    - `docker push ghcr.io/vinicf/core-novnc:9.2.1`

## Codespaces
- Codespaces should use the prebuilt GHCR image instead of compiling the whole stack during startup.
- The default `manage-container.sh start` path is already aligned with that model.
- If you need a different remote tag for a classroom or lab, set `CORE_IMAGE` in the Codespace environment.

## What else
- You can exchange files between container and host machine using the shared volume. Anything in your host $SHARED dir is accessible via container's /shared dir, and vice-versa.
- You can use the Dockerfile to create your own image, adding more libs or software, and point `manage-container.sh` to it with `CORE_IMAGE`.

## Optional SSH access
- SSH is disabled by default. Enable it only when needed with: `./manage-container.sh start --ssh`
- After the container is running, install a public key as authorized_keys, and use the private key to access the container via ssh.
- The example below uses the key pair named id_ed25519 (private) and id_ed25519 (public) under ~/.ssh/ dir. If you use a different keypair, replace ~/.ssh/id_ed25519.pub and the matching private key path in the commands.
- Adding the key:
    - `docker exec -i core sh -c 'umask 077; mkdir -p /root/.ssh; cat >> /root/.ssh/authorized_keys' < ~/.ssh/id_ed25519.pub`
- Then connect:
    - `ssh -i ~/.ssh/id_ed25519 root@127.0.0.1 -p 2022`

## Custom services
- start-up.sh is the runtime hook that points CORE to /shared so you can mount custom services when you start a new container.
- start-up.sh should stay. It is still the container entrypoint that wires `/shared` into CORE, conditionally starts `sshd`, and launches Xvfb, noVNC, `core-daemon`, and `core-gui`.
- You could inline that logic into the Dockerfile only by replacing it with a long shell `CMD` or another embedded script, which would be harder to maintain. Keeping start-up.sh is the cleaner option.
