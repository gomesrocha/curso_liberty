# Laboratório de automação

Criar o arquivo .sh e tornar ele executável com chmod +x, exemplo
arquivo verificaporta.sh
chmod +x verificaporta.sh

Passo 1:
Verificando porta com o bash

  ```bash
#!/bin/bash
PORT=$1
SERVER_NAME=$2
LIBERTY_PATH="/home/liberty-base00/wlp"

if [ -z "$PORT" ] || [ -z "$SERVER_NAME" ]; then
   echo "Uso: $0 porta nome_servidor"
   exit 1
fi

netstat -an |grep $PORT && echo "Porta: $PORT escultando" || echo "Porta: $PORT não escultando"


  ```


Passo 2: 
Verificando servidor com o Bash
  ```bash
#!/bin/bash
SERVER_NAME=$1
LIBERTY_PATH="/home/liberty-base00/wlp"
LOG_PATH="$LIBERTY_PATH/usr/servers/$SERVER_NAME/logs/messages.log"

if [ -z "$SERVER_NAME" ]; then
    echo "Uso: $0 nome_servidor"
    exit 1
fi

$LIBERTY_PATH/bin/server  status $SERVER_NAME || echo "O Servidor $SERVER_NAME não está rodando"

grep -E "CWPKI0033E|CWWKG0014E|CWWKS9582E|CWWKO0221E" $LOG_PATH && echo "Error encontrados" || echo "Nenhum erro de log"


tail -f $LOG_PATH


  ```


Passo 3 
Verificando certificado com o Bash
  ```bash

#!/bin/bash
SERVER_NAME=$1
PORT=$2
LIBERTY_PATH="/home/liberty-base00/wlp"
SENHA_SERVER="senhaSegura"

KEYSTORE="$LIBERTY_PATH/usr/servers/$SERVER_NAME/resources/security/key.p12"

if [ -z "$SERVER_NAME" ] || [ -z "$PORT" ]; then
  echo "Uso: $0 nome_servidor porta"
  exit 1
fi

keytool -list -v -keystore $KEYSTORE -storepass $SENHA_SERVER |grep -E "Valid from|util" || echo "Keystore invalida ou senha incorreta"

openssl s_client -connect localhost:$PORT


  ```