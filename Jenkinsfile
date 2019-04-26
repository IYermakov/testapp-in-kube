pipeline {
  options {
    timestamps()
  }
  environment {
    DOCKERHUB_REPO = 'notregistered'
    IMAGE = 'dropw'
    GIT_TAG_COMMIT = sh (script: 'git describe --tags --always', returnStdout: true).trim()
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
    }
  }
  stages {
    stage('Run maven') {
      steps {
        container('maven') {
          sh 'mvn -Dmaven.test.failure.ignore clean package'
          sh 'printenv'
        }
      }
    }
    stage('Build and Publish Image from master') {
      when {
        branch 'master'
      }
      steps {
        container('docker') {
            sh '''
            docker build -t ${DOCKERHUB_REPO}/${IMAGE}:${GIT_TAG_COMMIT} .
            docker push ${DOCKERHUB_REPO}/${IMAGE}:${GIT_TAG_COMMIT}
            '''
        }
      }
    }
    stage('Build and Publish Image from other branches') {
      when {
        not {
            branch 'master'
        }
      }
      steps {
        container('docker') {
            sh '''
            echo ${DOCKERHUB_REPO}
            echo ${IMAGE}
            echo ${GIT_TAG_COMMIT}
            echo ${GIT_BRANCH}
            echo ${DOCKERHUB_REPO}/${IMAGE}:${GIT_TAG_COMMIT}
            '''
            sh '''
            docker build -t ${DOCKERHUB_REPO}/${IMAGE}-${GIT_BRANCH}:${GIT_TAG_COMMIT} .
            docker push ${DOCKERHUB_REPO}/${IMAGE}-${GIT_BRANCH}:${GIT_TAG_COMMIT}
            '''
        }
      }
    }
  }
}
