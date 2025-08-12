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

# Guia para configurar o Cluster no Liberty
# Configuração de Cluster no Open Liberty

Este guia aborda a configuração de clusters no Open Liberty, focando em conceitos teóricos, arquitetura, importância, cálculo de nós, itens de atenção, configuração tradicional e em Kubernetes, best practices, desafios comuns e conclusão. O conteúdo é baseado no texto fornecido, organizado de forma lógica para facilitar a compreensão. O Open Liberty é um servidor de aplicações Java leve e modular, ideal para ambientes web e de microsserviços, com suporte nativo a clustering para alta disponibilidade (HA) e escalabilidade.

## Contexto: Web Server em Liberty

O Open Liberty não é apenas um web server, mas um servidor de aplicações Java completo, compatível com Jakarta EE e MicroProfile. Ele hospeda:

* Servlets, JSP, APIs REST.
* Aplicações monolíticas e microsserviços.
* Integração nativa com HTTP/HTTPS.

Diferença para um Apache HTTP Server:  
Enquanto o Apache atua como camada de entrega (estático/dinâmica via módulos), o Liberty processa e executa aplicações empresariais Java, eliminando a necessidade de um application server adicional.

Pontos fortes:
* Inicialização muito rápida (segundos).
* Baixo consumo de memória/CPU.
* Modularidade (features ativadas sob demanda via `server.xml`).
* Fácil integração com ambientes on-premise ou cloud.

## O que é Clustering em Liberty?

Clustering em Liberty refere-se ao agrupamento de múltiplos servidores Liberty, chamados de nós, que operam como uma unidade lógica unificada. Isso permite compartilhar carga de trabalho, recursos e estados entre os nós. Existem dois tipos principais: o clustering tradicional via "coletivo", que inclui um controller central e members distribuídos, e o clustering baseado em Kubernetes, utilizando o Open Liberty Operator para orquestração automatizada.

Os componentes chave incluem o controller (responsável pela gerenciamento centralizado do cluster), os members (nós que executam as aplicações) e um load balancer (para distribuir o tráfego de entrada). Em cenários avançados, sessões HTTP podem ser replicadas usando mecanismos como JCache ou Infinispan para manter a persistência distribuída.

O clustering é fundamental para alcançar alta disponibilidade e escalabilidade horizontal, permitindo que o sistema cresça conforme a demanda sem interrupções.

No modo tradicional, clustering no Liberty é feito com Collectives:
* Controller → Servidor central que gerencia configuração e monitora o cluster.
* Members → Nós que rodam as aplicações e se reportam ao controller.
* Load Balancer → Distribui requisições entre os members (Apache, NGINX, IHS).

Benefícios:
* Alta disponibilidade (HA).
* Escalabilidade horizontal.
* Gerenciamento centralizado.
* Replicação de sessão (para aplicações stateful).

Quando usar sem Kubernetes:
* Ambientes on-premise ou VM-based.
* Quando não há orquestrador cloud-native.
* Cenários legados que precisam HA mas não querem migrar toda a infraestrutura.

## Arquitetura de um Cluster Liberty

Na arquitetura tradicional de um cluster Liberty, há um controller central que coordena os members através da feature `collectiveController-1.0` e `collectiveMember-1.0`. Os members se conectam ao controller para sincronização e gerenciamento. Em ambientes Kubernetes, o Open Liberty Operator gerencia deployments, services e escalabilidade automática via Custom Resources como OpenLibertyApplication.

Um exemplo prático envolve a replicação de sessões HTTP usando JCache para cache distribuído ou Infinispan como provedor externo, garantindo que estados de usuário sejam mantidos mesmo em falhas. A arquitetura integra-se com ferramentas como Hazelcast para gerenciamento de dados distribuídos ou bancos de dados para aplicações stateful.

Essa estrutura promove resiliência e eficiência, especialmente em setups híbridos onde partes do cluster rodam on-premise e outras na cloud.

