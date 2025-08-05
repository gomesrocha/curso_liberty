# Laboratórios Práticos: Aula 1 - Open Liberty e WAS Liberty

Os laboratórios a seguir são projetados para reforçar os conceitos apresentados na aula, com foco em configuração, gerenciamento de features e deploy de aplicações. Pré-requisitos: JDK 17+, Maven 3.8+, Open Liberty instalado em `/opt/liberty` (ou use Docker: `docker pull icr.io/appcafe/open-liberty`). Cada laboratório leva ~20-30 minutos.

## Laboratório 1: Configurando o Primeiro Servidor Liberty

**Objetivo**: Criar e configurar um servidor Liberty, adicionar features e explorar o Admin Center.

**Passos**:
1. **Criar um Servidor**:
   ```bash
   /opt/liberty/bin/server create myserver
   ```
   Verifique a pasta criada em `/opt/liberty/wlp/usr/servers/myserver`.

2. **Adicionar Features**:
   Edite `wlp/usr/servers/myserver/server.xml`:
   ```xml
   <featureManager>
        <feature>adminCenter-1.0</feature>
        <feature>restConnector-2.0</feature>
        <feature>jakartaee-10.0</feature>
        <feature>microProfile-7.0</feature>
       <feature>webProfile-10.0</feature>
       <feature>mpHealth-4.0</feature>
   </featureManager>
   ```
   Instale as features:
   ```bash
   /opt/liberty/bin/installUtility install webProfile-10.0 mpHealth-4.0
   ```

3. **Iniciar o Servidor**:
   ```bash
   /opt/liberty/bin/server start myserver
   ```
   Verifique os logs em `wlp/usr/servers/myserver/logs/console.log`.

4. **Acessar o Admin Center**:
   - Adicione ao `server.xml`:
     ```xml
         <basicRegistry id="basic" realm="BasicRealm">
        <user name="admin" password="senhaSegura"/>
    </basicRegistry>

    <administrator-role>
        <user>admin</user>
    </administrator-role>
    
     ```
   - Instale a feature: `bin/installUtility install adminCenter-1.0`.
   - Reinicie o servidor: `bin/server stop myserver && bin/server start myserver`.
   - Acesse `https://localhost:9443/adminCenter` (login: admin/adminpwd).

**Tarefa**: Liste as features instaladas com `bin/productInfo featureInfo` e verifique o endpoint `/health` em `http://localhost:9080/health`.

## Laboratório 2: Deploy de uma Aplicação Simples

**Objetivo**: Deploy de uma aplicação WAR simples e teste de funcionalidade.

**Passos**:
1. **Criar uma Aplicação Simples**:
   Crie um projeto Maven:
   ```bash
   mvn archetype:generate -DgroupId=com.example -DartifactId=simple-app -DarchetypeArtifactId=maven-archetype-webapp -DinteractiveMode=false
   ```
   Adicione ao `pom.xml`:
   ```xml
   <dependency>
       <groupId>jakarta.servlet</groupId>
       <artifactId>jakarta.servlet-api</artifactId>
       <version>6.0.0</version>
       <scope>provided</scope>
   </dependency>
   <plugin>
       <groupId>io.openliberty.tools</groupId>
       <artifactId>liberty-maven-plugin</artifactId>
       <version>3.10</version>
   </plugin>
   ```

2. **Criar um Servlet**:
   Em `src/main/java/com/example/HelloServlet.java`:
   ```java
   package com.example;
   import jakarta.servlet.annotation.WebServlet;
   import jakarta.servlet.http.HttpServlet;
   import jakarta.servlet.http.HttpServletRequest;
   import jakarta.servlet.http.HttpServletResponse;
   import java.io.IOException;

   @WebServlet("/hello")
   public class HelloServlet extends HttpServlet {
       protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
           resp.getWriter().write("Hello from Liberty!");
       }
   }
   ```

3. **Build e Deploy**:
   ```bash
   cd simple-app
   mvn package
   cp target/simple-app.war /opt/liberty/wlp/usr/servers/myserver/dropins/
   ```
   Reinicie o servidor: `bin/server stop myserver && bin/server start myserver`.

4. **Testar**:
   Acesse `http://localhost:9080/simple-app/hello` e verifique a mensagem "Hello from Liberty!".

**Tarefa**: Modifique o Servlet para retornar o nome do usuário via parâmetro (ex.: `/hello?name=Aluno`), e redeploy.

## Laboratório 3: Implementando MicroProfile Health Check

**Objetivo**: Adicionar um health check com MicroProfile e testar integração com cloud-native.

**Passos**:
1. **Adicionar MicroProfile**:
   No `server.xml`:
   ```xml
   <featureManager>
       <feature>microProfile-6.1</feature>
   </featureManager>
   ```
   Instale: `bin/installUtility install microProfile-6.1`.

2. **Criar Health Check**:
   No projeto Maven, adicione a dependência:
   ```xml
   <dependency>
       <groupId>org.eclipse.microprofile</groupId>
       <artifactId>microprofile</artifactId>
       <version>6.1</version>
       <type>pom</type>
       <scope>provided</scope>
   </dependency>
   ```
   Crie `src/main/java/com/example/MyHealthCheck.java`:
   ```java
   package com.example;
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

3. **Build e Deploy**:
   ```bash
   mvn package
   cp target/simple-app.war /opt/liberty/wlp/usr/servers/myserver/dropins/
   ```
   Reinicie o servidor.

4. **Testar**:
   Acesse `http://localhost:9080/health`. Verifique o JSON retornado: `{"status":"UP","checks":[{"name":"MyService","status":"UP"}]}`.

**Tarefa**: Adicione um `@Readiness` check que verifica uma condição (ex.: conexão com banco de dados fictícia) e teste `/health/ready`.

## Notas
- **Ambiente**: Use um ambiente local ou VM com Open Liberty e Maven. Alternativamente, use Docker para simplificar.
- **Validação**: Após cada laboratório, peça aos alunos para compartilhar resultados no Admin Center ou via endpoints.
- **Duração**: ~1 hora para Laboratórios 1 e 2, ~45 minutos para Laboratório 3, com 15 minutos para discussão.