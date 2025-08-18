Vamos criar um script que faça nosso trabalho de validar se o servidor está ok

                                                                                   
#!/bin/bash
SERVER_NAME=$1
LIBERTY_PATH="/home/liberty-base00/wlp"
LOG_PATH="$LIBERTY_PATH/usr/servers/$SERVER_NAME/logs/messages.log"

if [ -z "$SERVER_NAME" ]; then
  echo "Uso: $0 nome_servidor"
  exit 1
fi

# Check se servidor roda
$LIBERTY_PATH/bin/server status $SERVER_NAME || echo "Servidor $SERVER_NAME não rodando."

# Check se servidor roda
$LIBERTY_PATH/bin/server status $SERVER_NAME || echo "Servidor $SERVER_NAME não rodando."

# Grep erros comuns em logs
grep -E "CWPKI0033E|CWWKG0014E|CWWKS9582E" $LOG_PATH && echo "Erros encontrados: Verifique keystore/senha ou XML." || echo "Nenhum erro comum em logs."

# Tail logs para monitoramento
tail -f $LOG_PATH


### Agora vamos criar um que verifica a porta do servidor
  GNU nano 7.2                                                                         liberty_check_ports.sh                                                                                   
#!/bin/bash
PORT=$1
SERVER_NAME=$2
LIBERTY_PATH="/home/liberty-base00/wlp"

if [ -z "$PORT" ] || [ -z "$SERVER_NAME" ]; then
  echo "Uso: $0 porta nome_servidor"
  exit 1
fi

# Check porta escutando
netstat -an | grep $PORT && echo "Porta $PORT escutando." || echo "Porta $PORT não escutando - verifique firewall ou config."

# Check certificado
KEYSTORE="$LIBERTY_PATH/usr/servers/$SERVER_NAME/resources/security/key.p12"
keytool -list -v -keystore $KEYSTORE -storepass senhaSegura | grep -E "Valid from|until" || echo "Keystore inválido ou senha errada."

# Teste conexão SSL
openssl s_client -connect localhost:$PORT -showcerts



E um ultimo de verificação do servidor

  GNU nano 7.2                                                                          liberty_auto_test.sh                                                                                    
#!/bin/bash
SERVER_NAME=$1
PORT=9447
LIBERTY_PATH="/home/liberty-base00/wlp"

echo "Testando $SERVER_NAME na porta $PORT..."

# Status servidor
$LIBERTY_PATH/bin/server status $SERVER_NAME

# Check logs
grep "ERROR" $LIBERTY_PATH/usr/servers/$SERVER_NAME/logs/messages.log

# Check porta
netstat -an | grep $PORT

# Check cert expiração
openssl s_client -connect localhost:$PORT -showcerts | grep -A5 "Certificate chain"






# Automação
Atualizar sistema
sudo apt update && sudo apt upgrade -y
Instalar dependencias
sudo apt install -y software-properties-common

adicionar repositório do ansible
sudo apt-add-repository --yes --update ppa:ansible/ansible

instalar o ansible
sudo apt install -y ansible

verificar se está instalado e funcionando 
ansible --version
crie um diretório chamado ansible
mkdir ansible
entre no diretório
cd ansible

crie um arquivo chamado host
conteúdo:
[local]
localhost ansible_connection=local

Vamos testar este endereço
ansible -i hosts  all -m ping
Deve retornar algo parecido com isso:
localhost | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3.12"
    },
    "changed": false,
    "ping": "pong"
}


Agora vamos criar nosso playbook.yml inicial
conteúdo:
- name: Teste de Setup Basico no Liberty
  hosts: local  # Grupo do hosts file
  become: yes   # Usa sudo
  tasks:
    - name: Atualizar pacotes
      apt:
        update_cache: yes

    - name: Instalar Java (se nao tiver)
      apt:
        name: openjdk-11-jdk
        state: present

    - name: Verificar se Liberty esta rodando
      command: /home/liberty-base00/wlp/bin/server status minhaAplicacaoCertificada
      register: liberty_status
      ignore_errors: yes

    - debug:
        msg: "Status do Liberty: {{ liberty_status.stdout }}"

