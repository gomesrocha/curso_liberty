#  Passo a passo para criar um certificado auto-assinado

### Criando a aplicação
./server create minhaAplicacaoCertificada


### Criando o certificado auto assinado
./securityUtility createSSLCertificate --server=minhaAplicacaoCertificada --password=senhaSegura --validity=365 --subject=CN=localhost,OU=appCertServer,O=example,C=BR

### Fazendo o encode da senha
./securityUtility encode senhaSegura

### Configurando a aplicação
nano ../usr/servers/minhaAplicacaoCertificada/server.xml 

 ```xml

    <?xml version="1.0" encoding="UTF-8"?>
    <server description="new server">

        <featureManager>
            <feature>jakartaee-10.0</feature>
            <feature>adminCenter-1.0</feature>
            <feature>restConnector-2.0</feature>
            <feature>ssl-1.0</feature>
        </featureManager>

        <basicRegistry id="basic" realm="BasicRealm">
            <user name="admin" password="senhaSegura"/>
        </basicRegistry>
        <administrator-role>
            <user>admin</user>
        </administrator-role>

  
        <httpEndpoint id="defaultHttpEndpoint" host="*" httpPort="9086" httpsPort="9447"/>

       
        <ssl id="defaultSSLConfig" keyStoreRef="defaultKeyStore" trustStoreRef="defaultTrustStore"/>

        <keyStore id="defaultKeyStore" location="resources/security/key.p12" password="{xor}LDoxNz4MOjgqLT4=" />
        <keyStore id="defaultTrustStore" location="resources/security/key.p12" password="{xor}LDoxNz4MOjgqLT4=" />
        
        <applicationMonitor updateTrigger="mbean"/>
        <applicationManager autoExpand="true"/>
    </server>
```

### Inicia aplicação
./server start minhaAplicacaoCertificada
Verifica se a porta foi aberta
netstat -an |grep 9447

Verifica o certificados
openssl s_client -connect localhost:9447 -showcerts
Pare a aplicação
./server stop minhaAplicacaoCertificada
