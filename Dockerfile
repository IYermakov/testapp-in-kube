FROM openjdk:8-jre-alpine

LABEL io.k8s.description="Simple RESTful Application" \
      io.k8s.display-name="dropw"

WORKDIR /
ADD target/dropwizard-example-0.0.1-SNAPSHOT.jar dropwizard.jar
ADD example.mv.db example.mv.db
ADD example.yml example.yml
EXPOSE 8080
RUN java -jar dropwizard.jar db migrate example.yml
CMD java -Xmx750M -jar dropwizard.jar server example.yml
