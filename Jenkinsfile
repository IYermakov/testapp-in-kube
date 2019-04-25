pipeline {
  options {
    timestamps()
  }
  environment {
    IMAGE = 'dropw'
    VERSION = '{env.GIT_COMMIT}'
  }
  agent {
    kubernetes {
      label 'mypod'
      yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
    - name: docker
      image: docker
      command:
      - cat
      tty: true
      env:
      - name: DOCKER_HOST
        value: tcp://localhost:2375 */
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
    }
  }
  stages {
    stage('Run maven') {
      steps {
        container('maven') {
          sh 'mvn -Dmaven.test.failure.ignore clean package'
        }
      }
    }
    stage('Build and Publish Image') {
      when {
        branch 'master'
      }
      steps {
        container('maven') {
            sh """
            docker build -t ${IMAGE} .
            docker tag ${IMAGE} ${IMAGE}:${VERSION}
            docker push ${IMAGE}:${VERSION}
            """
        }
      }
    }
  }
}
