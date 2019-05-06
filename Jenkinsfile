pipeline {
  options {
    timestamps()
  }
  environment {
    DOCKERHUB_REPO = 'notregistered'
    DOCKERHUB_SERVER = 'https://index.docker.io/v1/'
    IMAGE = 'dropw'
    IMAGE_NAME = 'dropw'
    IMAGE_TAG = 'latest'
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
      image: maven:3.5.2
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
//          sh 'mvn -Dmaven.test.failure.ignore clean package'
          sh 'mvn -Dmaven.test.failure.ignore package'
        }
      }
    }

    stage('Preparation') {
        steps{
            container('docker') {
                withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'dockerhub',
usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASSWORD']]) {
                    sh """
                        docker login -u ${DOCKER_USER} -p ${DOCKER_PASSWORD} ${DOCKERHUB_SERVER}
                        docker network create --driver=bridge curltest
                    """
                }
            }
        }
    }
    stage('Setting variables ') {
      when { buildingTag() }
      steps {
        sh """
            IMAGE_TAG = "${TAG_NAME}"
        """
      }
    }

    stage('PR docker build') {
      when { changeRequest target: 'master' }
      steps {
        container('docker') {
            withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'dockerhub',
usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASSWORD']]) {
                sh """
                    docker build -t ${DOCKERHUB_REPO}/${IMAGE}-pr:${CHANGE_ID} .
                    docker run -d --network=curltest --name='dropw-test' ${DOCKERHUB_REPO}/${IMAGE}-pr:${CHANGE_ID}
                    docker run -i --network=curltest tutum/curl /bin/bash -c '/usr/bin/curl --retry 10 --retry-delay 1 -v http://dropw-test:8080/hello-world'
                """
            }
        }
      }
    }

    stage('Regular docker build') {
      when { not { changeRequest() } }
        steps {
            container('docker') {
                withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'dockerhub',
usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASSWORD']]) {
                    sh """
                        IMAGE_NAME = ("${GIT_BRANCH}"=='master') ? "${DOCKERHUB_REPO}/${IMAGE}" : "${DOCKERHUB_REPO}/${IMAGE}-${GIT_BRANCH}"
                        IMAGE_TAG = (${IMAGE_TAG}==null) ? "${GIT_TAG_COMMIT}"
                        docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                        docker run -d --net=curltest --name='dropw-test' ${IMAGE_NAME}:${IMAGE_TAG}
                        docker run -i --net=curltest tutum/curl /bin/bash -c '/usr/bin/curl --retry 10 --retry-delay 1 -v http://dropw-test:8080/hello-world'
                        docker push ${IMAGE_NAME}:${IMAGE_TAG}
                    """
                }
            }
       }
    }

  }
}
