pipeline {
  options {
    timestamps()
  }
  environment {
    DOCKERHUB_REPO = 'notregistered'
    IMAGE = 'dropw'
    VERSION = '${env.GIT_COMMIT}'
    GIT_TAG_COMMIT = sh (script: 'git describe --tags --always', returnStdout: true).trim()
  }
  agent {
    kubernetes {
      label 'mypod'
      checkout([
                    $class: 'GitSCM',
                    branches: scm.branches,
                    doGenerateSubmoduleConfigurations: false,
                    extensions: scm.extensions + [[$class: 'SubmoduleOption', disableSubmodules: false, recursiveSubmodules: true, reference: '', trackingSubmodules: false]],
                    submoduleCfg: [],
                    userRemoteConfigs: scm.userRemoteConfigs])
      yamlFile 'workerpod.yml'
    }
  }
  stages {
    stage('Run maven') {
      steps {
        container('maven') {
          sh 'mvn -Dmaven.test.failure.ignore clean package'
          sh 'printenv'
          echo '${env.GIT_TAG_COMMIT}'
        }
      }
    }
    stage('Build and Publish Image from master') {
      when {
        branch 'master'
      }
      steps {
        container('docker') {
            sh """
            docker build -t ${DOCKERHUB_REPO}/${IMAGE}:${VERSION} .
            docker push ${DOCKERHUB_REPO}/${IMAGE}:${VERSION}
            """
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
            sh """
            docker build -t ${DOCKERHUB_REPO}/${IMAGE}-${env.GIT_BRANCH}:${VERSION} .
            docker push ${DOCKERHUB_REPO}/${IMAGE}-${env.GIT_BRANCH}:${VERSION}
            """
        }
      }
    }

  }
}
