pipeline {
  options {
    timestamps()
  }
  environment {
    DOCKERHUB_REPO = 'notregistered'
    DOCKERHUB_SERVER = 'https://index.docker.io/v1/'
    IMAGE = 'dropw'
    IMAGE_NAME = 'dropw'
    IMAGE_TAG = sh (script: 'git describe --tags --always', returnStdout: true).trim()
    CHART_DIR = 'dropw-app'
    CLUSTER_KUBECONFIG = 'ibm_devcluster_kubeconfig'
    CLUSTER_CERT = 'ibm_devcluster_cert'
  }
  agent {
  kubernetes {
    label 'mypod'
    yaml """
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins
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
    - name: helm
      image: alpine/helm:2.13.1
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
    stage('Setting variables ') {
      when { buildingTag() }
      steps {
        script {
            IMAGE_TAG = "${TAG_NAME}"
        }
      }
    }

    stage('Run maven') {
      steps {
        container('maven') {
          sh 'mvn -Dmaven.test.failure.ignore clean package'
        }
      }
    }

    stage('Docker image build') {
        steps {
            container('docker') {
                IMAGE_ID = sh 'docker build .'
            }
        }
        post {
            success{
                println "Docker build complete. Image ID is ${IMAGE_ID}"
            }
            failure{
                println "Docker build failure"
            }
        }
    }

    stage('Docker testing') {
        parallel {
            stage('PR testing') {
                when { changeRequest target: 'master' }
                    steps {
                        container('docker') {
                            script{
                                sh """
                                    docker network create --driver=bridge curltest
                                    docker build -t ${DOCKERHUB_REPO}/${IMAGE}:PR-${CHANGE_ID} .
                                    docker run -d --network=curltest --name='dropw-test' ${DOCKERHUB_REPO}/${IMAGE}:PR-${CHANGE_ID}
                                """
                                HTTP_RESPONSE_CODE_1 = sh (script: 'docker run -i --net=curltest tutum/curl \
                                    /usr/bin/curl -H "Content-Type: application/json" -o /dev/null -s -w "%{http_code}" -X POST -d \'{"fullName":"Test Person","jobTitle":"Test Title"}\' http://dropw-test:8080/people', returnStdout: true).trim()
                                HTTP_RESPONSE_CODE_2 = sh (script: 'docker run -i --net=curltest tutum/curl \
                                    /usr/bin/curl -o /dev/null -I -s -w "%{http_code}" http://dropw-test:8080/hello-world', returnStdout: true).trim()
                                HTTP_RESPONSE_CODE_3 = sh (script: 'docker run -i --net=curltest tutum/curl \
                                    /usr/bin/curl -o /dev/null -I -s -w "%{http_code}" http://dropw-test:8080/people/1', returnStdout: true).trim()
                                if (!"${HTTP_RESPONSE_CODE_1}" == 200 || !"${HTTP_RESPONSE_CODE_2}" == 200 || !"${HTTP_RESPONSE_CODE_3}" == 200) {
                                    println "Raising failure status"
                                    throw new Exception("Testing failure!")
                                }
                            }
                        }
                    }
            }

            stage('Regular docker build') {
                when { not { changeRequest() } }
                environment {
                    GREETING="${IMAGE_TAG}"
                }
                    steps {
                        container('docker') {
                            script {
                                IMAGE_NAME = ("${GIT_BRANCH}"=='master') ? "${DOCKERHUB_REPO}/${IMAGE}" : "${DOCKERHUB_REPO}/${IMAGE}-${GIT_BRANCH}"
                                sh """
                                docker network create --driver=bridge curltest
                                docker build --build-arg GREETING -t ${IMAGE_NAME}:${IMAGE_TAG} .
                                docker run -d --net=curltest --name='dropw-test' ${IMAGE_NAME}:${IMAGE_TAG}
                                """
                                HTTP_RESPONSE_CODE_1 = sh (script: 'docker run -i --net=curltest tutum/curl \
                                    /usr/bin/curl -o /dev/null -I -s -w "%{http_code}" http://dropw-test:8080/hello-world', returnStdout: true).trim()
                                HTTP_RESPONSE_CODE_2 = sh (script: 'docker run -i --net=curltest tutum/curl \
                                    /usr/bin/curl -H "Content-Type: application/json" -o /dev/null -s -w "%{http_code}" -X POST -d \'{"fullName":"Test Person","jobTitle":"Test Title"}\' http://dropw-test:8080/people', returnStdout: true).trim()
                                HTTP_RESPONSE_CODE_3 = sh (script: 'docker run -i --net=curltest tutum/curl \
                                    /usr/bin/curl -o /dev/null -I -s -w "%{http_code}" http://dropw-test:8080/people/1', returnStdout: true).trim()
                                if (!"${HTTP_RESPONSE_CODE_1}" == 200 || !"${HTTP_RESPONSE_CODE_2}" == 200 || !"${HTTP_RESPONSE_CODE_3}" == 200) {
                                    println "Raising failure status"
                                    throw new Exception("Testing failure!")
                                }
                            }
                        }
                    }
                post {
                    success{
                        println "Everything is OK. Application image tag is ${GREETING}"
                    }
                    failure{
                        println "Testing is not completed:"
                        println "HTTP response for GET hello-world page is - ${HTTP_RESPONSE_CODE_1}"
                        println "HTTP response for POST test person is - ${HTTP_RESPONSE_CODE_2}"
                        println "HTTP response for GET test person - ${HTTP_RESPONSE_CODE_3}"
                    }
                }
            }
        }
    }

    stage('Docker. Push image to repository.') {
        when { not { changeRequest() } }
            steps {
                container('docker') {
//configure image tag
                    withCredentials([[$class: 'UsernamePasswordMultiBinding',
                       credentialsId: 'dockerhub',
                       usernameVariable: 'DOCKER_USER',
                       passwordVariable: 'DOCKER_PASSWORD']]) {
                           sh "docker login -u ${DOCKER_USER} -p ${DOCKER_PASSWORD} ${DOCKERHUB_SERVER}"
//move tagging image here
                           sh "docker push ${IMAGE_NAME}:${IMAGE_TAG}"
                       }
                }
            }
        failure{
            println "Error pushing docker image."
        }
    }

    stage('Lint helm chart') {
        when { not { changeRequest() } }
            steps {
                container('helm') {
                    sh """
                        helm lint ${CHART_DIR}
                    """
                }
            }
        failure{
            println "Error checking helm chart."
        }
    }

    stage('Deploy to k8s') {
        when { not { changeRequest() } }
            steps {
                container('helm') {
                    sh """
                        helm init --client-only
                    """
                    withCredentials([file(credentialsId: "${CLUSTER_KUBECONFIG}", variable: 'kubeconfig'),
                                     file(credentialsId: "${CLUSTER_CERT}", variable: 'certificate')]) {
                        sh """
                            cat $certificate > ca-fra05-devcluster.pem
                            cat $kubeconfig > kubeconfig
                            helm upgrade --install --kubeconfig kubeconfig --set image.repository=${IMAGE_NAME} --set image.tag=${IMAGE_TAG} --debug --wait ${IMAGE} ${CHART_DIR}
                        """
                    }
                }
            }
    }

  }
}
