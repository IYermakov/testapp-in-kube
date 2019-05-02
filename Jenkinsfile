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

    stage('PR Build') {
      when { changeRequest target: 'master' }
      steps {
        container('docker') {
            withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'dockerhub',
usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASSWORD']]) {
                sh """
                    docker build -t ${DOCKERHUB_REPO}/${IMAGE}-pr:${CHANGE_ID} .
                    docker run -d --network=curltest --name='dropw-test' ${DOCKERHUB_REPO}/${IMAGE}-pr:${CHANGE_ID}
                    docker run -i --network=curltest tutum/curl /bin/bash -c '/usr/bin/curl --retry 10 --retry-delay 5 -v http://dropw-test:8080/hello-world'
                """
            }
        }
      }
      post {
         failure {
            mail to: '${authorEmail}',
            subject: "Failed Pipeline: ${currentBuild.fullDisplayName}",
            body: "Hey, {authorDisplayName}. Something is wrong with ${env.BUILD_URL}. Check it."
         }
      }
    }

    stage('Build and Publish Image from master with tag') {
      when {
        allOf { branch 'master'; buildingTag(); not { changeRequest() }  }
      }
      steps {
        container('docker') {
            sh """
                docker build -t ${DOCKERHUB_REPO}/${IMAGE}-${TAG_NAME} .
                docker run -d --network=curltest --name='dropw-test' ${DOCKERHUB_REPO}/${IMAGE}:${TAG_NAME}
                docker run -i --network=curltest tutum/curl /bin/bash -c '/usr/bin/curl --retry 10 --retry-delay 5 -v http://dropw-test:8080/hello-world'
                docker push ${DOCKERHUB_REPO}/${IMAGE}-${TAG_NAME}
            """
        }
      }
    }

    stage('Build and Publish Image from master without tag') {
      when {
        allOf { branch 'master'; not { buildingTag() }; not { changeRequest() } }
      }
      steps {
        container('docker') {
            sh """
                docker build -t ${DOCKERHUB_REPO}/${IMAGE}-${GIT_TAG_COMMIT} .
                docker run -d --network=curltest --name='dropw-test' ${DOCKERHUB_REPO}/${IMAGE}:${GIT_TAG_COMMIT}
                docker run -i --network=curltest tutum/curl /bin/bash -c '/usr/bin/curl --retry 10 --retry-delay 5 -v http://dropw-test:8080/hello-world'
                docker push ${DOCKERHUB_REPO}/${IMAGE}-${GIT_TAG_COMMIT}
            """
        }
      }
    }

    stage('Build and Publish Image from other branches with tag') {
      when { allOf { not { branch 'master' }; buildingTag(); not { changeRequest() } } }
      steps {
        container('docker') {
            withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'dockerhub',
usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASSWORD']]) {
                sh """
                    docker build -t ${DOCKERHUB_REPO}/${IMAGE}-${GIT_BRANCH}:${TAG_NAME} .
                    docker run -d --network=curltest --name='dropw-test' ${DOCKERHUB_REPO}/${IMAGE}-${GIT_BRANCH}:${TAG_NAME}
                    docker run -i --network=curltest tutum/curl /bin/bash -c '/usr/bin/curl --retry 10 --retry-delay 5 -v http://dropw-test:8080/hello-world'
                    docker push ${DOCKERHUB_REPO}/${IMAGE}-${GIT_BRANCH}:${TAG_NAME}
                """
            }
        }
      }
    }

    stage('Build and Publish Image from other branches without tag') {
      when { allOf { not { branch 'master' }; not { buildingTag() }; not { changeRequest() } } }
      steps {
        container('docker') {
            withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'dockerhub',
usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASSWORD']]) {
                sh """
                    docker build -t ${DOCKERHUB_REPO}/${IMAGE}-${GIT_BRANCH}:${GIT_TAG_COMMIT} .
                    docker run -d --network=curltest --name='dropw-test' ${DOCKERHUB_REPO}/${IMAGE}-${GIT_BRANCH}:${GIT_TAG_COMMIT}
                    docker run -i --network=curltest tutum/curl /bin/bash -c '/usr/bin/curl --retry 10 --retry-delay 5 -v http://dropw-test:8080/hello-world'
                    docker push ${DOCKERHUB_REPO}/${IMAGE}-${GIT_BRANCH}:${GIT_TAG_COMMIT}
                """
            }
        }
      }
    }

  }
  post {
    success {
        mail to: 'notregisterednick@gmail.com',
        subject: "Failed Pipeline: ${currentBuild.fullDisplayName}",
        body: "Hey, {authorDisplayName}. ${env.BUILD_URL} is success."
    }
  }
}
