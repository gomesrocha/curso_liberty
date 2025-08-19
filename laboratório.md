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

# Ansible

Ansible é uma ferramenta poderosa para automação de tarefas em servidores, como configuração, deployment e gerenciamento. Ele é tipicamente instalado em uma máquina de controle (control node), que pode ser o seu computador local ou outro servidor, para gerenciar tarefas remotamente via SSH em outros servidores (managed nodes). Os managed nodes não precisam do Ansible instalado, apenas Python e acesso SSH.

## Preparando o ambiente

- pré-requisito: python 3

Instalação:

```
sudo apt install ansible

ou

python3 -m pip install --user ansible

ansible --version
``` 

Crieo arquivo host (pode ser outro nome) que vai conter as máquinas, neste caso apenas uma, que vamos automatizar com o seguinte conteúdo:

[local]
localhost ansible_connection=local

Para testar o ansible, faça:

ansible -i host all -m ping


Agora vamos criar o playbook de verificação do servidor, neste caso, o servidor chama-se minhaAplicacaoCertificada, caso seja outro nome, basta substituir:

 


Arquivo verifica_servidor.yml
```xml

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

```

Para executar o playbook, faça:
ansible-playbook -i host verifica_servidor.yml



Agora vamos criar um playbook para fazer teste no nosso servidor.

Crie um arquivo novo playbook_teste_liberty.yml 
```xml
- name: Teste do  Liberty
  hosts: all
  vars:
    liberty_log_path: "/home/liberty-base00/wlp/usr/servers/minhaAplicacaoCertificada/logs/messages.log"  # Variável para fácil mudança

  tasks:
    - name: Verificar erros de log
      command: grep "ERROR" {{ liberty_log_path }}
      register: log_errors
      failed_when: log_errors.rc > 1  # Ignora rc=1 (nenhum erro), falha só se erro real
      changed_when: false  # Não marca como changed

    - name: Debug Erros Encontrados
      debug:
        msg: "Erros encontrados: {{ log_errors.stdout | default('Nenhum erro encontrado') }}"  # Corrigido: fechamento de aspas e filtro

    - name: Monitorar Logs se Erros Encontrados
      command: tail -f {{ liberty_log_path }}
      when: log_errors.rc == 0  # Só se encontrou erros (rc=0 para grep com match)
      async: 60  # Roda assincrono por 60s para monitoramento
      poll: 0    # Não espera fim (útil para tail)

    - name: Verificar porta 9447
      command: netstat -an | grep 9447
      register: port_check
      changed_when: false

    - name: Reiniciar se porta não estiver sendo listada
      command: /home/liberty-base00/wlp/bin/server start minhaAplicacaoCertificada --clean
      when: "'LISTEN' not in port_check.stdout"


```
E execute
ansible-playbook -i hosts playbook_teste_liberty.yml 