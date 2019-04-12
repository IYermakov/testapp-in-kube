FROM openjdk:8-jre-alpine
WORKDIR /
ADD dropwizard.jar dropwizard.jar
ADD mysql.yml mysql.yml
EXPOSE 8080
EXPOSE 8081
CMD java -Xmx750M -jar dropwizard.jar server mysql.yml
#LABEL "com.datadoghq.ad.logs"='[{"environment": "qa", "source": "application", "service": "dropwizard"}]'
