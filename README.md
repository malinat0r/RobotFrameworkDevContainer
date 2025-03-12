# RobotFrameworkDevContainer

The project describes steps to create and use/run Robot Framework Development container.

# Build docker image

```shell
docker build -t robotframework:v1 . 2>&1 | tee ./docker_build.log
```

# Usage

Robot Framework execution is normally started using the robot command. The path (or paths) to the test data to be executed is given as an argument after the command. Additionally, different command line options can be used to alter the test execution or generated outputs in many ways.

This image by default runs Robot Framework with two command line options - outputdir and path to the test data to be executed.  
Default directories are:
- Reports and log file directory path within container `/opt/robotframework/reports`
- Robot Frameork autotests source directory path within container `/opt/robotframework/tests`

This means  - In order to run Robot Framework autotests you have to bind this two mounts.

Launch this image:
```shell
# Bind folders using relative path
docker run --name robotframework \
  -it \
  --rm \
  --user $(id -u):$(id -g) \
  --mount type=bind,src=./RobotFrameworkSimpleExamples,dst=/opt/robotframework/tests \
  --mount type=bind,src=./reports,dst=/opt/robotframework/reports \
  robotframework:v1

# Bind folders using absolute path
docker run --name robotframework \
  -it \
  --rm \
  --user $(id -u):$(id -g) \
  --mount type=bind,src=${HOME}/dev/robotframework/RobotFrameworkSimpleExamples,dst=/opt/robotframework/tests \
  --mount type=bind,src=${HOME}/dev/robotframework/reports,dst=/opt/robotframework/reports \
  robotframework:v1

# Run with custom/defined folders and additional execution options (--name and --outputdir )
 docker run --name robotframework \
  -it \
  --rm \
  --user $(id -u):$(id -g) \
  --mount type=bind,src=${HOME}/dev/robotframework/RobotFrameworkSimpleExamples,dst=/opt/robotframework/tests \
  --mount type=bind,src=${HOME}/dev/robotframework/reports,dst=/opt/robotframework/reports \
  robotframework:v1 robot --name "Robot AutoTests" --outputdir /opt/robotframework/reports/ /opt/robotframework/tests/

# Define folder with test data to be executed. Output gets into workdir
 docker run --name robotframework \
  -it \
  --rm \
  --user $(id -u):$(id -g) \
  --mount type=bind,src=${HOME}/dev/robotframework/RobotFrameworkSimpleExamples,dst=/opt/robotframework/tests \
  --workdir /opt/robotframework/tests/ \
  robotframework:v1 robot /opt/robotframework/tests/
```
# Testing/Debugging

To debug the container:
```shell
docker logs -f robotframework

docker run --name robotframework \
    --rm \
    -it \
    -v ./reports:/opt/robotframework/reports \
    -v ./RobotFrameworkSimpleExamples:/opt/robotframework/tests \
    --user $(id -u):$(id -g) \
    robotframework:v1 bash
```

# Manage Permissions on output folder

Robot Framework runs using user:group `robotfw:robotfw` ( uid=1111, guid=1111 ) within container. This leads to `Permission denied` error on output folder.

```shell
labnet@LabNetVBoxStation:~/dev/robotframework$ docker run -it --rm --name robotframework  \
  -v ./example_requests:/opt/robotframework/tests \
  -v ./reports:/opt/robotframework/reports \
  -w /opt/robotframework/tmp \
  robotframework:v11 robot -d /opt/robotframework/reports/ /opt/robotframework/tests/

[ ERROR ] Opening output file '/opt/robotframework/reports/output.xml' failed: PermissionError: [Errno 13] Permission denied: '/opt/robotframework/reports/output.xml'

Try --help for usage information.

labnet@LabNetVBoxStation:~/dev/robotframework$ docker run -it --rm --name robotframework \
  -v ./example_requests:/opt/robotframework/tests \
  -v ./reports:/opt/robotframework/reports \
  -w /opt/robotframework/tmp \
  robotframework:v11 bash
robotfw@b2aeac9e8165:/opt/robotframework/tmp$ ls -la /opt/robotframework
total 28
drwxr-xr-x 1 root    root    4096 Mar  7 08:35 .
drwxr-xr-x 1 root    root    4096 Mar  5 14:36 ..
drwxrwxr-x 2    1000    1000 4096 Mar  5 13:35 reports
drwxrwxr-x 4    1000    1000 4096 Mar  7 08:14 tests
drwxr-xr-x 2 root    root    4096 Mar  7 08:35 tmp
drwxrwxr-x 2 robotfw robotfw 4096 Mar  5 14:36 workdir

labnet@LabNetVBoxStation:~$ docker top robotframework
UID                 PID                 PPID                C                   STIME               TTY                 TIME                CMD
labnet              5958                5938                0                   13:30               pts/0               00:00:00            bash
labnet@LabNetVBoxStation:~$
```
In order to resolve the issue use one of the approaches below.

