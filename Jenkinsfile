def label = "builder-${UUID.randomUUID().toString()}"

podTemplate(label: label, containers: [
  containerTemplate(name: 'maven', image: 'maven:3.3.9-jdk-8-alpine', ttyEnabled: true, command: 'cat'),
  containerTemplate(name: 'docker', image: 'docker:latest', ttyEnabled: true, command: 'cat'),
  ],
  volumes: [hostPathVolume(hostPath: '/var/run/docker.sock', mountPath: '/var/run/docker.sock'),],) {
    body.call(label)
  }
{

    node(label) {
        stage('Build a Maven project') {
            git 'https://github.com/IYermakov/testapp-in-kube'
            container('maven') {
                sh 'mvn -B clean package'
            }
        }
        stage('Docker build and push to hub') {
            container('docker') {
                sh 'ls -la ./ target'
                sh 'docker build -t notregistered/dropw-app-b .'
                sh 'docker push notregistered/dropw-app-b'
            }
        }
    }
}
