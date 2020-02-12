// daimler-wltp-sim-jenkins

pipeline {

  // Installed plugins:
  // Console debugging
  // - timestamps
  // GitHub intergation
  // - Pipeline: GitHub
  // - GitHub
  // - GitHub API
  // - GitHub Branch Source
  // Trigger by tag
  // - Multibranch build strategy extension
  // - Basic Branch Build Strategies Plugin <-

  // triggers {
  //   pollSCM( (BRANCH_NAME == 'master' || BRANCH_NAME == 'develop') ? '* * * * *' : '') /* default: poll once a minute */
  // }
  triggers {
    pollSCM('* * * * *') /* default: poll once a minute */
  }

  options {
    buildDiscarder(logRotator(numToKeepStr: '5', artifactNumToKeepStr: '5'))
    // timestamps()
  }

  environment {
    // Note: When empty the environment variable will not exists! Mind error handling.
    CICD_TAGS_NAME = "${TAG_NAME ? TAG_NAME : 'None'}"

    // GIT environment variables
    GIT_COMMIT_SHORT = sh(returnStdout: true, script: 'git rev-parse HEAD').trim().take(8)
    GIT_AUTHOR_NAME = sh(returnStdout: true, script: 'git show -s --pretty=%an').trim()

    // Jenkins environment variables
    JENKINS_PATH = sh(script: 'pwd', , returnStdout: true).trim()

    // Pre-load vriable from source control
    PREP_LOAD_ENV = sh(returnStdout: false, script: "${JENKINS_PATH}/build/config/_confConvert.sh ${CICD_TAGS_NAME} ${GIT_COMMIT_SHORT} > /dev/null 2>&1")
  }

  // Any
  agent any

  // CrossLogic
  // agent {
  //   label 'docker'
  // }

  // Kubernetes
  // agent {
  //   kubernetes {
  //     label 'jenkins-slave'
  //     cloud 'kubernetes'
  //     defaultContainer 'jnlp'
  //     instanceCap 1
  //     yamlFile "build/k8/build-pod-dind.yml"
  //   }
  // }

  // Notes
  // Branches should run otherwise tags get orphaned
  //master|develop|PR-.*|refs\/tags\/.*
  // Filter by name (with regular expression): master|develop|PR-.*|.*tags.*|feature.*|.*RELEASE OR ^((?!master).)*$|^((?!develop).)*$
  // when { tag "release-*" }
  // when { not { branch 'master' } }
  // when { branch "feature/*" }
  // when { changeRequest() }.
  // https://jenkins.io/doc/book/pipeline/syntax/#when
  stages {
    stage ('Prepare generic environment') {
      steps {
        sh 'echo "Version/Hash requested: ${CICD_TAGS_NAME}/${GIT_COMMIT_SHORT}"'

        // environvironment only has to be loaded once
        load "$JENKINS_PATH/build/config/env.files/generic.groovy"
        load "$JENKINS_PATH/build/config/env.files/tag_env.groovy"
      }
    }
    stage ('Prepare build only') {
      when {
        buildingTag()
        environment name: 'CICD_TAGS_DEPLOY_ENVIRONMENT', value: 'build'
      }
      steps {
        sh 'echo "build env stage reached"'
        load "$JENKINS_PATH/build/config/env.files/build.groovy"
      }
    }
    stage ('Prepare deploy') {
      when {
        buildingTag()
        not { environment name: 'CICD_TAGS_DEPLOY_ENVIRONMENT', value: 'build' }
      }
      steps {
        sh 'echo "deploy env stage reached"'
        load "$JENKINS_PATH/build/config/env.files/deploy_${CICD_TAGS_DEPLOY_ENVIRONMENT}.groovy"
      }
    }
    stage ('Prepare PR') {
      when { changeRequest() }
      steps {
        sh 'echo "PR env stage reached"'
        load "$JENKINS_PATH/build/config/env.files/pr.groovy"
        load "$JENKINS_PATH/build/config/env.files/deploy_${CICD_TAGS_DEPLOY_ENVIRONMENT}.groovy"
      }
    }
    stage ('Build Image') {
      when {
        environment name: 'CICD_BUILD_ENABLED', value: '1'
      }
      steps {
        // container ('dind') {
          sh 'echo "Build stage. Building image for ${APP_NAME} version ${CICD_TAGS_ID}."'

          dir ("${CICD_BUILD_PATH}") {
            script {
              dockerImage = docker.build("${CICD_REGISTRY}/${APP_NAME}:${CICD_TAGS_ID}", "-f ${CICD_BUILD_FILE} .")
            }
          }
        // }
      }
    }
    stage ('Push Image') {
      when {
        environment name: 'CICD_BUILD_ENABLED', value: '1'
      }
      steps {   
        // container ('dind') {
          script {
            docker.withRegistry( "${CICD_REGISTRY_URL}", "${CICD_REGISTRY_CREDENTIALS}" ) {
              dockerImage.push()
            }
          }
        // }
      }
    }
    stage ('Show Env Build Temp') {
      when {
        environment name: 'CICD_BUILD_ENABLED', value: '1'
      }
    // dockerRegistry = "${ALT_DOCKER_REGISTRY}"
    // dockerPath = 'build/transmission'
    // dockerFile = 'Dockerfile'
    // imageGroup = ''
    // imageName = 'transmission'
    // imageVersion = '2.1'
    // imagePath = "${imageGroup}${imageName}"
    // buildTag = "${GIT_COMMIT}-b${BUILD_NUMBER}"
    // versionTag = "${imageVersion}-b${BUILD_NUMBER}"

      steps {
        sh 'echo Build'
        sh 'echo -----------------------------------------------------------------'
        sh 'echo "Print all environment variable"'
        sh 'printenv | sort'
      }
    }
    stage ('Deployment') {
      when {
        environment name: 'CICD_DEPLOY_ENABLED', value: '1'
      }
      steps {
        sh 'echo "Deployed in ${CICD_TAGS_DEPLOY_ENVIRONMENT}."'
      }
    }
  }

post {
  always {
    echo 'This will always run'
  }
  success {
    echo 'This will run only if successful'
  }
  failure {
    echo 'This will run only if failed'
  }
  unstable {
    echo 'This will run only if the run was marked as unstable'
  }
  changed {
    echo 'This will run only if the state of the Pipeline has changed'
    echo 'For example, if the Pipeline was previously failing but is now successful'
  }
}



}
