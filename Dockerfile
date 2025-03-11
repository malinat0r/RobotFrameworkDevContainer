FROM python:3.13.2-slim-bookworm

LABEL authors="Evgeny Malinovsky malinovskogo@gmail.com",description="Demo Robot Framework in Docker"

# Set the reports directory environment variable
ENV ROBOT_REPORTS_DIR=/opt/robotframework/reports

# Set the tests directory environment variable
ENV ROBOT_TESTS_DIR=/opt/robotframework/tests

# Set the working directory environment variable
ENV ROBOT_WORK_DIR=/opt/robotframework/workdir

# Define the default user who'll run the tests
ENV ROBOT_USER=robotfw \
    ROBOT_GROUP=robotfw \
    ROBOT_UID=1111 \
    ROBOT_GID=1111

# Install Robot Framework and associated libraries
COPY ./requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir --requirement /tmp/requirements.txt \
# Add user 
  && groupadd --gid ${ROBOT_GID} ${ROBOT_GROUP} && useradd --comment "Robot Framework User" --create-home --shell=/bin/bash --uid ${ROBOT_UID} -g ${ROBOT_GROUP} ${ROBOT_USER} \
# Create the default report and work folders with the default user to avoid runtime issues
  && mkdir -p ${ROBOT_REPORTS_DIR} \
  && mkdir -p ${ROBOT_WORK_DIR} \
  && mkdir -p ${ROBOT_TESTS_DIR} \
  && chown ${ROBOT_USER}:${ROBOT_GROUP} ${ROBOT_REPORTS_DIR} ${ROBOT_WORK_DIR} ${ROBOT_TESTS_DIR} \
  && chmod ug+w ${ROBOT_REPORTS_DIR} ${ROBOT_WORK_DIR}

WORKDIR ${ROBOT_WORK_DIR}

USER ${ROBOT_USER}:${ROBOT_GROUP}

# Execute all robot tests
CMD  [ "bash", "-c", "robot -d ${ROBOT_REPORTS_DIR} ${ROBOT_TESTS_DIR}" ]