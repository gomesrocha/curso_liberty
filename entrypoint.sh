#!/bin/bash

SERVER_NAME=${NAME:-defaultServer}
KEYSTORE_PASS=pass123
ADMIN_USER=admin
ADMIN_PASS=adminpass
CONTROLLER_PORT=9443

# Cria o servidor se não existir
if [ ! -d "$LIBERTY_HOME/usr/servers/$SERVER_NAME" ]; then
  server create $SERVER_NAME

  # Configura baseado no role
  if [ "$ROLE" = "controller" ]; then
    collective create $SERVER_NAME --keystorePassword=$KEYSTORE_PASS --createConfigFile=$LIBERTY_HOME/usr/servers/$SERVER_NAME/include.xml
    
    # Adiciona include no server.xml
    sed -i '/<\/server>/i <include location="include.xml"/>' $LIBERTY_HOME/usr/servers/$SERVER_NAME/server.xml
    
    # Configura host=* no httpEndpoint
    sed -i 's/host="localhost"/host="*"/' $LIBERTY_HOME/usr/servers/$SERVER_NAME/server.xml
    
    # Configura quickStartSecurity no include.xml
    sed -i "s/userName=\"\"/userName=\"$ADMIN_USER\"/" $LIBERTY_HOME/usr/servers/$SERVER_NAME/include.xml
    sed -i "s/userPassword=\"\"/userPassword=\"$ADMIN_PASS\"/" $LIBERTY_HOME/usr/servers/$SERVER_NAME/include.xml

  elif [ "$ROLE" = "replica" ]; then
    # Espera o controlador estar pronto
    until curl -k -f -u $ADMIN_USER:$ADMIN_PASS https://$CONTROLLER_HOST:$CONTROLLER_PORT/IBMJMXConnectorREST/ >/dev/null 2>&1; do
      echo "Aguardando controlador em $CONTROLLER_HOST:$CONTROLLER_PORT..."
      sleep 5
    done
    
    collective replica $SERVER_NAME --host=$CONTROLLER_HOST --port=$CONTROLLER_PORT --user=$ADMIN_USER --password=$ADMIN_PASS --keystorePassword=$KEYSTORE_PASS
    
    # Adiciona include no server.xml (assume que cria replica.xml)
    sed -i '/<\/server>/i <include location="replica.xml"/>' $LIBERTY_HOME/usr/servers/$SERVER_NAME/server.xml
    
    # Configura host=*
    sed -i 's/host="localhost"/host="*"/' $LIBERTY_HOME/usr/servers/$SERVER_NAME/server.xml

  elif [ "$ROLE" = "member" ]; then
    # Espera o controlador estar pronto
    until curl -k -f -u $ADMIN_USER:$ADMIN_PASS https://$CONTROLLER_HOST:$CONTROLLER_PORT/IBMJMXConnectorREST/ >/dev/null 2>&1; do
      echo "Aguardando controlador em $CONTROLLER_HOST:$CONTROLLER_PORT..."
      sleep 5
    done
    
    collective join $SERVER_NAME --host=$CONTROLLER_HOST --port=$CONTROLLER_PORT --user=$ADMIN_USER --password=$ADMIN_PASS --keystorePassword=$KEYSTORE_PASS --autoAcceptSigner
    
    # Adiciona feature collectiveMember-1.0
    sed -i '/<featureManager>/a <feature>collectiveMember-1.0</feature>' $LIBERTY_HOME/usr/servers/$SERVER_NAME/server.xml
    
    # Configura host=*
    sed -i 's/host="localhost"/host="*"/' $LIBERTY_HOME/usr/servers/$SERVER_NAME/server.xml

  fi
fi

# Inicia o servidor
server run $SERVER_NAME