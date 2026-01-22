pipeline {
    agent any

    environment {
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {

        /* ---------------- BUILD & PUSH ---------------- */

        stage('Verify AWS Access') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-creds',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh 'aws sts get-caller-identity'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t ${ECR_REPO}:${IMAGE_TAG} .'
            }
        }

        stage('Login to ECR') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-creds',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh '''
                    aws ecr get-login-password --region ${AWS_REGION} \
                      | docker login --username AWS --password-stdin \
                        ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                    '''
                }
            }
        }

        stage('Push Image to ECR') {
            steps {
                sh '''
                docker tag ${ECR_REPO}:${IMAGE_TAG} \
                  ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}

                docker tag ${ECR_REPO}:${IMAGE_TAG} \
                  ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:latest

                docker push ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}
                docker push ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:latest
                '''
            }
        }

        /* ---------------- DEPLOYMENT ---------------- */

        stage('Scale ASG Up (Deploy Buffer)') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-creds',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh '''
                    echo "Scaling ASG to desired capacity = 2 (deployment buffer)"

                    aws autoscaling update-auto-scaling-group \
                      --auto-scaling-group-name ${ASG_NAME} \
                      --desired-capacity 2

                    echo "Waiting for ASG to have 2 InService instances..."

                    while true; do
                      INSERVICE_COUNT=$(aws autoscaling describe-auto-scaling-groups \
                        --auto-scaling-group-names ${ASG_NAME} \
                        --query "AutoScalingGroups[0].Instances[?LifecycleState=='InService'] | length(@)" \
                        --output text)

                      echo "InService instances: $INSERVICE_COUNT"

                      if [ "$INSERVICE_COUNT" -ge 2 ]; then
                        echo "Deployment buffer ready."
                        break
                      fi

                      sleep 15
                    done
                    '''
                }
            }
        }

        stage('Deploy via ASG Rolling Refresh') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-creds',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh '''
                    set -e

                    REFRESH_ID=$(aws autoscaling describe-instance-refreshes \
                      --auto-scaling-group-name ${ASG_NAME} \
                      --query "InstanceRefreshes[?Status=='InProgress'].InstanceRefreshId" \
                      --output text)

                    if [ -n "$REFRESH_ID" ]; then
                      echo "Instance refresh already in progress ($REFRESH_ID). Skipping."
                      exit 0
                    fi

                    aws autoscaling start-instance-refresh \
                      --auto-scaling-group-name ${ASG_NAME} \
                      --strategy Rolling
                    '''
                }
            }
        }

        stage('Wait for Instance Refresh Completion') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-creds',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh '''
                    echo "Waiting for instance refresh to complete..."

                    while true; do
                      STATUS=$(aws autoscaling describe-instance-refreshes \
                        --auto-scaling-group-name ${ASG_NAME} \
                        --max-items 1 \
                        --query "InstanceRefreshes[0].Status" \
                        --output text)

                      echo "Current refresh status: $STATUS"

                      if [ "$STATUS" = "Successful" ]; then
                        echo "Instance refresh completed successfully."
                        break
                      fi

                      if [ "$STATUS" = "Failed" ]; then
                        echo "Instance refresh failed."
                        exit 1
                      fi

                      sleep 30
                    done
                    '''
                }
            }
        }

        stage('Scale ASG Down (Normal State)') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-creds',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh '''
                    echo "Scaling ASG back to desired capacity = 1"

                    aws autoscaling update-auto-scaling-group \
                      --auto-scaling-group-name ${ASG_NAME} \
                      --desired-capacity 1
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "CI/CD pipeline completed successfully with near-zero downtime."
        }
        failure {
            echo "CI/CD pipeline failed. Check logs."
        }
    }
}
