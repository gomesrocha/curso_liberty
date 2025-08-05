---
title: Curso Liberty
Author: Fabio Gomes Rocha
---

# Curso Liberty
## Aula 1

### 0. Aplicações Tradicionais vs. Cloud-Native

Aplicações Java empresariais evoluíram de **aplicações tradicionais** (monolíticas, geralmente hospedadas on-premise) para **aplicações cloud-native** (distribuídas, otimizadas para ambientes de nuvem). O WAS Liberty é uma ponte ideal para gerenciar ambas, permitindo que a empresa mantenha sistemas monolíticos atuais enquanto planeja a migração para microsserviços.

- **Aplicações Tradicionais (Monolíticas)**:
  - **Definição**: Sistemas grandes, com todas as funcionalidades (UI, lógica de negócios, persistência) em um único artefato (ex.: WAR/EAR).
  - **Características**: Arquitetura em camadas, hospedada em servidores de aplicação robustos como WAS Tradicional, com foco em estabilidade e integração com sistemas legados.
  - **Uso na Empresa**: Apps legados da empresa, como sistemas ERP ou CRM, que rodam em servidores on-premise com lógica complexa.
  - **Desafios**: Escalabilidade limitada, alto consumo de recursos, dificuldade em atualizações rápidas.

- **Aplicações Cloud-Native**:
  - **Definição**: Sistemas projetados para nuvem, geralmente divididos em microsserviços, rodando em containers (ex.: Docker) e orquestrados por Kubernetes.
  - **Características**: Leves, escaláveis, com deploy independente, suporte a DevOps (CI/CD), monitoramento (Prometheus), e resiliência (fault tolerance).
  - **Uso na Empresa**: Preparação para microsserviços, com serviços menores e independentes, como APIs REST para integração com novos sistemas.
  - **Vantagens**: Escalabilidade horizontal, atualizações frequentes, integração com cloud híbrida.

#### Comparação: Necessidades de Aplicações Tradicionais vs. Cloud-Native

| Aspecto                | Aplicações Tradicionais (Monolíticas)                       | Aplicações Cloud-Native (Microsserviços)                     |
|------------------------|-------------------------------------------------------------|-------------------------------------------------------------|
| **Arquitetura**        | Monolítica, camadas acopladas (UI, negócios, dados).        | Distribuída, microsserviços independentes.                  |
| **Escalabilidade**     | Vertical (mais hardware), clustering complexo.              | Horizontal, auto-scaling via Kubernetes.                    |
| **Gerenciamento**      | Configuração estática, consoles pesados.                    | Configuração dinâmica, CLI, integração com DevOps.          |
| **Deployment**         | WAR/EAR único, deploy lento, reinicialização necessária.    | Containers leves, deploy rápido, hot-reload.                |
| **Recursos**           | Alto consumo (CPU, memória), servidores dedicados.          | Baixo consumo, otimizado para containers (ex.: 200 MB).     |
| **Manutenção**         | Atualizações raras, risco de quebras em upgrades.           | CI/CD, atualizações frequentes sem downtime.                |
| **Monitoramento**      | Logs locais, ferramentas proprietárias.                     | Health checks, métricas (Prometheus), tracing (OpenTelemetry). |
| **Uso no Liberty**     | Suporte a Jakarta EE full para apps legados.                | Suporte a MicroProfile para serviços leves e cloud-ready.   |

**Relevância para a Empresa**: O Liberty suporta monolíticos (Jakarta EE) para apps legados e microsserviços (MicroProfile) para modernização, reduzindo custos e facilitando a transição para cloud.

## 1. O Que é WAS Liberty

O **WAS Liberty** (WebSphere Application Server Liberty) é uma versão leve, modular e de alto desempenho do servidor de aplicação WebSphere da IBM, baseado no projeto open-source **Open Liberty**. Ele é projetado para rodar aplicações Java empresariais, suportando tanto sistemas monolíticos quanto microsserviços, com foco em eficiência e cloud-native.

### Características Principais
- **Código Aberto**: Baseado no Open Liberty, com suporte comercial no WAS Liberty (atualizações, segurança, integração com IBM Cloud Pak).
- **Compatibilidade**: Totalmente compatível com **Jakarta EE 10+**, garantindo portabilidade e interoperabilidade de aplicações.
- **Leveza**: Inicia em segundos, com footprint de ~200 MB (vs. 1 GB+ de servidores tradicionais).
- **Escalabilidade**: Suporta **clustering** nativo para alta disponibilidade; balanceamento de carga externo (ex.: Kubernetes, NGINX).
- **Gerenciamento**: Interface CLI para configuração e Admin Center (web) para monitoramento.
- **Casos de Uso**: Ideal para apps monolíticos legados da empresa e transição para microsserviços em ambientes cloud.

**Relevância para a Empresa**: Gerencia sistemas monolíticos atuais com compatibilidade Jakarta EE, enquanto prepara para microsserviços, reduzindo custos operacionais.

