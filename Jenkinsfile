pipeline {
    agent any

    environment {
        DOCKER_USER = 's10shani'
        DOCKER_PASS = credentials('dockerhub-credentials')
    }

    stages {

        stage('Checkout Repos') {
            parallel {
                stage('Clone server') {
                    steps {
                        git branch: 'dev', url: 'https://github.com/shanic474/Server-FullStack-final-Project.git'
                    }
                }
                stage('Clone client') {
                    steps {
                        git branch: 'dev', url: 'https://github.com/shanic474/Client-FullStack-final-Project.git'
                    }
                }
                stage('Clone dashboard') {
                    steps {
                        git branch: 'dev', url: 'https://github.com/shanic474/Dashboard-FullStack-final-Project.git'
                    }
                }
            }
        }

        stage('Build Docker Images') {
            parallel {
                stage('Build server') {
                    steps {
                        sh 'docker build --no-cache --build-arg APP_NAME=server --build-arg APP_TYPE=backend -t s10shani/server-app:latest -f Dockerfile ./server'
                    }
                }
                stage('Build client') {
                    steps {
                        sh 'docker build --no-cache --build-arg APP_NAME=client --build-arg APP_TYPE=frontend -t s10shani/client-app:latest -f Dockerfile ./client'
                    }
                }
                stage('Build dashboard') {
                    steps {
                        sh 'docker build --no-cache --build-arg APP_NAME=dashboard --build-arg APP_TYPE=frontend -t s10shani/dashboard-app:latest -f Dockerfile ./dashboard'
                    }
                }
            }
        }

        stage('Push Docker Images') {
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

        stage('Deploy Apps') {
            parallel {
                stage('Deploy Server') {
                    steps {
                        retry(3) {
                            sh '''
                            kubectl apply -f proj2-deployment-server.yaml
                            kubectl apply -f proj2-service-server.yaml
                            '''
                        }
                    }
                }
                stage('Deploy Client') {
                    steps {
                        retry(3) {
                            sh '''
                            kubectl apply -f proj2-deployment-client.yaml
                            kubectl apply -f proj2-service-client.yaml
                            '''
                        }
                    }
                }
                stage('Deploy Dashboard') {
                    steps {
                        retry(3) {
                            sh '''
                            kubectl apply -f proj2-deployment-dashboard.yaml
                            kubectl apply -f proj2-service-dashboard.yaml
                            '''
                        }
                    }
                }
            }
        }

    }

    post {
        failure {
            echo 'Pipeline failed!'
        }
        success {
            echo 'Pipeline completed successfully!'
        }
    }
}
