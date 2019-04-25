pipeline {
//  agent any
  environment {
        BUILDER = "builder-${UUID.randomUUID().toString()}"
  }
  // using the Timestamper plugin we can add timestamps to the console log
  options {
    timestamps()
  }
  agent {
    kubernetes {
        label "${BUILDER}"
        serviceAccount jenkins
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
//      image: dtzar/helm-kubectl
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
    stage("Build Application") {
      def scmVars = checkout scm
      steps {
        echo "building master branch"
        container('maven') {
          sh 'mvn -Dmaven.test.failure.ignore clean package'
        }
        script {
          String res = env.MAKE_RESULT
          if (res != null) {
            echo "Setting build result ${res}"
            currentBuild.result = res
          } else {
            echo "All is well"
          }
        }
      }
      // Post in Stage executes at the end of Stage instead of end of Pipeline
      post {
        aborted {
          echo "Stage 'Hello' WAS ABORTED"
        }
        always {
          echo "Stage 'Hello' finished"
        }
        changed {
          echo "Stage HAVE CHANGED"
        }
        failure {
          echo "Stage FAILED"
        }
        success {
          echo "Stage was Successful"
        }
        unstable {
          echo "Stage is Unstable"
        }
      }
    }
    stage("Build docker image") {
        when {
            branch "master"
        }
        steps {
            echo "Build docker image"
            sh 'docker build -t notregistered/${scmVars.GIT_BRANCH} .'
            sh 'printenv'
        }
    }
  }

  // All Stages and Pipeline can each have their own post section that is executed at different times
  post {
    always {
      echo "Pipeline is done"
    }
  }
}

