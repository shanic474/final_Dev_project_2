pipeline {
    agent any

    environment {
        DOCKERHUB_USER = "s10shani"
        DOCKERHUB_CREDENTIALS = credentials("dockerhub-credentials")
        KUBECONFIG = "/home/jenkins/.kube/config"  // adjust if needed
        BUILD_NUMBER = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout([$class: 'GitSCM',
                          branches: [[name: 'main']],
                          userRemoteConfigs: [[url: 'https://github.com/shanic474/final_Dev_project_2.git']]])
            }
        }

        stage('Clean Old Apps') {
            steps {
                sh 'rm -rf server client dashboard'
            }
        }

        stage('Load Apps Config') {
            steps {
                script {
                    // Define apps array (adjust docker_image, node_port as needed)
                    def apps = [
                        [name: "server", type: "backend", docker_image: "${DOCKERHUB_USER}/server-app", git_url: "https://github.com/shanic474/Server-FullStack-final-Project.git", branch: "dev", k3s_deployment: "proj2-deployment.yaml", k3s_service: "proj2-service.yaml", node_port: 30001],
                        [name: "client", type: "frontend", docker_image: "${DOCKERHUB_USER}/client-app", git_url: "https://github.com/shanic474/Client-FullStack-final-Project.git", branch: "dev", k3s_deployment: "proj2-deployment.yaml", k3s_service: "proj2-service.yaml", node_port: 30002],
                        [name: "dashboard", type: "frontend", docker_image: "${DOCKERHUB_USER}/dashboard-app", git_url: "https://github.com/shanic474/Dashboard-FullStack-final-Project.git", branch: "dev", k3s_deployment: "proj2-deployment.yaml", k3s_service: "proj2-service.yaml", node_port: 30003]
                    ]
                    env.APPS = apps
                }
            }
        }

        stage('Build, Push, Deploy Apps in Parallel') {
            steps {
                script {
                    // Define apps array directly here
                    def apps = [
                        [name: "server", type: "backend", docker_image: "s10shani/server-app", git_url: "https://github.com/shanic474/Server-FullStack-final-Project.git", branch: "dev", k3s_deployment: "proj2-deployment.yaml", k3s_service: "proj2-service.yaml", node_port: 30001],
                        [name: "client", type: "frontend", docker_image: "s10shani/client-app", git_url: "https://github.com/shanic474/Client-FullStack-final-Project.git", branch: "dev", k3s_deployment: "proj2-deployment.yaml", k3s_service: "proj2-service.yaml", node_port: 30002],
                        [name: "dashboard", type: "frontend", docker_image: "s10shani/dashboard-app", git_url: "https://github.com/shanic474/Dashboard-FullStack-final-Project.git", branch: "dev", k3s_deployment: "proj2-deployment.yaml", k3s_service: "proj2-service.yaml", node_port: 30003]
                    ]
        
                    def branches = [:]
        
                    for (app in apps) {
                        def appCopy = app
                        branches[appCopy.name] = {
                            stage("Clone ${appCopy.name}") {
                                sh "git clone --branch ${appCopy.branch} --single-branch ${appCopy.git_url} ${appCopy.name}"
                            }
        
                            stage("Build Docker ${appCopy.name}") {
                                sh "docker build --no-cache --build-arg APP_NAME=${appCopy.name} --build-arg APP_TYPE=${appCopy.type} -t ${appCopy.docker_image}:latest -f Dockerfile ./${appCopy.name}"
                            }
        
                            stage("Tag Docker ${appCopy.name}") {
                                sh "docker tag ${appCopy.docker_image}:latest ${appCopy.docker_image}:${BUILD_NUMBER}"
                            }
        
                            stage("Push Docker ${appCopy.name}") {
                                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                                    sh "echo $PASS | docker login -u $USER --password-stdin && docker push ${appCopy.docker_image}:${BUILD_NUMBER}"
                                }
                            }
        
                            stage("Deploy ${appCopy.name}") {
                                def tempDeployment = "temp-${appCopy.name}-deployment.yaml"
                                def tempService = "temp-${appCopy.name}-service.yaml"
        
                                sh """
                                    cp ${appCopy.k3s_deployment} ${tempDeployment}
                                    cp ${appCopy.k3s_service} ${tempService}
                                    sed -i "s|\\\${APP_NAME}|${appCopy.name}|g" ${tempDeployment} ${tempService}
                                    sed -i "s|\\\${DOCKER_IMAGE}:${BUILD_NUMBER}|${appCopy.docker_image}:${BUILD_NUMBER}|g" ${tempDeployment}
                                    sed -i "s|\\\${NODE_PORT}|${appCopy.node_port}|g" ${tempService}
                                    kubectl --kubeconfig=${KUBECONFIG} apply -f ${tempDeployment}
                                    kubectl --kubeconfig=${KUBECONFIG} apply -f ${tempService}
                                    kubectl --kubeconfig=${KUBECONFIG} rollout restart deployment ${appCopy.name}-deployment
                                """
                            }
                        }
                    }
        
                    parallel branches
                }
            }
        }
    }

    post {
        always {
            sh 'docker logout'
        }
    }
}
