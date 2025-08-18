FROM registry.access.redhat.com/ubi8/openjdk-17

COPY --chown=185:0 wlp-nd-all-25.0.0.5.jar /tmp/

RUN java -jar /tmp/wlp-nd-all-25.0.0.5.jar --acceptLicense /opt/ibm && \
    rm /tmp/wlp-nd-all-25.0.0.5.jar

RUN /opt/ibm/wlp/bin/installUtility install collectiveController-1.0 collectiveMember-1.0 adminCenter-1.0 ssl-1.0 restConnector-2.0 --acceptLicense

ENV LIBERTY_HOME=/opt/ibm/wlp
ENV PATH=$PATH:$LIBERTY_HOME/bin

COPY --chown=185:0 entrypoint.sh /opt/entrypoint.sh
RUN chmod +x /opt/entrypoint.sh

ENTRYPOINT ["/opt/entrypoint.sh"]