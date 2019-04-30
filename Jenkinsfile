pipeline {
  options {
    timestamps()
  }
  environment {
    DOCKERHUB_REPO = 'notregistered'
    DOCKERHUB_SERVER = 'https://index.docker.io/v1/'
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
      image: docker:latest
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
//      when { branch 'master' }
      steps {
        container('maven') {
          sh 'mvn -Dmaven.test.failure.ignore clean package'
//          sh 'printenv'
        }
      }
    }

    stage('Build and Publish Image from master with tag') {
      when {
        allOf { branch 'master'; buildingTag() }
      }
      steps {
        container('docker') {
            sh """
                docker login -u ${DOCKER_USER} -p ${DOCKER_PASSWORD} ${DOCKERHUB_SERVER}
                docker build -t ${DOCKERHUB_REPO}/${IMAGE}-${TAG_NAME} .
                docker push ${DOCKERHUB_REPO}/${IMAGE}-${TAG_NAME}
            """
        }
      }
    }

    stage('Build and Publish Image from master without tag') {
      when {
        allOf { branch 'master'; not { buildingTag() } }
      }
      steps {
        container('docker') {
            sh """
                docker login -u ${DOCKER_USER} -p ${DOCKER_PASSWORD} ${DOCKERHUB_SERVER}
                docker build -t ${DOCKERHUB_REPO}/${IMAGE}-${GIT_TAG_COMMIT} .
                docker push ${DOCKERHUB_REPO}/${IMAGE}-${GIT_TAG_COMMIT}
            """
        }
      }
    }

    stage('Build and Publish Image from other branches with tag') {
      when { allOf { not { branch 'master' }; buildingTag() } }
      steps {
        container('docker') {
            withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'dockerhub',
usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASSWORD']]) {
                sh """
                    docker login -u ${DOCKER_USER} -p ${DOCKER_PASSWORD} ${DOCKERHUB_SERVER}
                    docker build -t ${DOCKERHUB_REPO}/${IMAGE}-${GIT_BRANCH}:${TAG_NAME} .
                    docker push ${DOCKERHUB_REPO}/${IMAGE}-${GIT_BRANCH}:${TAG_NAME}
                """
            }
        }
      }
    }

    stage('Build and Publish Image from other branches without tag') {
      when { allOf { not { branch 'master' }; not { buildingTag() } } }
      steps {
        container('docker') {
            withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'dockerhub',
usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASSWORD']]) {
                sh """
                    printenv
                    cat /etc/hosts
                    docker login -u ${DOCKER_USER} -p ${DOCKER_PASSWORD} ${DOCKERHUB_SERVER}
                    docker build -t ${DOCKERHUB_REPO}/${IMAGE}-${GIT_BRANCH}:${GIT_TAG_COMMIT} .
                    docker network create curltest
                    docker network ls
                    docker run -d --network=curltest --name=dropw-test ${DOCKERHUB_REPO}/${IMAGE}-${GIT_BRANCH}:${GIT_TAG_COMMIT}
                    docker ps
                    docker network inspect curltest
                    docker run -i --network=curltest appropriate/curl /usr/bin/curl --retry 10 --retry-delay 5 -v http://dropw-test/hello-world
//                    docker push ${DOCKERHUB_REPO}/${IMAGE}-${GIT_BRANCH}:${GIT_TAG_COMMIT}
                """
            }
        }
      }
    }

  }
}