## Use --user Docker option

```shell
docker run --name robotframework \
  -it \
  --rm \
  --user $(id -u):$(id -g) \
  --mount type=bind,src=./RobotFrameworkSimpleExamples,dst=/opt/robotframework/tests \
  --mount type=bind,src=./reports,dst=/opt/robotframework/reports \
  robotframework:v1
```

This approach resolves the permissions issue but may lead to other issues
```shell
# Run container with "--user" option
docker run -it --rm --name robotframework  --user $(id -u):$(id -g) -v ./example_requests:/opt/robotframework/tests  -v ./reports:/opt/robotframework/reports -w /opt/robotframework/tmp robotframework:v11 robot -d /opt/robotframework/reports/ /opt/robotframework/tests/

labnet@LabNetVBoxStation:~$ docker top robotframework
UID                 PID                 PPID                C                   STIME               TTY                 TIME                CMD
labnet              6126                6105                1                   11:30               pts/0               00:00:00            /usr/local/bin/python3.13 /usr/local/bin/robot -d /opt/robotframework/reports/ /opt/robotframework/tests/

labnet@LabNetVBoxStation:~$ ps -ef | grep python
labnet      6126    6105  4 11:30 pts/0    00:00:00 /usr/local/bin/python3.13 /usr/local/bin/robot -d /opt/robotframework/reports/ /opt/robotframework/tests/
labnet      6150    5853  0 11:30 pts/1    00:00:00 grep --color=auto python

labnet@LabNetVBoxStation:~$ docker exec -it robotframework /bin/bash
I have no name!@bbd18e4b33d4:/opt/robotframework/tmp$ whoami
whoami: cannot find name for user ID 1000
I have no name!@bbd18e4b33d4:/opt/robotframework/tmp$ echo ${HOME}
/
```
If you need to use user variables and commands (for example `${HOME}` , `whoami` ) you may run into issue.

## Use group and GUID at host

Assuming there is an unprivileged user (robotframework) within a contaner, we can create a group at host, add user(s) and setup mounting into container with required permissions.

- Get group `robotfw` GUID from container:
  ```shell
  ROBOT_GUID=$(docker run --name robotframework \
    -it \
    --rm \
    robotframework:v1 id -g)
  ```
  The command above returns number (for example `1111`) into `ROBOT_GUID` variable.

- Create group 
  ```shell
  sudo groupadd --gid ${ROBOT_GUID} devcontainer

  # Or define GUID manually without variable
  sudo groupadd --gid 1111 devcontainer
  ``

- Add user `labnet` to the created group `devcontainer`
  ```shell
  sudo usermod -aG devcontainer labnet
  ```

- Reconnect to console in order to see changes. Check the user group in order to make sure the  group has been added:
  ```shell
  ~$ id
  uid=1000(labnet) gid=1000(labnet) groups=1000(labnet),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),100(users),114(lpadmin),982(docker),1111(devcontainer)
  ```

- Create folder with write permissions for the group:
  ```shell
  mkdir -p ${HOME}/devcontainer/reports
  sudo chown :devcontainer ${HOME}/devcontainer/reports
  sudo chmod 770 ${HOME}/devcontainer/reports  # read/write for user and group
  ```

- Run the container:
  ```shell
  docker run --name robotframework \
    -it \
    --rm \
    --user robotfw:robotfw \
    --mount type=bind,src=./RobotFrameworkSimpleExamples,dst=/opt/robotframework/tests \
    --mount type=bind,src=${HOME}/devcontainer/reports,dst=/opt/robotframework/reports \
    robotframework:v1
  ```

> ❗ This approach allows using user variables and commands but leads to __permission error__ in browsers (Chrome, Firefox) on attempt to open generated log and report files due to file owner mismatch (despite to group read permissions).

## Mount the host machine’s /etc/passwd and /etc/group to a container

One more approach, which is used in [VSCode Devcontainers](https://code.visualstudio.com/remote/advancedcontainers/add-nonroot-user#_specifying-a-user-for-vs-code) project  - update `/etc/passwd` and `/etc/groups` in container with `UID` and `GID` of host user running the dev-container. But i'd siggest to mount these files into container all the time instead of rebuilding the container.

Create files at host:
```shell
# Create folder for devcontainer config files
mkdir ${HOME}/devcontainer/etc

