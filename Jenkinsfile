pipeline {
    agent any

    environment {
        DOCKERHUB_CREDS = credentials('dockerhub-credentials')
        DOCKER_USER = 's10shani'
    }

    stages {

        stage('Clean Workspace') {
            steps {
                deleteDir()
            }
        }

        stage('Checkout Pipeline Repo') {
            steps {
                checkout scm
            }
        }

        stage('Clone Application Repositories') {
            parallel {

                stage('Clone Server') {
                    steps {
                        dir('Server-FullStack-final-Project') {
                            git branch: 'main',
                                url: 'https://github.com/shanic474/Server-FullStack-final-Project.git'
                        }
                    }
                }

                stage('Clone Client') {
                    steps {
                        dir('Client-FullStack-final-Project') {
                            git branch: 'main',
                                url: 'https://github.com/shanic474/Client-FullStack-final-Project.git'
                        }
                    }
                }

                stage('Clone Dashboard') {
                    steps {
                        dir('Dashboard-FullStack-final-Project') {
                            git branch: 'dev',
                                url: 'https://github.com/shanic474/Dashboard-FullStack-final-Project.git'
                        }
                    }
                }
            }
        }

        stage('Build Docker Images') {
            parallel {

                stage('Build Server Image') {
                    steps {
                        dir('Server-FullStack-final-Project') {
                            sh 'docker build -t s10shani/server-app:latest .'
                        }
                    }
                }

                stage('Build Client Image') {
                    steps {
                        dir('Client-FullStack-final-Project') {
                            sh 'docker build -t s10shani/client-app:latest .'
                        }
                    }
                }

                stage('Build Dashboard Image') {
                    steps {
                        dir('Dashboard-FullStack-final-Project') {
                            sh 'docker build -t s10shani/dashboard-app:latest .'
                        }
                    }
                }
            }
        }

        stage('Push Images to Docker Hub') {
            steps {
                sh '''
                    echo "$DOCKERHUB_CREDS_PSW" | docker login -u "$DOCKERHUB_CREDS_USR" --password-stdin

                    docker push s10shani/server-app:latest
                    docker push s10shani/client-app:latest
                    docker push s10shani/dashboard-app:latest
                '''
            }
        }

        stage('Deploy to Kubernetes') {
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
        success {
            echo '✅ Pipeline completed successfully'
        }
        failure {
            echo '❌ Pipeline failed'
        }
    }
}
