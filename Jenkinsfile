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
        label ${BUILDER}
        podTemplate {
            serviceAccountName: jenkins
            volumes {
                Volume(Name: 'dind-storage', emtyDir: {})
            }
            containerTemplate {
                name 'docker'
                image 'docker:latest'
                ttyEnabled true
                command 'cat'
                envVars: [
                    containerEnvVar(key: 'DOCKER_HOST', value: 'tcp://localhost:2375')
//                  containerEnvVar(key: 'POD_IP', valueFrom: (fieldRef: (fieldPath: ${status.podIP})))
                ]
            }
            containerTemplate {
                name 'maven'
                image 'maven:latest'
                ttyEnabled true
                command 'cat'
            }
            containerTemplate {
                name 'dind'
                image 'docker:18.05-dind'
                ttyEnabled true
                privieged true
                command 'cat'
            }
        }
    }
  }
  stages {
/*    stage("Preparation") {
        steps {
            echo "Stage Preparation"
        }
    }*/
    stage("Build Application") {
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
            sh 'docker build -t notregistered/${$GIT_BRANCH} .'
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

