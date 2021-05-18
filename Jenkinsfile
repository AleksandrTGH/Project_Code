properties([pipelineTriggers([githubPush()])])

pipeline {
    agent any
    environment {    
        // Git Code Checkout SCM stage
        CLASS                 = "GitSCM"
        BRANCH                = "main"
        GIT_CREDENTIALS       = "GitHub_SSH"
        GIT_URL               = "git@github.com:AleksandrTGH/Project_Code.git"
	    GIT_CONFIGURATION_URL = "git@github.com:AleksandrTGH/Project_Configuration.git"

        // Publish to S3 Bucket stage
        REGION          = "us-east-1"
        FILE            = "src/App.jar"
        BUCKET          = "dos01-bucket"
        PATH_IN_BUCKET  = "Artifact/App_${JOB_NAME}_b${BUILD_NUMBER}.jar"
        ACL             = "PublicRead"

        // Create java docker image stage
        IMAGE_NAME = "aleksandrtdh/artifacts"
        IMAGE_TAG  = "${JOB_NAME}_b${BUILD_NUMBER}"

        // Pushing image to DockerHub stage
	    DOCKER_REGISTRY_ID  = "Docker_Hub"
        DOCKER_REGISTRY_URL = "https://index.docker.io/v1/"

        // Notification to Slack stages
        CHANNEL           = "test"
        SLACK_CREDENTIALS = "Slack"

        // Blocks SlackSend
        MESSAGE_TEXT = "${JOB_NAME}_#${BUILD_NUMBER}\nDocker pull command: docker pull ${IMAGE_NAME}\nJar-file: https://${BUCKET}.s3.amazonaws.com/${PATH_IN_BUCKET}\nDeploy application?"
        YES_URL      = "${BUILD_URL}input/${STEP_ID}/proceedEmpty?"
        NO_URL       = "${BUILD_URL}input/${STEP_ID}/abort?"
        
        // Input step
        INPUT_MESSAGE = "Apply changes?"
        STEP_ID       = "Choisee"
    }

    stages {
        stage('Git Code Checkout SCM') {
            steps {
                cleanWs()
                checkout([
                    $class: "${CLASS}",
                    branches: [[name: "${BRANCH}"]],
                    userRemoteConfigs: [[
                        url: "${GIT_URL}",
                        credentialsId: "${GIT_CREDENTIALS}",
                    ]]
                ])
            }
        }

        stage('Build'){
            steps{
                sh 'mkdir lib'
                sh 'cd lib && wget https://repo1.maven.org/maven2/org/junit/platform/junit-platform-console-standalone/1.7.0/junit-platform-console-standalone-1.7.0-all.jar'
                sh 'cd src && javac -cp "../lib/junit-platform-console-standalone-1.7.0-all.jar" CarTest.java Car.java App.java'
            }
        }

        stage('Test'){
            steps{
                sh 'cd src && java -jar ../lib/junit-platform-console-standalone-1.7.0-all.jar -cp "." --select-class CarTest --reports-dir="reports"'
            }
        }

        stage('Deploy'){
            steps{
                sh 'cd src && jar cfve App.jar App *.class && java -jar App.jar' 
            }
        }

        stage("Publish to S3 Bucket") {
            steps {
                withAWS(region:"${REGION}") {
                    s3Upload(
                        file:   "${FILE}",
                        bucket: "${BUCKET}",
                        path:   "${PATH_IN_BUCKET}",
                        acl:    "${ACL}"
                    )
                }
            }
        }

        stage('Create myapp docker image') {
            steps {
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -t ${IMAGE_NAME}:latest ."
            }
        }
        
        stage('Push image to dockerhub') {
            steps {
                withDockerRegistry([
                    credentialsId: "${DOCKER_REGISTRY_ID}",
                    url: "${DOCKER_REGISTRY_URL}"
                ]) {
                    sh "docker push ${IMAGE_NAME}:${IMAGE_TAG}"
                    sh "docker push ${IMAGE_NAME}:latest"
                }
            }    
        }
        
        stage('Delete docker image') {
            steps {
                sh "docker rmi ${IMAGE_NAME}:${IMAGE_TAG}"
                sh "docker rmi ${IMAGE_NAME}:latest"
            }
        }

        stage('Notification to Slack') {
            steps {
                slackSend (
                    botUser: true, 
                    channel: "${CHANNEL}", 
                    blocks: [
                                [
			                        "type": "section",
			                        "text": [
				                        "type": "plain_text",
				                        "text": "${MESSAGE_TEXT}"
                                    ]
                                ],
                                [
			                        "type": "actions",
			                        "elements": [
                                        [
					                        "type": "button",
					                        "text": [
                                                "type": "plain_text",
						                        "text": "Yes"
                                            ],
					                        "style": "primary",
					                        "url": "${YES_URL}"
                                        ],
                                        [
					                        "type": "button",
					                        "text": [
						                        "type": "plain_text",
						                        "text": "No"
                                            ],
                                            "style": "danger",
                                            "url": "${NO_URL}"
                                        ]
                                    ]
			                    ]
                            ], 
                    tokenCredentialId: "${SLACK_CREDENTIALS}"
                )
            }
        }

        stage('Input step') {
            steps {
                input message: "${INPUT_MESSAGE}", id: "${STEP_ID}"
            }
        }

        stage('Git Configuration checkout SCM') {
            steps {
                checkout([
                    $class: "${CLASS}",
                    branches: [[name: "${BRANCH}"]],
                    userRemoteConfigs: [[
                        url: "${GIT_CONFIGURATION_URL}",
                        credentialsId: "${GIT_CREDENTIALS}",
                    ]]
                ])
            }
        }

        stage('Run ansible playbook') {
            steps {
                sh "ansible-playbook site.yml"
            }
        }
    }
}