Controller usa a feature `collectiveController-1.0`.
* Members usam `collectiveMember-1.0` e `clusterMember-1.0`.
- Comunicação segura via SSL/TLS (`ssl-1.0`).
* Sessões replicadas com `sessionCache-1.0` + provedor (JCache, Infinispan, Hazelcast).
- LB geralmente ativo-ativo para evitar ponto único de falha.

## Por que Clustering é Importante?

### Parte 1
O clustering é essencial para garantir alta disponibilidade (HA), proporcionando redundância contra falhas de hardware ou software. Se um nó falhar, os outros assumem a carga automaticamente, minimizando ou eliminando downtime. Além disso, ele permite escalabilidade horizontal, adicionando nós dinamicamente para lidar com picos de tráfego, como em eventos sazonais.

O balanceamento de carga distribui requisições de forma uniforme entre os nós, otimizando a performance geral do sistema e evitando sobrecarga em servidores individuais. Isso é particularmente importante para aplicações mission-critical, como plataformas de e-commerce, sistemas bancários ou serviços de saúde, onde interrupções podem resultar em perdas financeiras ou riscos operacionais.

Sem clustering, sistemas monolíticos tornam-se pontos únicos de falha, limitando a capacidade de crescimento.

Alta Disponibilidade:
* Failover automático: se um member falhar, outro assume a carga.
* Minimiza downtime (atende SLAs altos como 99.9% ou 99.99%).

Escalabilidade:
* Adição/remoção de nós conforme demanda.
* Melhor uso de recursos físicos.

Exemplo real:
* E-commerce em datas de pico (Black Friday) escala para 6 nós; no restante do ano, opera com 3.

### Parte 2
Além da HA, o clustering oferece resiliência através de mecanismos de failover automático e recuperação de sessões de usuário, preservando o estado das interações mesmo em falhas. Ele melhora a eficiência de recursos em ambientes cloud, permitindo alocação dinâmica e redução de custos com ociosidade.

Em termos de conformidade, o clustering ajuda a atender SLAs de uptime elevados, como 99.99%, e regulamentos como GDPR, ao distribuir dados de forma segura e redundante. Para organizações, isso significa maior confiabilidade e capacidade de lidar com demandas imprevisíveis, evitando perdas de receita ou reputação.

Em cenários sem cluster, falhas isoladas podem paralisar todo o sistema, destacando a importância estratégica dessa abordagem.

## Como Calcular a Quantidade de Nós no Cluster?

### Princípios Gerais
Para calcular o número de nós em um cluster, use a fórmula básica: Número de Nós = (Carga Esperada / Capacidade por Nó) + Fator de Redundância. A carga esperada é medida em requisições por segundo (RPS) ou usuários simultâneos, obtida através de ferramentas de teste como JMeter ou Locust.

A capacidade por nó é determinada por testes de stress em um servidor isolado, por exemplo, avaliando quantos RPS um nó com 4 vCPUs e 8GB de RAM pode suportar sem degradar performance. Recomenda-se começar com pelo menos 3 nós para garantir HA básica, formando um quorum para decisões distribuídas no cluster.

Esse cálculo inicial deve ser iterativo, ajustado com base em dados reais de produção.

Fórmula básica:  
Nós = (RPS esperado / RPS por nó) + redundância  
* RPS esperado: Obtido com testes (JMeter, Locust).  
- RPS por nó: Medido em ambiente de homologação.  
* Redundância: Mínimo N+1 (um nó extra).  

Dica:  
* Sempre usar pelo menos 3 nós para quorum e HA.  
* Ajustar após monitoramento real (Prometheus ou JVisualVM).

### Fatores Avançados
Fatores avançados incluem redundância, como N+1 para proteção básica ou N+2 para HA elevada, visando uptimes de 99.99%. Considere latência de rede, overhead de replicação (tipicamente 20% extra para caching de sessões) e mecanismos de auto-scaling em Kubernetes, ativados quando CPU excede 70%.

