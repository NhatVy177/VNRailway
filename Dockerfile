# Stage 1: Build the application using Maven
FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /app

# Copy the pom.xml and download dependencies (optional optimization step, but we copy all for simplicity)
COPY pom.xml .
COPY src ./src

# Build the application
RUN mvn clean package -DskipTests

# Stage 2: Create a lightweight image for running the application
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Copy the built jar file from the build stage
COPY --from=build /app/target/*.jar app.jar

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
