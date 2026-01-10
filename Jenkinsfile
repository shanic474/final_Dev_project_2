pipeline {
    agent any

    environment {
        DOCKER_USER = 's10shani'
        DOCKER_PASS = credentials('dockerhub-credentials')
        KUBECONFIG = '/var/lib/jenkins/.kube/config' // צריך kubeconfig עם הרשאות
    }

    stages {

        stage('Clean Old Apps') {
            steps { sh 'rm -rf server client dashboard' }
        }

        stage('Clone Repos') {
            parallel {
                stage('Clone server') { steps { sh 'git clone --branch dev --single-branch https://github.com/shanic474/Server-FullStack-final-Project.git server' } }
                stage('Clone client') { steps { sh 'git clone --branch dev --single-branch https://github.com/shanic474/Client-FullStack-final-Project.git client' } }
                stage('Clone dashboard') { steps { sh 'git clone --branch dev --single-branch https://github.com/shanic474/Dashboard-FullStack-final-Project.git dashboard' } }
            }
        }

        stage('Build Docker Images') {
            parallel {
                stage('Build server') { steps { sh 'docker build --no-cache --build-arg APP_NAME=server --build-arg APP_TYPE=backend -t s10shani/server-app:latest -f Dockerfile ./server' } }
                stage('Build client') { steps { sh 'docker build --no-cache --build-arg APP_NAME=client --build-arg APP_TYPE=frontend -t s10shani/client-app:latest -f Dockerfile ./client' } }
                stage('Build dashboard') { steps { sh 'docker build --no-cache --build-arg APP_NAME=dashboard --build-arg APP_TYPE=frontend -t s10shani/dashboard-app:latest -f Dockerfile ./dashboard' } }
            }
        }

        stage('Tag & Push Docker Images') {
            steps {
                withCredentials([string(credentialsId: 'dockerhub-credentials', variable: 'DOCKER_PASS')]) {
                    sh '''
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                        docker tag s10shani/server-app:latest s10shani/server-app:20
                        docker tag s10shani/client-app:latest s10shani/client-app:20
                        docker tag s10shani/dashboard-app:latest s10shani/dashboard-app:20
                        docker push s10shani/server-app:20
                        docker push s10shani/client-app:20
                        docker push s10shani/dashboard-app:20
                    '''
                }
            }
        }

        stage('Deploy Apps in Parallel') {
            parallel {
                stage('Deploy Server') {
                    steps {
                        script {
                            sh 'cp proj2-deployment.yaml temp-server-deployment.yaml'
                            sh 'cp proj2-service.yaml temp-server-service.yaml'
                            sh 'sed -i s|\\${APP_NAME}|server|g temp-server-deployment.yaml temp-server-service.yaml'
                            sh 'sed -i s|\\${APP_IMAGE}|s10shani/server-app:20|g temp-server-deployment.yaml'
                            sh 'sed -i s|\\${NODE_PORT}|30001|g temp-server-service.yaml'

                            // Retry ל-server
                            retry(3) {
                                sh '''
                                    kubectl --kubeconfig=$KUBECONFIG apply -f temp-server-deployment.yaml --validate=false
                                    kubectl --kubeconfig=$KUBECONFIG rollout status deployment server-deployment --timeout=120s
                                '''
                            }
                        }
                    }
                }

                stage('Deploy Client') {
                    steps {
                        script {
                            // מחכה ל-server להיות מוכן
                            retry(3) {
                                sh 'kubectl --kubeconfig=$KUBECONFIG rollout status deployment server-deployment --timeout=120s || exit 1'
                            }

                            sh 'cp proj2-deployment.yaml temp-client-deployment.yaml'
                            sh 'cp proj2-service.yaml temp-client-service.yaml'
                            sh 'sed -i s|\\${APP_NAME}|client|g temp-client-deployment.yaml temp-client-service.yaml'
                            sh 'sed -i s|\\${APP_IMAGE}|s10shani/client-app:20|g temp-client-deployment.yaml'
                            sh 'sed -i s|\\${NODE_PORT}|30002|g temp-client-service.yaml'

                            // Retry ל-client
                            retry(3) {
                                sh 'kubectl --kubeconfig=$KUBECONFIG apply -f temp-client-deployment.yaml --validate=false'
                            }
                        }
                    }
                }

                stage('Deploy Dashboard') {
                    steps {
                        script {
                            // מחכה ל-server להיות מוכן
                            retry(3) {
                                sh 'kubectl --kubeconfig=$KUBECONFIG rollout status deployment server-deployment --timeout=120s || exit 1'
                            }

                            sh 'cp proj2-deployment.yaml temp-dashboard-deployment.yaml'
                            sh 'cp proj2-service.yaml temp-dashboard-service.yaml'
                            sh 'sed -i s|\\${APP_NAME}|dashboard|g temp-dashboard-deployment.yaml temp-dashboard-service.yaml'
                            sh 'sed -i s|\\${APP_IMAGE}|s10shani/dashboard-app:20|g temp-dashboard-deployment.yaml'
                            sh 'sed -i s|\\${NODE_PORT}|30003|g temp-dashboard-service.yaml'

                            // Retry ל-dashboard
                            retry(3) {
                                sh 'kubectl --kubeconfig=$KUBECONFIG apply -f temp-dashboard-deployment.yaml --validate=false'
                            }
                        }
                    }
                }
            }
        }

    }
}
