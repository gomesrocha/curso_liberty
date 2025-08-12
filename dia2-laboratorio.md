# Laboratório 1: Configuração de Certificado Auto-Assinado e Deploy de Aplicação "aplicacaoTeste" na Porta 9453 no Open Liberty

Este laboratório configura um servidor Open Liberty com certificado SSL auto-assinado, cria uma aplicação simples chamada "aplicacaoTeste" (um servlet Jakarta EE), e a expõe na porta HTTPS 9453. Usamos uma configuração local, assumindo o Liberty instalado em `/home/liberty-base00/wlp` e Java 11+. O certificado é válido por 365 dias a partir de 12 de agosto de 2025.

## Pré-requisitos
- Open Liberty instalado (baixe em openliberty.io se necessário).
- Java 11+ (ex: OpenJDK).
- Instale features: `./featureUtility installFeature jakartaee-10.0 ssl-1.0 --acceptLicense`.
- Maven para build da app (instale com `sudo apt install maven` se necessário).

## Passo 1: Criar o Servidor
Crie um servidor dedicado:
```
./server create aplicacaoTesteServer
```

## Passo 2: Configurar o `server.xml` para Porta 9453 e SSL
Edite o arquivo em `/home/liberty-base00/wlp/usr/servers/aplicacaoTesteServer/server.xml`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<server description="Servidor para aplicacaoTeste">
    <featureManager>
        <feature>jakartaee-10.0</feature>
        <feature>ssl-1.0</feature>
    </featureManager>

    <!-- Endpoint com HTTPS na porta 9453 -->
    <httpEndpoint id="defaultHttpEndpoint" host="*" httpPort="9080" httpsPort="9453"/>

    <!-- Configuracao SSL -->
    <ssl id="defaultSSLConfig" keyStoreRef="defaultKeyStore" trustStoreRef="defaultTrustStore"/>

    <!-- Keystore e Truststore -->
    <keyStore id="defaultKeyStore" location="resources/security/key.p12" password="{xor}LDoxNz4MOjgqLT4=" />
    <keyStore id="defaultTrustStore" location="resources/security/key.p12" password="{xor}LDoxNz4MOjgqLT4=" />

    <applicationMonitor updateTrigger="mbean"/>
    <applicationManager autoExpand="true"/>
</server>
```
- Codifique a senha "senhaSegura" com `./securityUtility encode senhaSegura` e substitua o password.

## Passo 3: Gerar o Certificado Auto-Assinado
Gere o keystore com certificado:
```
./securityUtility createSSLCertificate --server=aplicacaoTesteServer --password=senhaSegura --validity=365 --subject=CN=localhost,OU=aplicacaoTesteServer,O=example,C=BR
```
- Isso cria `key.p12` em `resources/security/`.

## Passo 4: Inicialização e Teste
- Inicie: `./server start aplicacaoTesteServer --clean`.
- Verifique logs: `less ../usr/servers/aplicacaoTesteServer/logs/messages.log` (procure sucesso em SSL).
- Teste porta: `netstat -an | grep 9453`.
- Teste certificado: `openssl s_client -connect localhost:9453 -showcerts`.


# Laboratório 2: Configuração de Cluster Simples com "meuControlador", "meuMembro1" e "meuMembro2" no Open Liberty

Este laboratório configura um cluster tradicional no Open Liberty usando um controlador ("meuControlador") e dois membros ("meuMembro1", "meuMembro2"). Usamos features de collective para gerenciamento centralizado. Assumimos o Liberty em `/home/liberty-base00/wlp`.

## Pré-requisitos
- Instale features: `./featureUtility installFeature collectiveController-1.0 collectiveMember-1.0 ssl-1.0 --acceptLicense`.
- Senha "senhaSegura".

## Passo 1: Criar e Configurar o Controlador "meuControlador"
- Crie: `./server create meuControlador`.
- Gere collective: `./collective create meuControlador --keystorePassword=senhaSegura --createConfigFile=../usr/servers/meuControlador/collective-include.xml --hostName=localhost`.
- Atualize `server.xml` em `../usr/servers/meuControlador/server.xml`:
  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
    <server description="new server">

        <!-- Enable features -->
        <featureManager>
            <feature>collectiveController-1.0</feature>
        </featureManager>

        <!-- To access this server from a remote client add a host attribute to the following element, e.g. host="*" -->
        <httpEndpoint id="defaultHttpEndpoint"
                    httpPort="20080"
                    httpsPort="20443" />

        <!-- Automatically expand WAR files and EAR files -->
        <applicationManager autoExpand="true"/>

        <!-- Default SSL configuration enables trust for default certificates from the Java runtime --> 
        <ssl id="defaultSSLConfig" trustDefaultCerts="true" />
    </server>

  ```
- Inicie: `./server start meuControlador --clean`.

## Passo 2: Criar e Adicionar Membro "meuMembro1"
- Crie: `./server create meuMembro1`.
- Join: `./collective join meuMembro1 --host=localhost --port=9443 --user=admin --password=senhaSegura --keystorePassword=senhaSegura --autoAcceptCertificates`.
- Atualize `server.xml` em `../usr/servers/meuMembro1/server.xml` (use sugestões do join, ajuste portas para 9081/9444):
  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
    <server description="new server">

        <!-- Enable features -->
        <featureManager>
            <feature>jsp-2.3</feature>
        </featureManager>

        <!-- To access this server from a remote client add a host attribute to the following element, e.g. host="*" -->
        <httpEndpoint id="defaultHttpEndpoint"
                    httpPort="9080"
                    httpsPort="9443" />

        <!-- Automatically expand WAR files and EAR files -->
        <applicationManager autoExpand="true"/>

        <!-- Default SSL configuration enables trust for default certificates from the Java runtime --> 
        <ssl id="defaultSSLConfig" trustDefaultCerts="true" />
    </server>

  ```
- Inicie: `./server start meuMembro1 --clean`.

## Passo 3: Criar e Adicionar Membro "meuMembro2"
- Repita o Passo 2 para "meuMembro2", ajustando portas para 9082/9445 no `server.xml`.
- Join: `./collective join meuMembro2 --host=localhost --port=9443 --user=admin --password=senhaSegura --keystorePassword=senhaSegura --autoAcceptCertificates`.

