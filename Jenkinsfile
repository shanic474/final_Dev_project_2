pipeline {
    agent any

    environment {
        DOCKER_USER = 's10shani'
        DOCKER_PASS = credentials('dockerhub-credentials')
        BUILD_NUMBER = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Clean Old Apps') {
            steps {
                sh 'rm -rf server client dashboard'
            }
        }

        stage('Clone Repos') {
            parallel {
                stage('Clone server') {
                    steps {
                        sh 'git clone --branch dev --single-branch https://github.com/shanic474/Server-FullStack-final-Project.git server'
                    }
                }
                stage('Clone client') {
                    steps {
                        sh 'git clone --branch dev --single-branch https://github.com/shanic474/Client-FullStack-final-Project.git client'
                    }
                }
                stage('Clone dashboard') {
                    steps {
                        sh 'git clone --branch dev --single-branch https://github.com/shanic474/Dashboard-FullStack-final-Project.git dashboard'
                    }
                }
            }
        }

        stage('Build Docker Images') {
            parallel {
                stage('Build server') {
                    steps {
                        sh 'docker build --no-cache --build-arg APP_TYPE=backend -t s10shani/server-app:latest -f Dockerfile ./server'
                    }
                }
                stage('Build client') {
                    steps {
                        sh 'docker build --no-cache --build-arg APP_TYPE=frontend -t s10shani/client-app:latest -f Dockerfile ./client'
                    }
                }
                stage('Build dashboard') {
                    steps {
                        sh 'docker build --no-cache --build-arg APP_TYPE=frontend -t s10shani/dashboard-app:latest -f Dockerfile ./dashboard'
                    }
                }
            }
        }

        stage('Tag & Push Docker Images') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                        docker push s10shani/server-app:latest
                        docker push s10shani/client-app:latest
                        docker push s10shani/dashboard-app:latest
                    '''
                }
            }
        }

        stage('Deploy Apps to Kubernetes') {
            steps {
                sh '''
                    kubectl apply -f proj2-deployment-server.yaml
                    kubectl apply -f proj2-service-server.yaml
                    kubectl apply -f proj2-deployment-client.yaml
                    kubectl apply -f proj2-service-client.yaml
                    kubectl apply -f proj2-deployment-dashboard.yaml
                    kubectl apply -f proj2-service-dashboard.yaml
                '''
            }
        }
    }

    post {
        always {
            echo "Pipeline finished"
        }
        success {
            echo "All apps deployed successfully!"
        }
        failure {
            echo "Pipeline failed. Check logs."
        }
    }
}
