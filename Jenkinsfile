def label = "mypod-${UUID.randomUUID().toString()}"
podTemplate(label: label, yaml: """
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: jenkins
    component: agent
spec:
  containers:
    - name: jnlp
      image: docker
      env:
      - name: POD_IP
        valueFrom:
          fieldRef:
            fieldPath: status.podIP
      - name: DOCKER_HOST
        value: tcp://localhost:2375
    - name: maven
      image: maven:3.3.9-jdk-8-alpine
    - name: dind
      image: docker:dind
      securityContext:
        privileged: true
      volumeMounts:
        - name: dind-storage
          mountPath: /var/lib/docker
  volumes:
    - name: dind-storage
      emptyDir: {}
"""
) {

    node (label) {
        stage('Build app') {
            container('jnlp') {
                sh "hostname"
                docker info
            }
        }
        stage('Build app') {
            git 'https://github.com/IYermakov/testapp-in-kube'
            container('maven') {
                stage('Build a Maven project') {
                    sh 'mvn -B clean package'
                }
            }
        }
        stage('Build and push image') {
            container('dind') {
                stage('Build an image') {
                    sh """
                    ls -la ./ target
                    docker build -t notregistered/dropw-app-b .
                    docker push notregistered/dropw-app-b
                    """
                }
            }
        }
    }
}
