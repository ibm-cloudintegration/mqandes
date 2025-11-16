FROM maven:3.9.4-ibm-semeru-17-focal
 
COPY src src
COPY pom.xml pom.xml

RUN mvn clean install package

FROM openjdk:22-slim-buster

WORKDIR /app

COPY --from=0 target/payment-gateway-0.0.1-jar-with-dependencies.jar /app
ENTRYPOINT java -cp payment-gateway-0.0.1-jar-with-dependencies.jar com.ibm.example.readMQMessages
#ENTRYPOINT ["java", "-cp", "payment-gatewsy-0.0.1-jar-with-dependencies.jar" "com.ibm.example.readMQMessages"]