# Create "/etc/group" file
cat <<EOF > ${HOME}/devcontainer/etc/group
root:x:0:
daemon:x:1:
bin:x:2:
sys:x:3:
adm:x:4:
tty:x:5:
disk:x:6:
lp:x:7:
mail:x:8:
news:x:9:
uucp:x:10:
man:x:12:
proxy:x:13:
kmem:x:15:
dialout:x:20:
fax:x:21:
voice:x:22:
cdrom:x:24:
floppy:x:25:
tape:x:26:
sudo:x:27:
audio:x:29:
dip:x:30:
www-data:x:33:
backup:x:34:
operator:x:37:
list:x:38:
irc:x:39:
src:x:40:
shadow:x:42:
utmp:x:43:
video:x:44:
sasl:x:45:
plugdev:x:46:
staff:x:50:
games:x:60:
users:x:100:
nogroup:x:65534:
robotfw:x:$(id -g):
EOF

# Create "/etc/passwd" file
cat <<EOF > ${HOME}/devcontainer/etc/passwd
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync
games:x:5:60:games:/usr/games:/usr/sbin/nologin
man:x:6:12:man:/var/cache/man:/usr/sbin/nologin
lp:x:7:7:lp:/var/spool/lpd:/usr/sbin/nologin
mail:x:8:8:mail:/var/mail:/usr/sbin/nologin
news:x:9:9:news:/var/spool/news:/usr/sbin/nologin
uucp:x:10:10:uucp:/var/spool/uucp:/usr/sbin/nologin
proxy:x:13:13:proxy:/bin:/usr/sbin/nologin
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
backup:x:34:34:backup:/var/backups:/usr/sbin/nologin
list:x:38:38:Mailing List Manager:/var/list:/usr/sbin/nologin
irc:x:39:39:ircd:/run/ircd:/usr/sbin/nologin
_apt:x:42:65534::/nonexistent:/usr/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
robotfw:x:$(id -u):$(id -g):Robot Framework User:/home/robotfw:/bin/bash
EOF
```

Since changing UID/GID does not automatically update existing files/directory ownership, you either need to:
- Fix permissions for the user's files within container:
  ```shell
  sudo find / -user OLD_UID -exec chown -h NEW_UID {} \;
  sudo find / -group OLD_GID -exec chgrp -h NEW_GID {} \;
  ```
  It require running entrypoint script within container on startup with [suid bit](https://en.wikipedia.org/wiki/Setuid) (which is not secure) or installing `sudo` utility into container, which is not recommended as well.
- Define new (not existent) [`workdir`](https://docs.docker.com/reference/cli/docker/container/run/#workdir) when running container. If the `WORKDIR` doesn't exist, it will be created with correct permissions.
  ```shell
  docker run --name robotframework \
    -it \
    --rm \
    --user $(id -u):$(id -g) \
    --mount type=bind,src=./RobotFrameworkSimpleExamples,dst=/opt/robotframework/tests \
    --mount type=bind,src=${HOME}/devcontainer/reports,dst=/opt/robotframework/reports \
    --mount type=bind,source=${HOME}/devcontainer/etc/passwd,target=/etc/passwd,readonly \
    --mount type=bind,source=${HOME}/devcontainer/etc/group,target=/etc/group,readonly \
    --workdir /opt/robotframework/tmp
    robotframework:v1  
  ```
- Bind mount for workdir as well. I'd recomment this approach, assiming temporary files may be used in investigation of failed tests.
    ```shell
  docker run --name robotframework \
    -it \
    --rm \
    --user $(id -u):$(id -g) \
    --mount type=bind,src=./RobotFrameworkSimpleExamples,dst=/opt/robotframework/tests \
    --mount type=bind,src=${HOME}/devcontainer/reports,dst=/opt/robotframework/reports \
    --mount type=bind,source=${HOME}/devcontainer/etc/passwd,target=/etc/passwd,readonly \
    --mount type=bind,source=${HOME}/devcontainer/etc/group,target=/etc/group,readonly \
    --mount type=bind,source=${HOME}/devcontainer/workdir,target=/opt/robotframework/workdir \
    robotframework:v1  
  ```

## Resources 
- [stackoverflow.com](https://stackoverflow.com/questions/71918710/allow-docker-container-host-user-to-write-on-bind-mounted-host-directory)
- [Visual Studio Code. Developing inside a Container](https://code.visualstudio.com/docs/devcontainers/containers)
- [An open specification for enriching containers with development specific content and settings. ](https://containers.dev/)
- [@ppodgorsek Paul Podgorsek. Robot Framework in Docker, with Firefox, Chrome and Microsoft Edge](https://github.com/ppodgorsek/docker-robot-framework/)