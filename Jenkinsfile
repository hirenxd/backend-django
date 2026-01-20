pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
        IMAGE_NAME = "backend-django"
        IMAGE_TAG  = "${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Verify AWS Access') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-creds',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh '''
                    echo "Verifying AWS identity..."
                    aws sts get-caller-identity
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                echo "Building Docker image in CI-friendly mode..."

                export DOCKER_BUILDKIT=1

                docker build \
                  --progress=plain \
                  -t ${IMAGE_NAME}:${IMAGE_TAG} .

                echo "Built images:"
                docker images | grep ${IMAGE_NAME}
                '''
            }
        }
    }

    post {
        success {
            echo "CI pipeline completed successfully."
        }
        failure {
            echo "CI pipeline failed. Check logs above."
        }
    }
}
