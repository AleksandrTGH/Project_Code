FROM openjdk:11
COPY ./src/App.jar /tmp/myapp/
CMD ["java", "-jar", "App.jar"]