Vamos testar
ansible-playbook -i hosts playbook.yml 
o -i host indica o servidor e o playbook as ações

resultado:

PLAY [Teste de Setup Basico no Liberty] ********************************************************************************************************************************************************

TASK [Gathering Facts] *************************************************************************************************************************************************************************
[WARNING]: Platform linux on host localhost is using the discovered Python interpreter at /usr/bin/python3.12, but future installation of another Python interpreter could change the meaning
of that path. See https://docs.ansible.com/ansible-core/2.18/reference_appendices/interpreter_discovery.html for more information.
ok: [localhost]

TASK [Atualizar pacotes] ***********************************************************************************************************************************************************************
changed: [localhost]

TASK [Instalar Java (se nao tiver)] ************************************************************************************************************************************************************
ok: [localhost]

TASK [Verificar se Liberty esta rodando] *******************************************************************************************************************************************************
fatal: [localhost]: FAILED! => {"changed": true, "cmd": ["/home/liberty-base00/wlp/bin/server", "status", "minhaAplicacaoCertificada"], "delta": "0:00:00.280719", "end": "2025-08-14 11:16:49.228343", "msg": "non-zero return code", "rc": 1, "start": "2025-08-14 11:16:48.947624", "stderr": "", "stderr_lines": [], "stdout": "\nServer minhaAplicacaoCertificada is not running.", "stdout_lines": ["", "Server minhaAplicacaoCertificada is not running."]}
...ignoring

TASK [debug] ***********************************************************************************************************************************************************************************
ok: [localhost] => {
    "msg": "Status do Liberty: \nServer minhaAplicacaoCertificada is not running."
}

PLAY RECAP *************************************************************************************************************************************************************************************
localhost                  : ok=5    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=1   





Vamos criar um script para verificar logs e erros

#!/bin/bash
SERVER_NAME=$1
LIBERTY_PATH="/home/liberty-base00/wlp"
LOG_PATH="$LIBERTY_PATH/usr/servers/$SERVER_NAME/logs/messages.log"

if [ -z "$SERVER_NAME" ]; then
  echo "Uso: $0 nome_servidor"
  exit 1
fi

# Check se servidor roda
$LIBERTY_PATH/bin/server status $SERVER_NAME || echo "Servidor $SERVER_NAME não rodando."

# Grep erros comuns em logs
grep -E "CWPKI0033E|CWWKG0014E|CWWKS9582E" $LOG_PATH && echo "Erros encontrados: Verifique keystore/senha ou XML." || echo "Nenhum erro comum em logs."

# Tail logs para monitoramento
tail -f $LOG_PATH

chmod +x arquivo.sh

./arquivo.sh


nano check_ports.sh
#!/bin/bash
PORT=$1
SERVER_NAME=$2
LIBERTY_PATH="/home/liberty-base00/wlp"

if [ -z "$PORT" ] || [ -z "$SERVER_NAME" ]; then
  echo "Uso: $0 porta nome_servidor"
  exit 1
fi

# Check porta escutando
netstat -an | grep $PORT && echo "Porta $PORT escutando." || echo "Porta $PORT não escutando - verifique firewall ou config."

# Check certificado
KEYSTORE="$LIBERTY_PATH/usr/servers/$SERVER_NAME/resources/security/key.p12"
keytool -list -v -keystore $KEYSTORE -storepass senhaSegura | grep -E "Valid from|until" || echo "Keystore inválido ou senha errada."

# Teste conexão SSL
openssl s_client -connect localhost:$PORT -showcerts

