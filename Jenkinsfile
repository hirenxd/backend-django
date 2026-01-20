pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
        IMAGE_NAME = "backend-django"
        IMAGE_TAG  = "${BUILD_NUMBER}"
    }

    stages {

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
                    aws sts get-caller-identity
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                echo "Building Docker image..."
                docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                docker images | grep ${IMAGE_NAME}
                '''
            }
        }
    }
}

