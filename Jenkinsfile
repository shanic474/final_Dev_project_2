pipeline {
    agent any

    environment {
        APP_SERVER = 's10shani/server-app'
        APP_CLIENT = 's10shani/client-app'
        APP_DASHBOARD = 's10shani/dashboard-app'
        TAG = 'latest'
    }

    stages {

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
                        sh 'docker build --no-cache --build-arg APP_NAME=server --build-arg APP_TYPE=backend -t $APP_SERVER:$TAG -f Dockerfile ./server'
                    }
                }
                stage('Build client') {
                    steps {
                        sh 'docker build --no-cache --build-arg APP_NAME=client --build-arg APP_TYPE=frontend -t $APP_CLIENT:$TAG -f Dockerfile ./client'
                    }
                }
                stage('Build dashboard') {
                    steps {
                        sh 'docker build --no-cache --build-arg APP_NAME=dashboard --build-arg APP_TYPE=frontend -t $APP_DASHBOARD:$TAG -f Dockerfile ./dashboard'
                    }
                }
            }
        }

        stage('Tag & Push Docker Images') {
            steps {
                // כאן משתמשים ב-usernamePassword עבור Docker Hub
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                        docker push $APP_SERVER:$TAG
                        docker push $APP_CLIENT:$TAG
                        docker push $APP_DASHBOARD:$TAG
                    '''
                }
            }
        }

        stage('Deploy Apps with Wait & Retry') {
            parallel {
                stage('Deploy Server') {
                    steps {
                        retry(3) {
                            sh './deploy-server.sh'
                        }
                    }
                }
                stage('Deploy Client') {
                    steps {
                        retry(3) {
                            sh './deploy-client.sh'
                        }
                    }
                }
                stage('Deploy Dashboard') {
                    steps {
                        retry(3) {
                            sh './deploy-dashboard.sh'
                        }
                    }
                }
            }
        }
    }
}
