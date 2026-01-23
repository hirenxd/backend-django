pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
        ACCOUNT_ID = "628253046406"
        ECR_REPO   = "diary-backend"
        ASG_NAME   = "diary-public-asg"
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
                    sh 'aws sts get-caller-identity'
                }
            }
        }


        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonarqube') {
                    sh '''
                    sonar-scanner \
                      -Dsonar.projectKey=diary-backend \
                      -Dsonar.projectName=diary-backend \
                      -Dsonar.sources=. \
                      -Dsonar.python.version=3.12
                    '''
                }
            }
        }

        
        
        stage('Build Docker Image') {
            steps {
                sh '''
                docker build -t ${ECR_REPO}:${IMAGE_TAG} .
                '''
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

        /* ------------------------------------------------------- */
        /* CRITICAL GUARD: WAIT FOR EXISTING INSTANCE REFRESH       */
        /* ------------------------------------------------------- */
        stage('Wait for Existing Instance Refresh') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-creds',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh '''
                    echo "Checking for existing instance refresh..."

                    while true; do
                      COUNT=$(aws autoscaling describe-instance-refreshes \
                        --auto-scaling-group-name ${ASG_NAME} \
                        --query "InstanceRefreshes[?Status=='InProgress'] | length(@)" \
                        --output text)

                      if [ "$COUNT" = "0" ]; then
                        echo "No instance refresh in progress."
                        break
                      fi

                      echo "Instance refresh still running. Waiting..."
                      sleep 30
                    done
                    '''
                }
            }
        }

        /* ------------------------------------------------------- */
        /* SCALE UP TO CREATE DEPLOYMENT BUFFER                    */
        /* ------------------------------------------------------- */
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
                    echo "Scaling ASG to desired capacity = 2"
                    aws autoscaling update-auto-scaling-group \
                      --auto-scaling-group-name ${ASG_NAME} \
                      --desired-capacity 2

                    echo "Waiting for 2 InService instances..."
                    MAX_WAIT=600
                    ELAPSED=0

                    while true; do
                      COUNT=$(aws autoscaling describe-auto-scaling-groups \
                        --auto-scaling-group-names ${ASG_NAME} \
                        --query "AutoScalingGroups[0].Instances[?LifecycleState=='InService'] | length(@)" \
                        --output text)

                      echo "InService instances: $COUNT"

                      if [ "$COUNT" -ge 2 ]; then
                        echo "Deployment buffer ready."
                        break
                      fi

                      sleep 15
                      ELAPSED=$((ELAPSED+15))

                      if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
                        echo "Timeout waiting for ASG scale-up"
                        exit 1
                      fi
                    done
                    '''
                }
            }
        }

        /* ------------------------------------------------------- */
        /* START INSTANCE REFRESH (ACTUAL DEPLOYMENT)              */
        /* ------------------------------------------------------- */
        stage('Deploy via ASG Instance Refresh') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-creds',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh '''
                    aws autoscaling start-instance-refresh \
                      --auto-scaling-group-name ${ASG_NAME} \
                      --strategy Rolling
                    '''
                }
            }
        }

        /* ------------------------------------------------------- */
        /* WAIT FOR DEPLOYMENT TO FINISH                           */
        /* ------------------------------------------------------- */
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
                    MAX_WAIT=1800
                    ELAPSED=0

                    while true; do
                      STATUS=$(aws autoscaling describe-instance-refreshes \
                        --auto-scaling-group-name ${ASG_NAME} \
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
                      ELAPSED=$((ELAPSED+30))

                      if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
                        echo "Timeout waiting for instance refresh"
                        exit 1
                      fi
                    done
                    '''
                }
            }
        }

        /* ------------------------------------------------------- */
        /* SCALE BACK TO NORMAL                                    */
        /* ------------------------------------------------------- */
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
            echo "CI/CD pipeline completed successfully."
    
            slackSend(
                channel: '#jenkins-builds',
                color: 'good',
                message: "SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER} deployed successfully"
            )
        }
    
        failure {
            echo "CI/CD pipeline failed. Check logs."
    
            slackSend(
                channel: '#jenkins-builds',
                color: 'danger',
                message: "FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER} – check Jenkins logs"
            )
        }
    }

}
