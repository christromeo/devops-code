pipeline {
    agent any

    environment {
        KUBE_CONFIG = credentials('id')
        APP_NAME = 'legal-api'
        HELM_CHART_PATH = '.helm/'
        PYTHON_VERSION = '3.11'
        POETRY_VERSION = '1.6.1'
        ECR_REGISTRY = 'your-ecr-registry-url'
        AWS_DEFAULT_REGION = 'your-aws-region'
        DOCKER_IMAGE_NAME = 'legalterm'
        DOCKERFILE_PATH = './legal-term/Dockerfile'
        ECR_CERDENTIALS_ID = credentials('id')
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    checkout scm
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                script {
                    // Install Python and Poetry
                    sh """
                        pyenv install ${PYTHON_VERSION}
                        pyenv global ${PYTHON_VERSION}
                        pip install poetry==${POETRY_VERSION}
                    """
                    
                    // Install project dependencies using poetry
                    sh "poetry install"
                }
            }
        }

        stage('Unit Tests') {
            steps {
                script {
                    // Run unit tests using poetry
                    sh "poetry run pytest tests/"
                }
            }
        }

        stage('Integration Tests') {
            steps {
                script {
                    // Run integration tests using poetry
                    sh "poetry run pytest tests/test_loading.py::test_json_loading"
                }
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                script {
                    // Login to ECR
                    withCredentials([string(credentialsId: ${ECR_CERDENTIALS_ID}, variable: 'AWS_ECR_CREDENTIALS')]) {
                        sh """
                            aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                        """
                    }

                    // Build and tag the Docker image
                    sh """
                        docker build -t ${DOCKER_IMAGE_NAME} -f ${DOCKERFILE_PATH} .
                        docker tag ${DOCKER_IMAGE_NAME} ${ECR_REGISTRY}/${DOCKER_IMAGE_NAME}
                    """

                    // Push the Docker image to ECR
                    sh "docker push ${ECR_REGISTRY}/${DOCKER_IMAGE_NAME}"
                }
            }
        }

        stage('Helm Deploy') {
            steps {
                script {
                    // Install Helm
                    sh """
                        curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
                        chmod +x get_helm.sh
                        ./get_helm.sh
                    """

                    // Deploy Helm chart
                    sh """
                        helm upgrade --install ${APP_NAME} ${env.HELM_CHART_PATH} --set image.tag=${DOCKER_IMAGE_NAME} --namespace your-namespace
                    """
                }
            }
        }
    }

    post {
        always {
            // archive test results
            junit 'legal-term/tests/reports/**/*.xml'
        }
    }
}