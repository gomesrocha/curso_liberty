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

```
[local]
localhost ansible_connection=local
```

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

Verificando e renovando certificado com o Ansible

Crie um arquivo verificar_renovar_certificado.yml com o seguinte conteúdo

``` 
- name: Verificar e Renovar Certificado no Open Liberty
  hosts: all
  vars:
    liberty_path: "/home/liberty-base00/wlp"
    server_name: "{{ server_name | default('minhaAplicacaoCertificada') }}"  # Nome do servidor
    keystore_password: "{{ keystore_password | default('senhaSegura') }}"    # Senha do keystore
    keystore_file: "{{ liberty_path }}/usr/servers/{{ server_name }}/resources/security/key.p12"  # Caminho do keystore
    days_to_expire: 1

  tasks:
    - name: Verificar se Keystore Existe
      stat:
        path: "{{ keystore_file }}"
      register: keystore_stat
      failed_when: not keystore_stat.stat.exists  # Falha se keystore ausente

    - name: Extrair Data de Expiração do Certificado
      command: keytool -list -v -keystore {{ keystore_file }} -storepass {{ keystore_password }}
      register: keytool_output
      changed_when: false

    - name: Parsear Data de Expiração (String Completa)
      set_fact:
        expiration_str: "{{ keytool_output.stdout | regex_search('until: (.*)', '\\1') | first | trim }}"
      when: "'until:' in keytool_output.stdout"

    - name: Converter Data de Expiração para Timestamp Unix
      command: date -d "{{ expiration_str }}" +%s
      register: expiration_timestamp
      changed_when: false
      when: expiration_str is defined

    - name: Obter Timestamp Atual + {{ days_to_expire }} Dia
      command: date -d "+{{ days_to_expire }} days" +%s
      register: current_timestamp_plus_one
      changed_when: false

    - name: Verificar se Certificado Expirou ou Expira em Breve
      set_fact:
        needs_renewal: true
      when: expiration_timestamp.stdout | int <= current_timestamp_plus_one.stdout | int

    - name: Debug Status do Certificado
      debug:
        msg: "Certificado expira em {{ expiration_str | default('Data não encontrada') }}. Renovação necessária: {{ needs_renewal | default(false) }}"

    - name: Backup do keystore
      copy:
        src: "{{ keystore_file }}"
        dest: "{{ keystore_file }}.old"
      when: needs_renewal | default(false)

    - name: Remover keystore expirada
      file:
        path: "{{ keystore_file }}"
        state: absent
      when: needs_renewal | default(false)

    - name: Renovar Certificado se Necessário
      command: "{{ liberty_path }}/bin/securityUtility createSSLCertificate --server={{ server_name }} --password={{ keystore_password }} --validity=365 --subject=CN=localhost,OU={{ server_name }},O=example,C=BR"
      when: needs_renewal | default(false)

    - name: Parar Servidor Após Renovação
      command: "{{ liberty_path }}/bin/server stop {{ server_name }}"
      when: needs_renewal | default(false)
      ignore_errors: yes

    - name: Iniciar Servidor Após Renovação
      command: "{{ liberty_path }}/bin/server start {{ server_name }} --clean"
      when: needs_renewal | default(false)
      ignore_errors: yes

    - name: Verificar Status Final do Servidor
      command: "{{ liberty_path }}/bin/server status {{ server_name }}"
      register: server_status
      ignore_errors: yes

    - name: Debug Status Final
      debug:
        msg: "Status do Servidor: {{ server_status.stdout | default('Servidor não iniciado') }}"


```

Depois basta executar

ansible-playbook -i host verificar_renovar_certificado.yml -e "server_name=minhaAplicacaoCertificada" -e "keystore_password=senhaSegura"

Onde minhaAplicacaoCertificada é o nome da aplicação que quero validar o certificado e;
senhaSegura é a senha do keystore
