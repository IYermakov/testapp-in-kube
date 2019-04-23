def builder = "builder-${UUID.randomUUID().toString()}"
podTemplate(label: builder, yaml: """
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins
  containers:
    - name: docker
      image: docker
      command:
      - cat
      tty: true
      env:
      - name: POD_IP
        valueFrom:
          fieldRef:
            fieldPath: status.podIP
      - name: DOCKER_HOST
        value: tcp://localhost:2375
    - name: maven
      image: maven:latest
      command:
      - cat
      tty: true
    - name: kubectl
      image: lachlanevenson/k8s-kubectl
      command:
      - cat
      tty: true
    - name: dind
      image: docker:18.05-dind
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

  node (builder) {
    stage('Preparation') {
      git 'https://github.com/IYermakov/testapp-in-kube'
    }
/*    
    stage ('build') {
        container('maven') {
            sh "mvn -Dmaven.test.failure.ignore clean package"
        }
    }
    
    stage ('publish container') {
        container('docker') {
            withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'dockerhub', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD']]) {
                sh """
                    echo ${PASSWORD}
                    echo "username is ${env.USERNAME}"
                    docker info
                    docker login -u $USERNAME -p $PASSWORD
                    docker build -t notregistered/dropw-app-b .
                    docker push notregistered/dropw-app-b
                """
            }
        }
    }
*/
    stage ('Deploy to k8s') {
        container('kubectl') {
            sh "kubectl apply -f jenkins/app-pod.yml"
        }
    }
  }
}