## 2. Arquitetura Jakarta EE (Evolução da J2EE)

A **Jakarta EE** é a evolução da J2EE, agora gerenciada pela Eclipse Foundation. Foca em aplicações Java empresariais, com modularidade e suporte a cloud.

### Componentes Principais
- **APIs**: Servlets, WebSockets, JPA (persistência), EJB (lógica de negócios), JMS (messaging), JAX-RS (REST), Jakarta Security.
- **Perfis**:
  - **Web Profile**: Leve, para apps web.
  - **Full Profile**: Completo, para apps complexos.
- **Portabilidade**: Apps rodam em qualquer servidor Jakarta EE compatível.
- **Vantagens**: Modularidade (use apenas o necessário), suporte a CDI (injeção de dependências), integração com NoSQL (Jakarta NoSQL).

**No Liberty**: Suporta Jakarta EE 10+ e MicroProfile, ideal para monolíticos (full EE) e microsserviços (subsets leves).

**Diagrama Sugerido**: Comparar J2EE (camadas fixas: cliente, web, business, EIS) vs. Jakarta EE (modular, cloud-ready).

## 3. Introdução ao Jakarta EE

### O que é o Jakarta EE?
Jakarta EE é a evolução do Java EE (Java Platform, Enterprise Edition), agora mantido pela Eclipse Foundation. É uma plataforma padrão para o desenvolvimento de aplicações corporativas Java, portáveis e escaláveis, utilizando especificações maduras e amplamente adotadas.

| Etapa | Evento |
|-------|--------|
| Java EE | Criado pela Sun Microsystems, depois mantido pela Oracle. |
| 2017 | Oracle doa Java EE à Eclipse Foundation. |
| 2018 | Renomeado para Jakarta EE. |
| 2020+ | Jakarta EE continua evoluindo sob a Eclipse. |

**Objetivo da Plataforma**:
- Criar sistemas robustos, seguros e escaláveis.
- Fornecer APIs padronizadas e estáveis.
- Garantir portabilidade entre servidores de aplicação.
- Suporte completo a aplicações corporativas monolíticas ou distribuídas.

**Principais APIs e Especificações**:
| API | Finalidade |
|-----|------------|
| JAX-RS | APIs RESTful |
| JPA | Persistência ORM com anotações |
| CDI | Injeção de dependência e ciclo de vida |
| EJB | Transações, timers e lógica de negócio |
| Servlet | Manipulação HTTP de baixo nível |
| Jakarta Security | Segurança baseada em roles e contextos |
| Jakarta Batch | Processamento em lote |
| Jakarta JMS | Comunicação assíncrona via mensagens |
| Jakarta Faces (JSF) | UI baseada em componentes para web |
| Bean Validation | Validação declarativa com anotações |

**Arquitetura**:
- **Camada de Apresentação**: JSF, Servlets, REST (JAX-RS).
- **Camada de Negócio**: CDI, EJB.
- **Camada de Persistência**: JPA.
- **Outros**: Segurança, Transações, Messaging, Configurações.

## 4. MicroProfile

**MicroProfile** é um padrão open-source para microsserviços Java, complementar ao Jakarta EE, com foco em cloud-native.

**Objetivo do MicroProfile**:
- Levar o Java corporativo para a nuvem e microsserviços.
- Oferecer funcionalidades como configuração externa, tolerância a falhas, métricas e rastreamento.
- Facilitar a integração com ferramentas DevOps modernas (Prometheus, Jaeger, Kubernetes).
- Reduzir o acoplamento e simplificar a infraestrutura de microsserviços.

### Principais Especificações
- **MicroProfile Config**: Externaliza configurações (ex.: variáveis de ambiente).
- **MicroProfile Health**: Endpoints `/health` para monitoramento em Kubernetes.
- **MicroProfile Metrics**: Exporta métricas para Prometheus.
- **MicroProfile OpenAPI**: Documentação automática de APIs REST.
- **MicroProfile Fault Tolerance**: Resiliência com retries, circuit breakers.
- **MicroProfile JWT**: Autenticação via JSON Web Tokens.
- **MicroProfile Rest Client**: Chamadas REST type-safe.
- **MicroProfile Telemetry**: Rastreamento com OpenTelemetry.

## 5. Diferenças entre WAS Tradicional x WAS Liberty

| Aspecto | WAS Tradicional (Classic) | WAS Liberty |
|---------|---------------------------|-------------|
| **Arquitetura** | Monolítica, kernel pesado, inicia lento (~minutos), footprint alto (1 GB+). | Modular, kernel leve, inicia rápido (~segundos), ~200 MB, composável para microsserviços. |
| **Desempenho** | Alto overhead, ideal para apps legados on-premise, ineficiente em cloud. | Baixo consumo, otimizado para cloud, com live reload e dev mode. |
| **Compatibilidade** | Suporta Java EE legado (ex.: EE6), mas migrações podem exigir mudanças. | Foco em Jakarta EE 7+, MicroProfile; atualizações sem quebra de API. |
| **Segurança** | Suporte completo a SSO, auditing, etc. | Subset de segurança, extensível, mais leve. |
| **Gerenciamento** | Console administrativo pesado, clustering complexo. | CLI simples, Admin Center web, clustering leve, balanceamento externo. |
| **Uso na Empresa** | Ideal para monolíticos legados, caro em cloud. | Transição para monolíticos e microsserviços, custo-efetivo em cloud. |

