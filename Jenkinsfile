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
            when {
                expression {
                    env.BRANCH_NAME == 'main' ||
                    env.GIT_BRANCH == 'origin/main' ||
                    env.GIT_BRANCH == 'main'
                }
            }
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
                      -Dsonar.python.version=3.12 \
                      ${CHANGE_ID:+-Dsonar.pullrequest.key=$CHANGE_ID} \
                      ${CHANGE_ID:+-Dsonar.pullrequest.branch=$CHANGE_BRANCH} \
                      ${CHANGE_ID:+-Dsonar.pullrequest.base=$CHANGE_TARGET}
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build Docker Image') {
            when {
                expression {
                    env.BRANCH_NAME == 'main' ||
                    env.GIT_BRANCH == 'origin/main' ||
                    env.GIT_BRANCH == 'main'
                }
            }
            steps {
                sh '''
                docker build -t ${ECR_REPO}:${IMAGE_TAG} .
                '''
            }
        }

        stage('Login to ECR') {
            when {
                expression {
                    env.BRANCH_NAME == 'main' ||
                    env.GIT_BRANCH == 'origin/main' ||
                    env.GIT_BRANCH == 'main'
                }
            }
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
            when {
                expression {
                    env.BRANCH_NAME == 'main' ||
                    env.GIT_BRANCH == 'origin/main' ||
                    env.GIT_BRANCH == 'main'
                }
            }
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

        stage('Wait for Existing Instance Refresh') {
            when {
                expression {
                    env.BRANCH_NAME == 'main' ||
                    env.GIT_BRANCH == 'origin/main' ||
                    env.GIT_BRANCH == 'main'
                }
            }
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

        stage('Scale ASG Up (Deploy Buffer)') {
            when {
                expression {
                    env.BRANCH_NAME == 'main' ||
                    env.GIT_BRANCH == 'origin/main' ||
                    env.GIT_BRANCH == 'main'
                }
            }
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

        stage('Deploy via ASG Instance Refresh') {
            when {
                expression {
                    env.BRANCH_NAME == 'main' ||
                    env.GIT_BRANCH == 'origin/main' ||
                    env.GIT_BRANCH == 'main'
                }
            }
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

        stage('Wait for Instance Refresh Completion') {
            when {
                expression {
                    env.BRANCH_NAME == 'main' ||
                    env.GIT_BRANCH == 'origin/main' ||
                    env.GIT_BRANCH == 'main'
                }
            }
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

        stage('Scale ASG Down (Normal State)') {
            when {
                expression {
                    env.BRANCH_NAME == 'main' ||
                    env.GIT_BRANCH == 'origin/main' ||
                    env.GIT_BRANCH == 'main'
                }
            }
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
            script {
                slackSend(channel: '#jenkins-builds', color: 'good',
                          message: "SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER} deployed successfully")

                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-creds',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh '''
                    echo "Saving last known good image version..."
                    aws ssm put-parameter \
                    --name "/diary/last-good-image" \
                    --value "${IMAGE_TAG}" \
                    --type String \
                    --region ${AWS_REGION} \
                    --overwrite
                    '''
                }
            }
        }
        failure {
            slackSend(channel: '#jenkins-builds', color: 'danger',
                    message: "FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER} – initiating rollback")

            withCredentials([
                usernamePassword(
                    credentialsId: 'aws-creds',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )
            ]) {
                sh '''
                echo "Deployment failed. Starting automated rollback..."

                PREVIOUS_TAG=$(aws ssm get-parameter \
                --name "/diary/last-good-image" \
                --region ${AWS_REGION} \
                --query Parameter.Value \
                --output text 2>/dev/null)

                if [ -z "$PREVIOUS_TAG" ]; then
                    echo "No previous stable version found. Rollback aborted."
                    exit 0
                fi

                echo "Rolling back to last known good image: $PREVIOUS_TAG"

                LT_ID=$(aws autoscaling describe-auto-scaling-groups \
                --auto-scaling-group-names ${ASG_NAME} \
                --region ${AWS_REGION} \
                --query "AutoScalingGroups[0].LaunchTemplate.LaunchTemplateId" \
                --output text)

                CURRENT_USER_DATA=$(aws ec2 describe-launch-template-versions \
                --launch-template-id $LT_ID \
                --region ${AWS_REGION} \
                --versions '$Latest' \
                --query 'LaunchTemplateVersions[0].LaunchTemplateData.UserData' \
                --output text | base64 -d)

                NEW_USER_DATA=$(echo "$CURRENT_USER_DATA" | sed "s|:${IMAGE_TAG}|:$PREVIOUS_TAG|g" | base64 -w 0)

                aws ec2 create-launch-template-version \
                --launch-template-id $LT_ID \
                --region ${AWS_REGION} \
                --source-version '$Latest' \
                --launch-template-data "{\"UserData\":\"$NEW_USER_DATA\"}"

                aws autoscaling start-instance-refresh \
                --auto-scaling-group-name ${ASG_NAME} \
                --region ${AWS_REGION}

                echo "Rollback instance refresh started with image tag: $PREVIOUS_TAG"
                '''
            }
        }

    }
}
