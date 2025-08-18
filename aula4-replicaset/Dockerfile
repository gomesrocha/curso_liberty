# Use a base image with Java
FROM ibm-semeru-runtimes:open-11-jre

# Set environment variables for Liberty
ENV LIBERTY_VERSION 25.0.0.5
ENV WLP_INSTALL_DIR /opt/ibm
ENV SERVER_NAME defaultServer
ENV WLP_USER_DIR ${WLP_INSTALL_DIR}/wlp/usr
ENV SERVER_CONFIG_DIR ${WLP_USER_DIR}/servers/${SERVER_NAME}
ENV LOG_DIR /logs

# Create directories and set permissions
RUN mkdir -p ${LOG_DIR} \
    && chmod -R 777 ${LOG_DIR}

# Copy the Liberty installer JAR and install Liberty
# IMPORTANT: The wlp-nd-all-25.0.0.5.jar file must be in the same directory as the Dockerfile
COPY wlp-nd-all-25.0.0.5.jar /tmp/
RUN java -jar /tmp/wlp-nd-all-25.0.0.5.jar --acceptLicense ${WLP_INSTALL_DIR} \
    && rm /tmp/wlp-nd-all-25.0.0.5.jar

# Set up server environment
RUN ${WLP_INSTALL_DIR}/wlp/bin/server create ${SERVER_NAME}

# Argument for the server.xml file, to be passed during build
ARG SERVER_XML

# Copy the server configuration into the image
COPY ${SERVER_XML} ${SERVER_CONFIG_DIR}/server.xml

# Expose ports for HTTP, HTTPS, and command
EXPOSE 9080 9443 9043

# Start the server
CMD ["/opt/ibm/wlp/bin/server", "run", "defaultServer"]
