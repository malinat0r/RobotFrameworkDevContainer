# RobotFrameworkDevContainer
Robot Framework Development container

# Build docker image

```shell
docker build -t robotframework:v1 . 2>&1 | tee ./docker_build.log
```

# Usage

Execution is normally started using the robot command.
The path (or paths) to the test data to be executed is given as an argument after the command. Additionally, different command line options can be used to alter the test execution or generated outputs in many ways.

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
