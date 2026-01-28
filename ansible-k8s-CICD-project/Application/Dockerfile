# Use Eclipse Temurin JDK 17 on Alpine 3.18
FROM eclipse-temurin:17-jdk-alpine3.18

# Set working directory
WORKDIR /app

# Copy only the built JAR from Maven target
COPY target/myapp-1.0.jar app.jar

# Expose application port
EXPOSE 8080

# Run the JAR
ENTRYPOINT ["java", "-jar", "app.jar"]

