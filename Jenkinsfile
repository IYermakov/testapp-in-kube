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
      steps {
        container('maven') {
          sh 'mvn -Dmaven.test.failure.ignore clean package'
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

//    stage ('Build docker image') {
//    parallel {

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
      /*post {
        failure {
            mail to: '${authorEmail}',
            subject: "Failed Pipeline: ${currentBuild.fullDisplayName}",
            body: "Hey, {authorDisplayName}. ${env.BUILD_URL} failure. Check it."
        }
      }*/
    }

    stage('Regular docker build') {
      when { not { changeRequest() } }
      steps {
        container('docker') {
            withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'dockerhub',
usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASSWORD']]) {
                sh """
                    if (${GIT_BRANCH} == "master") {
                        IMAGE_NAME="${DOCKERHUB_REPO}/${IMAGE}"
                    }
                    else { IMAGE_NAME="${DOCKERHUB_REPO}/${IMAGE}-${GIT_BRANCH}" }

                    if (${TAG_NAME}!=NULL) {
                        IMAGE_TAG="${TAG_NAME}"
                    }
                    else { IMAGE_TAG="${GIT_TAG_COMMIT}" }

                    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                    docker run -d --network=curltest --name='dropw-test' ${IMAGE_NAME}:${IMAGE_TAG}
                    docker run -i --network=curltest tutum/curl /bin/bash -c '/usr/bin/curl --retry 10 --retry-delay 1 -v http://dropw-test:8080/hello-world'
                    docker push ${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }
      }
    }

//    }
//    }


  }
}
