# Guia para Configurar Certificado SSL no Open Liberty

Este guia explica como configurar um certificado SSL no Liberty usando o `server.xml` fornecido. O foco é em um ambiente de laboratório local, usando um certificado auto-assinado gerado pela ferramenta `securityUtility`. 

A configuração inicial usa um certificado auto-assinado, que é simples para testes, mas não recomendado para produção (use CA-signados como Let's Encrypt para evitar warnings em browsers). Ao final, explico como trocar para outro certificado auto-assinado (renovação ou regeneração).

## Pré-requisitos
- Open Liberty instalado em `/home/liberty-base00/wlp`.
- Java 11+ (confirmado nos logs).
- Features instaladas: `jakartaee-10.0`, `adminCenter-1.0`, `restConnector-2.0`, `ssl-1.0` (instale com `./featureUtility installFeature ... --acceptLicense` se necessário).
- Senha "senhaSegura" (codificada como `{xor}LDoxNz4MOjgqLT4=` via `securityUtility encode`).

## Passo 1: Criar o Servidor
Execute o comando para criar o servidor:
```
./server create minhaAplicacaoCertificada
```
- Isso cria o diretório do servidor em `../usr/servers/minhaAplicacaoCertificada`, com um `server.xml` padrão.

## Passo 2: Editar o `server.xml`
Abra o arquivo com:
```
nano ../usr/servers/minhaAplicacaoCertificada/server.xml
```
Use o conteúdo corrigido abaixo (baseado no seu XML, com tags fechadas corretamente, atributos completos e senha codificada para segurança). O erro nos logs (`CWWKG0014E`) foi causado por um '<' inválido no atributo `trustStoreRef` e tags truncadas – corrigimos isso fechando as tags e removendo caracteres proibidos.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<server description="new server">
    <!-- Enable features -->
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

    <!-- To access this server from a remote client add a host attribute to the following element, e.g. host="*" -->
    <httpEndpoint id="defaultHttpEndpoint" host="*" httpPort="9086" httpsPort="9447"/>

    <!-- Configuracao SSL -->
    <ssl id="defaultSSLConfig" keyStoreRef="defaultKeyStore" trustStoreRef="defaultTrustStore"/>

    <!-- Keystores -->
    <keyStore id="defaultKeyStore" location="resources/security/key.p12" password="{xor}LDoxNz4MOjgqLT4=" />
    <keyStore id="defaultTrustStore" location="resources/security/key.p12" password="{xor}LDoxNz4MOjgqLT4=" />

    <applicationMonitor updateTrigger="mbean"/>
    <applicationManager autoExpand="true"/>
</server>
```

- **Explicações das Mudanças**:
  - Fechamos a tag `<ssl>` corretamente (adicionando `/` no final).
  - Completamos os atributos `password` nos `<keyStore>`, usando a senha codificada que você gerou (`{xor}LDoxNz4MOjgqLT4=`).
  - Removemos acentos em comentários para evitar problemas de encoding (opcional, mas previne erros).
  - A porta HTTPS é 9447, como especificado.

Salve o arquivo (Ctrl+O, Enter, Ctrl+X).

## Passo 3: Gerar o Certificado Auto-Assinado
Execute o comando para criar o keystore com o certificado:
```
./securityUtility createSSLCertificate --server=minhaAplicacaoCertificada --password=senhaSegura --validity=365 --subject=CN=localhost,OU=appCertServer,O=example,C=BR
```
- Isso gera `key.p12` em `../usr/servers/minhaAplicacaoCertificada/resources/security/`, com validade de 365 dias.
- O comando também sugere adicionar `<feature>transportSecurity-1.0</feature>`, mas usamos `ssl-1.0` (equivalente em versões recentes).

## Passo 4: Codificar a Senha (Já Feito)
Você já executou:
```
./securityUtility encode senhaSegura
```
- Output: `{xor}LDoxNz4MOjgqLT4=`.
- Isso é usado no `server.xml` para proteger a senha em texto puro.

## Passo 5: Iniciar o Servidor e Verificar
Inicie com:
```
./server start minhaAplicacaoCertificada
```
- Verifique logs: `less ../usr/servers/minhaAplicacaoCertificada/logs/messages.log` – Deve mostrar sucesso sem erros de XML ou keystore.
- Verifique porta: `netstat -an | grep 9447` – Deve mostrar `LISTEN` (ex: `tcp6 0 0 :::9447 :::* LISTEN`).
- Teste SSL: `openssl s_client -connect localhost:9447 -showcerts` – Deve exibir detalhes do certificado (subject, validade, etc.).
- Firewall: Se porta não aparecer, libere: `sudo ufw allow 9447/tcp && sudo ufw reload`.

Se tudo funcionar, o certificado está configurado! Acesse endpoints HTTPS como `https://localhost:9447`.

## Trocar para um Novo Certificado Auto-Assinado (Renovação ou Regeneração)
Se o certificado atual expirar ou precisar de atualização (ex: mudar subject ou validade), siga esses passos para trocar por um novo auto-assinado:

1. **Pare o Servidor**:
   ```
   ./server stop minhaAplicacaoCertificada
   ```

2. **Backup do Keystore Antigo**:
   ```
   cp ../usr/servers/minhaAplicacaoCertificada/resources/security/key.p12 ../usr/servers/minhaAplicacaoCertificada/resources/security/key.p12.old
   ```

3. **Gere o Novo Certificado**:
   ```
   ./securityUtility createSSLCertificate --server=minhaAplicacaoCertificada --password=senhaSegura --validity=730 --subject=CN=localhost,OU=appCertServer,O=example,C=BR
   ```
   - `--validity=730`: Aumenta para 2 anos.
   - Isso substitui `key.p12` com o novo.

4. **Atualize o `server.xml` (se Mudou Senha)**:
   - Se a senha mudou, codifique a nova e atualize os `password` nos `<keyStore>`.

5. **Reinicie e Teste**:
   ```
   ./server start minhaAplicacaoCertificada --clean
   ```
   - Verifique logs e testes como no Passo 5.
   - Confirme nova validade com `openssl s_client -connect localhost:9447 -showcerts`.

## Trocando Certificado Auto-Assinado por Let's Encrypt

Olá! Baseado na configuração anterior (servidor `minhaAplicacaoCertificada` com self-signed certificate via `securityUtility`), vamos explicar como substituir por um certificado do Let's Encrypt (CA gratuita que emite certificados válidos por 90 dias, renováveis automaticamente). O Open Liberty suporta isso nativamente via feature `acmeCA-2.0`, que usa o protocolo ACME para obter e renovar certificados automaticamente.

Isso elimina warnings de "self-signed" em browsers e melhora segurança. Requer um domínio público (ex: seu-dominio.com) para verificação (DNS ou HTTP challenge). Para labs locais sem domínio, use self-signed; para produção/homelab, configure DNS.

**Pré-requisitos**:
- Domínio público apontando para seu servidor (ex: A record no DNS para IP público).
- Porta 80 aberta para verificação HTTP (Let's Encrypt usa challenge ACME).
- Certbot instalado (opcional, mas útil para inicial): `sudo apt install certbot`.
- Servidor parado durante config inicial.

## Passo 1: Pare o Servidor e Backup
Pare para editar:
```
./server stop minhaAplicacaoCertificada
```
Backup keystore antigo:
```
cp ../usr/servers/minhaAplicacaoCertificada/resources/security/key.p12 ../usr/servers/minhaAplicacaoCertificada/resources/security/key.p12.selfsigned
```

## Passo 2: Instale a Feature ACME
Adicione suporte ACME:
```
./featureUtility installFeature acmeCA-2.0 --acceptLicense
```
Verifique:
```
./featureUtility find acmeCA-2.0
```

## Passo 3: Atualize o `server.xml` para Let's Encrypt
Edite (`nano ../usr/servers/minhaAplicacaoCertificada/server.xml`) e adicione `<acmeCA>` para ACME. Remova ou comente os keystores self-signed, pois ACME gerencia automaticamente.

XML atualizado (mantenha features e endpoint; adicione ACME config):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<server description="new server">
    <!-- Enable features -->
    <featureManager>
        <feature>jakartaee-10.0</feature>
        <feature>adminCenter-1.0</feature>
        <feature>restConnector-2.0</feature>
        <feature>ssl-1.0</feature>
        <feature>acmeCA-2.0</feature> <!-- Novo: Suporte ACME para Let's Encrypt -->
    </featureManager>

    <basicRegistry id="basic" realm="BasicRealm">
        <user name="admin" password="senhaSegura"/>
    </basicRegistry>
    <administrator-role>
        <user>admin</user>
    </administrator-role>

    <!-- Endpoint com HTTPS -->
    <httpEndpoint id="defaultHttpEndpoint" host="*" httpPort="9086" httpsPort="9447"/>

    <!-- SSL config que usara ACME -->
    <ssl id="defaultSSLConfig" keyStoreRef="defaultKeyStore" trustStoreRef="defaultTrustStore"/>

    <!-- ACME config para Let's Encrypt -->
    <acmeCA directoryURI="https://acme-v02.api.letsencrypt.org/directory"
            domain="seu-dominio.com"
            contact="mailto:seu@email.com"
            accountKeyFile="resources/security/acmeAccountKey.p12"
            domainKeyFile="resources/security/acmeDomainKey.p12"
            acceptTermsOfService="true" />

    <applicationMonitor updateTrigger="mbean"/>
    <applicationManager autoExpand="true"/>
</server>
```

- **Explicações**:
  - `<acmeCA>`: Configura Let's Encrypt (directoryURI oficial). Substitua `seu-dominio.com` e email. `acceptTermsOfService="true"` aceita termos.
  - Keystores: ACME gera/atualiza `key.p12` automaticamente; remova refs a self-signed.
  - Salve.

## Passo 4: Verificação e Inicialização
- Abra porta 80 para challenge: `sudo ufw allow 80/tcp && sudo ufw reload`.
- Inicie:
  ```
  ./server start minhaAplicacaoCertificada --clean
  ```
- Liberty solicita certificado ao Let's Encrypt via ACME. Verifique logs: `cat ../usr/servers/minhaAplicacaoCertificada/logs/messages.log` – Procure sucesso em ACME (ex: certificado obtido).
- Teste: `openssl s_client -connect seu-dominio.com:9447 -showcerts` (mostra cert Let's Encrypt, válido por 90 dias).

## Renovação Automática
- ACME renova automaticamente a cada 60-90 dias (verifica diariamente). Monitore logs para confirmações.
- Se manual: Pare servidor, rode Certbot (`sudo certbot renew`), importe para `key.p12` via openssl (como em guias anteriores), atualize server.xml e reinicie.
