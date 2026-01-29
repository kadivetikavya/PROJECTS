
# Stage 1 — Build WAR

FROM maven:3.9.6-eclipse-temurin-17 AS buildstage

WORKDIR /opt/myapp

# Copy only pom first (better Docker caching)
COPY pom.xml .
RUN mvn -B -q -e -DskipTests dependency:go-offline

# Copy source and build
COPY src ./src
RUN mvn clean package -DskipTests



# Stage 2 — Tomcat Runtime

FROM tomcat:9.0-jdk17-temurin

WORKDIR /usr/local/tomcat/webapps

# Remove default apps (security best practice)
RUN rm -rf ROOT docs examples host-manager manager

# Copy built WAR and rename to ROOT.war
COPY --from=buildstage /opt/myapp/target/*.war ROOT.war

EXPOSE 8080

CMD ["catalina.sh", "run"]