resultado
./liberty_check_ports.sh 9443 minhaAplicacaoCertificada
Porta 9443 não escutando - verifique firewall ou config.
Valid from: Tue Aug 12 12:58:04 UTC 2025 until: Wed Aug 12 12:58:04 UTC 2026
40679E3AA4750000:error:8000006F:system library:BIO_connect:Connection refused:../crypto/bio/bio_sock2.c:114:calling connect()
40679E3AA4750000:error:10000067:BIO routines:BIO_connect:connect error:../crypto/bio/bio_sock2.c:116:
connect:errno=111
liberty-base00@liberty-base00:~$ ./liberty_check_ports.sh 9447 minhaAplicacaoCertificada
tcp6       0      0 :::9447                 :::*                    LISTEN     
Porta 9447 escutando.
Valid from: Tue Aug 12 12:58:04 UTC 2025 until: Wed Aug 12 12:58:04 UTC 2026
CONNECTED(00000003)
Can't use SSL_get_servername
depth=0 C = BR, O = example, OU = appCertServer, CN = localhost
verify error:num=18:self-signed certificate
verify return:1
depth=0 C = BR, O = example, OU = appCertServer, CN = localhost
verify return:1
---
Certificate chain
 0 s:C = BR, O = example, OU = appCertServer, CN = localhost
   i:C = BR, O = example, OU = appCertServer, CN = localhost
   a:PKEY: rsaEncryption, 2048 (bit); sigalg: RSA-SHA256
   v:NotBefore: Aug 12 12:58:04 2025 GMT; NotAfter: Aug 12 12:58:04 2026 GMT
-----BEGIN CERTIFICATE-----
MIIDXDCCAkSgAwIBAgIEeWPlSDANBgkqhkiG9w0BAQsFADBLMQswCQYDVQQGEwJC
UjEQMA4GA1UEChMHZXhhbXBsZTEWMBQGA1UECxMNYXBwQ2VydFNlcnZlcjESMBAG
A1UEAxMJbG9jYWxob3N0MB4XDTI1MDgxMjEyNTgwNFoXDTI2MDgxMjEyNTgwNFow
SzELMAkGA1UEBhMCQlIxEDAOBgNVBAoTB2V4YW1wbGUxFjAUBgNVBAsTDWFwcENl
cnRTZXJ2ZXIxEjAQBgNVBAMTCWxvY2FsaG9zdDCCASIwDQYJKoZIhvcNAQEBBQA


Teste automatizado
#!/bin/bash
SERVER_NAME=$1
PORT=9447
LIBERTY_PATH="/home/liberty-base00/wlp"

echo "Testando $SERVER_NAME na porta $PORT..."

# Status servidor
$LIBERTY_PATH/bin/server status $SERVER_NAME

# Check logs
grep "ERROR" $LIBERTY_PATH/usr/servers/$SERVER_NAME/logs/messages.log

# Check porta
netstat -an | grep $PORT

# Check cert expiração
openssl s_client -connect localhost:$PORT -showcerts | grep -A5 "Certificate chain"




Ansible
criando um playbook de teste automatizado
- name: Troubleshooting Liberty
  hosts: all
  tasks:
    - name: Check Logs for Errors
      command: grep "ERROR" /home/liberty-base00/wlp/usr/servers/minhaAplicacaoCertificada/logs/messages.log
      register: log_errors
      ignore_errors: yes

    - debug:
        msg: "Erros encontrados: {{ log_errors.stdout }}"

    - name: Check Port 9447
      command: netstat -an | grep 9447
      register: port_check

    - name: Restart if Port Not Listening
      command: /home/liberty-base00/wlp/bin/server start minhaAplicacaoCertificada --clean
      when: "'LISTEN' not in port_check.stdout"

,


server_name: "{{ server_name | default("meuServidor") }}"
    http_port: "{{  http_port | default('9080')  }}"
    https_port:




ver dynamic routing e replica set
duas coletivas e aplicação embaixo e aplicação respondendo pelo cluster