Ferramentas como Prometheus e Grafana ajudam no monitoramento, permitindo calcular Nós = (Pico de RPS / RPS por Nó) * Fator de Segurança (geralmente 1.5 a 2 para margens de erro). Realize load testing repetido para refinar o modelo, evitando subdimensionamento que pode levar a throttling ou sobrecargas.

Esses fatores garantem que o cluster seja robusto e econômico.

## Itens de Atenção no Clustering

### Parte 1: Segurança e Rede
Na segurança, ative a feature `ssl-1.0` para criptografia de comunicações e configure firewalls para proteger portas sensíveis como 9080 (HTTP) e 9443 (HTTPS). Harden a rede restringindo acessos e usando certificados válidos para evitar vulnerabilidades.

Para a rede, garanta latência baixa (menos de 50ms entre nós) e use multicast para descoberta automática em clusters tradicionais. Evite single points of failure, como load balancers não redundantes, configurando setups ativos-ativos.

Esses itens previnem ataques como DDoS e garantem comunicação estável; consulte a documentação da IBM para guidelines de hardening.

Segurança:
* Habilitar `ssl-1.0` para criptografia.
* Usar certificados válidos e renovar antes do vencimento.
* Restringir portas (9080 HTTP, 9443 HTTPS) no firewall.

Rede:
* Latência entre nós < 50ms.
* Evitar single SPoF no load balancer (usar dois LB em ativo-ativo).

### Parte 2: Performance e Manutenção
Para performance, monitore e ajuste o heap size (definindo min=max para estabilidade) e pools de conexões (máximo de 50-100 para evitar esgotamento). Na manutenção, aplique atualizações em modo rolling, atualizando um nó por vez para zero downtime, e teste failover periodicamente.

Atenção especial ao gerenciamento de estados: prefira apps stateless para simplicidade, mas para stateful, minimize overhead de replicação que pode aumentar latência. Em Kubernetes, configure probes de liveness e readiness para detecção precoce de problemas.

Essas práticas mantêm o cluster otimizado e resiliente a longo prazo.

Performance:
* Ajustar heap (-Xms = -Xmx).
* Pool de conexões de BD ajustado ao tamanho do cluster.
* Evitar replicação excessiva de sessão (impacta latência).

## Configuração de Cluster Tradicional

### Pré-requisitos
Antes de configurar, instale o Liberty baixando o JAR de instalação e executando `java -jar wlp-install.jar --acceptLicense`. Habilite features necessárias como `collectiveController-1.0`, `collectiveMember-1.0`, `clusterMember-1.0` e `cluster-1.0` via `server.xml`.

O ambiente requer Java 8 ou superior, sistemas operacionais suportados como Linux ou Windows, e diretórios padronizados como `/opt/ibm/wlp`. Crie um usuário administrativo (ex.: wasadmin) com permissões adequadas para gerenciamento.

Esses pré-requisitos garantem uma base sólida para o setup do cluster.

* Java 8+.
* Liberty instalado (`java -jar wlp-install.jar --acceptLicense`).
* Usuário admin (wasadmin).

### Passos Iniciais
Comece criando o controller: execute `./server create wlpCntlr` seguido de `./collective create wlpCntlr --keystorePassword=senha`. Edite o `server.xml` para incluir `<include location="wlpcntlr_include.xml"/>` e configure `<httpEndpoint host="*"/>` para acessibilidade.

Inicie o controller com `./server start wlpCntlr`. Gere chaves SSL para comunicações seguras entre nós.

Esses passos iniciais estabelecem o hub central do cluster.

Criar Controller:  
`./server create wlpController`  
`./collective create wlpController –keystorePassword=senha`  
Adicionar ao `server.xml`:  
`<feature>collectiveController-1.0</feature>`  
`<feature>ssl-1.0</feature>`  
Iniciar:  
`./server start wlpController`

