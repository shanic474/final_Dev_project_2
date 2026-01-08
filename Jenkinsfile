pipeline {
    agent any
    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        KUBECONFIG = "/etc/rancher/k3s/k3s.yaml"
    }

    stages {
        stage('Clean Old Apps') {
            steps {
                sh 'rm -rf server dashboard client'  // remove old cloned app repos
            }
        }

        stage('Load Apps Config') {
            steps {
                script { 
                    def apps = readJSON file: 'apps.json'
                    // save to env so we can use later
                    env.APPS_JSON = groovy.json.JsonOutput.toJson(apps)
                }
            }
        }

        stage('Build, Push, Deploy Apps in Parallel') {
            steps {
                script {
                    def apps = new groovy.json.JsonSlurper().parseText(env.APPS_JSON)
                    def branches = [:]

                    apps.each { app ->
                        branches[app.name] = {
                            stage("Clone ${app.name}") {
                                sh "git clone --branch ${app.branch} --single-branch ${app.git_url} ${app.name}"
                            }

                            stage("Build Docker ${app.name}") {
                                sh """
                                    docker build \
                                        --no-cache \
                                        --build-arg APP_NAME=${app.name} \
                                        --build-arg APP_TYPE=${app.app_type} \
                                        -t ${app.docker_image}:latest \
                                        -f Dockerfile ./${app.name}
                                """
                            }

                            stage("Tag Docker ${app.name}") {
                                sh "docker tag ${app.docker_image}:latest ${app.docker_image}:${BUILD_NUMBER}"
                            }

                            stage("Push Docker ${app.name}") {
                                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                                    sh "echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin && docker push ${app.docker_image}:${BUILD_NUMBER}"
                                }
                            }

                            stage("Deploy ${app.name}") {
                                script {
                                    def tempDeployment = "temp-${app.name}-deployment.yaml"
                                    def tempService = "temp-${app.name}-service.yaml"

                                    sh "cp ${app.k3s_deployment} ${tempDeployment}"
                                    sh "cp ${app.k3s_service} ${tempService}"

                                    sh """
                                        sed -i 's|\\\${APP_NAME}|${app.name}|g' ${tempDeployment} ${tempService}
                                        sed -i 's|\\\${APP_IMAGE}|${app.docker_image}:${BUILD_NUMBER}|g' ${tempDeployment}
                                        sed -i 's|\\\${NODE_PORT}|${app.node_port}|g' ${tempService}
                                    """

                                    sh "kubectl --kubeconfig=${KUBECONFIG} apply -f ${tempDeployment}"
                                    sh "kubectl --kubeconfig=${KUBECONFIG} apply -f ${tempService}"
                                    sh "kubectl --kubeconfig=${KUBECONFIG} rollout restart deployment ${app.name}-deployment"
                                }
                            }
                        }
                    }

                    parallel branches
                }
            }
        }
    }
}