**Resumo**: WAS Tradicional é robusto para on-premise; Liberty é ágil para cloud, reduzindo TCO em até 50%.

## 6. Arquitetura WAS Liberty

A arquitetura do WAS Liberty é baseada em um **kernel leve** e **modular** (OSGi):
- **Kernel Core**: Núcleo mínimo, inicia rápido, adiciona features sob demanda.
- **Features Modulares**: Habilitadas via `server.xml` (ex.: `jakartaee-10.0`, `mpMetrics-5.0`).
- **Camadas**:
  - **Runtime Layer**: Gerencia containers (Servlet, EJB) e serviços (transações, segurança).
  - **Configuration Layer**: Configuração via XML/JSON, com variáveis dinâmicas.
  - **Extension Layer**: Integração com Kubernetes (probes, metrics para Prometheus).
- **Escalabilidade**: Clustering nativo, auto-scaling em Kubernetes, InstantOn para startup sub-segundo.

## 7. Comandos Iniciais para Configurar o Servidor

Assuma o Open Liberty instalado em `/opt/liberty` (baixe em [openliberty.io](https://openliberty.io/downloads/) ou use Docker: `docker pull icr.io/appcafe/open-liberty`).

### Comandos Básicos
1. **Criar Servidor**:
   ```bash
   bin/server create myserver
   ```
   Cria servidor em `wlp/usr/servers/myserver`.

2. **Iniciar Servidor**:
   ```bash
   bin/server start myserver
   ```
   Inicia em background; logs em `servers/myserver/logs`. Para debug: `bin/server debug myserver`.

3. **Parar Servidor**:
   ```bash
   bin/server stop myserver
   ```

4. **Dev Mode (Hot-Reload)**:
   ```bash
   mvn liberty:dev
   ```
   Requer Maven; ideal para desenvolvimento.

5. **Deploy de Aplicação**:
   Copie WAR/EAR para `dropins/` ou adicione ao `server.xml`:
   ```xml
   <application location="myapp.war"/>
   ```

### Gerenciamento de Módulos (Features)
- **Instalar Feature**:
   ```bash
   bin/installUtility install jakartaee-10.0
   ```
   Baixa do Liberty Repository.

- **Listar Features Instaladas**:
   ```bash
   bin/productInfo featureInfo
   ```

- **Adicionar Feature no server.xml**:
   ```xml
   <featureManager>
       <feature>jakartaee-10.0</feature>
       <feature>mpConfig-3.1</feature>
   </featureManager>
   ```

### Onde Encontrar Módulos
- **Open Liberty Docs**: [Feature Reference](https://openliberty.io/docs/latest/reference/feature/) (lista completa, ex.: `mpMetrics-5.0`, `jpa-3.1`).
- **Liberty Repository**: Use `bin/installUtility find` para explorar.
- **WAS Liberty**: Features comerciais em [IBM Fix Central](https://www.ibm.com/support/fixcentral/).

## 8. MicroProfile no WAS Liberty

### Exemplo de Configuração
Habilite MicroProfile no `server.xml`:
```xml
<featureManager>
    <feature>microProfile-6.1</feature>
</featureManager>
```

**Exemplo de Health Check**:
```java
import org.eclipse.microprofile.health.HealthCheck;
import org.eclipse.microprofile.health.HealthCheckResponse;
import org.eclipse.microprofile.health.Liveness;

@Liveness
public class MyHealthCheck implements HealthCheck {
    @Override
    public HealthCheckResponse call() {
        return HealthCheckResponse.up("MyService");
    }
}
```
Acesse: `http://localhost:9080/health`.

### Relevância para a Empresa
- **Monolíticos**: Use Jakarta EE para apps legados.
- **Microsserviços**: MicroProfile para serviços leves, com health checks e métricas.
- **Transição**: Liberty suporta ambos, facilitando migração gradual.

## 9. Futuro do Liberty em Cloud-Native
- **InstantOn/CRaC**: Startup sub-segundo para serverless.
- **Kubernetes/OpenShift**: Integração com probes, auto-scaling.
- **MicroProfile/Jakarta EE 11+**: Suporte a AI/ML, NoSQL.
- **Ferramentas**: Liberty Tools para IDEs, badges para certificação.
- **Guias**: 60+ guias em [openliberty.io](https://openliberty.io).

**Para a Empresa**: Reduz TCO, suporta monolíticos atuais e migração para microsserviços em cloud híbrida.