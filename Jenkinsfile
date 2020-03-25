pipeline {

    agent {
        label 'maven'
    }

    environment {
        ARTIFACTORY_URL = "${env.EXTERNAL_DOCKER_REGISTRY}"
        OSE_PROJ = credentials('OSE_PROJ')
        PUSH_SECRET = credentials('PUSH_SECRET')
        PROXY_PASS_BUILD = "http:\\/\\/kong-docker.kong-development-environment.svc:8000"
        PROXY_PASS_E2E = "http:\\/\\/kong-docker.prod-kong-deployment.svc:8000"
        VERSION = "1.2.1"
        scmVars = checkout scm
        gitBranch = sh(
                script: "echo ${scmVars.GIT_BRANCH} | cut -d '/' -f2",
                returnStdout: true).trim()
    }

    stages {

      stage('Build and Push Docker Image (develop)') {
            steps {
				timestamps {
					logstash {
						script {
							try {
								sh 'set +x'
								sh 'oc project $OSE_PROJ'
								sh """oc new-build --binary=true --name=pedigree-nginx --to-docker=true \\
											--to=\"$ARTIFACTORY_URL/pedigree-nginx:$VERSION\" \\
											--push-secret=\"$PUSH_SECRET\""""

								// Execute the build config to build the Docker image and push to Artifactory
								sh "oc start-build pedigree-nginx --from-dir=. --follow=true --wait"
							} catch (err) {
								echo "Error caught in step. Deleting build config in Open Shift."
								echo "Caught: ${err}"
								currentBuild.result = 'FAILURE'
							} finally {
								// Delete the created build config to keep OSE clean for demo purposes
								// Note: If the build config is kept, then "oc new-build" is not needed for subsequent builds.
								sh 'oc delete bc/pedigree-nginx'
							}
						}
					}
				}
			}
        }

        stage('Deploy to Build Cluster') {
            steps {	
				timestamps {
					logstash {
						script {
							sh 'set +x'
							sh "oc import-image --confirm pedigree-nginx:$VERSION --from=\"$ARTIFACTORY_URL/pedigree-nginx:$VERSION\""
						}
					}
				}
            }
        }
        
    }
}