### Adicionando Members
Para cada member, crie o servidor com `./server create wlpMember` e junte ao cluster via `./collective join wlpMember --host=IP_CONTROLLER --port=9443 --user=admin --password=senha --keystorePassword=senha`. Adicione a feature `<feature>clusterMember-1.0</feature>` no `server.xml` do member.

Inicie com `./server start wlpMember` e verifique o status através do Admin Center na porta 9443.

Isso integra os nós ao coletivo de forma segura.

Criar Member:  
`./server create wlpMember1`  
`./collective join wlpMember1 --host=IP_CONTROLLER --port=9443 --user=wasadmin --password=senha –keystorePassword=senha`  
Adicionar ao `server.xml`:  
`<feature>collectiveMember-1.0</feature>`  
`<feature>clusterMember-1.0</feature>`  
Iniciar:  
`./server start wlpMember1`

### Sessões e HA
Ative o caching de sessões com a feature `sessionCache-1.0` e configure provedores como Infinispan para replicação distribuída. Integre um load balancer como Apache ou NGINX para distribuição de tráfego.

Teste deployando uma aplicação sample, acessando via balancer e simulando falha em um nó para validar failover. Para apps stateful, use bancos de dados externos para persistência.

Essa configuração assegura HA e continuidade de sessões.

* Habilitar `sessionCache-1.0`.
* Configurar provedor:  
`<httpSessionCache cacheProviderRef="infinispanProvider"/>`

## Configuração de Cluster em Kubernetes

### Com Open Liberty Operator
Instale o Operator via OperatorHub no OpenShift ou `kubectl apply -f operator.yaml`. Crie um Custom Resource YAML para OpenLibertyApplication, definindo `spec: applicationImage: myapp:latest; replicas: 3; service: type: ClusterIP`.

O Operator automatiza o gerenciamento de deployments e escalabilidade.

Isso facilita setups cloud-native.

### Auto-Scaling e HA
Ative auto-scaling no YAML com `autoscaling: minReplicas: 2; maxReplicas: 10; targetCPUUtilizationPercentage: 80`. Use Horizontal Pod Autoscaler (HPA) para escalar baseado em métricas.

Configure volumeClaims para persistência de sessões e integre com Prometheus para monitoring detalhado.

Essas features promovem HA dinâmica em K8s.

## Best Practices para Configuração

### Parte 1
Use Image Streams para updates rolling sem interrupções. Ative MicroProfile Health com `livenessProbe` e `readinessProbe` no YAML para checks automáticos.

Na segurança, delegue SSO via Operator e use cert-manager para gerenciamento de TLS.

Priorize automação para eficiência.

* Automação: Scripts de deploy e configuração para múltiplos nós.
* Rolling Updates: Atualizar um member por vez.
* Monitoramento: Integrar com Prometheus, Grafana.
* Backup de Configuração: Sincronizar `server.xml` e artefatos em repositório Git.

### Parte 2
Defina limites de recursos por pod, como `requests: cpu: 1, memory: 2Gi`, para evitar overcommit. Use persistent volumes para backups e teste planos de disaster recovery.

Integre services automaticamente, como databases, via Operator.

Essas práticas otimizam performance e manutenção.

## Desafios Comuns e Soluções

Desbalanceamento de carga: Solucione com affinity rules em K8s. Conflitos de porta: Configure `host="*"` em `httpEndpoint`.

Overhead de cluster: Otimize features mínimas. Use ferramentas como Kibana para troubleshooting via logs.

Essas soluções mitigam problemas frequentes.

* Desbalanceamento de tráfego → Afinidade no LB para sessões stateful.
* Single de porta → Configure `single point of failure` no LB.
* Overhead de replicação → Minimizar objetos grandes em sessão.
* Gerenciamento manual → Usar scripts para reduzir erro humano.