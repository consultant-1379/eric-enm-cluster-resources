#!/usr/bin/env groovy

/* IMPORTANT:
 *
 * In order to make this pipeline work, the following configuration on Jenkins is required:
 * - slave with a specific label (see pipeline.agent.label below)
 * - credentials plugin should be installed and have the secrets with the following names:
 *   + lciadm100credentials (token to access Artifactory)
 */

def defaultBobImage = 'armdocker.rnd.ericsson.se/sandbox/adp-staging/adp-cicd/bob.2.0:1.5.2-0'
def bob = new BobCommand()
        .bobImage(defaultBobImage)
        .needDockerSocket(true)
        .toString()

def bobInCA = new BobCommand()
        .bobImage(defaultBobImage)
        .needDockerSocket(true)
        .envVars([
                ARM_API_TOKEN     : '${ARM_CREDENTIALS_PSW}',
                CHART_PATH        : '${CHART_PATH}',
                GIT_REPO_URL      : '${GIT_REPO_URL}',
                HELM_INTERNAL_REPO: '${HELM_INTERNAL_REPO}',
                HELM_DROP_REPO    : '${HELM_DROP_REPO}',
                HELM_RELEASED_REPO: '${HELM_RELEASED_REPO}',
                GERRIT_USERNAME   : '${GERRIT_CREDENTIALS_USR}',
                GERRIT_PASSWORD   : '${GERRIT_CREDENTIALS_PSW}',
                CHART_NAME        : '${CHART_NAME}',
                CHART_VERSION     : '${CHART_VERSION}',
                ALLOW_DOWNGRADE   : '${ALLOW_DOWNGRADE}',
                HELM_REPO_CREDENTIALS : '${HELM_REPO_CREDENTIALS}',
                HELM_USER         :  '${HELM_REPO_CREDENTIALS}',
                HELM_REPO_TOKEN   :   '${HELM_REPO_TOKEN}'
        ])
        .toString()

def GIT_COMMITTER_NAME = 'enmadm100'
def GIT_COMMITTER_EMAIL = 'enmadm100@ericsson.com'
def failedStage = ''

pipeline {
    agent {
        label 'Cloud-Native'
    }
    environment {
        GERRIT_CREDENTIALS = credentials('cenmbuild_gerrit_api_token')
        ARM_CREDENTIALS = credentials('cenmbuild_ARM_token')
        CHART_PATH = "chart/eric-enm-cluster-scoped-resources"
        REPO = "OSS/ENM-Parent/SQ-Gate/com.ericsson.oss.containerisation/eric-enm-cluster-resources"
        GIT_REPO_URL = "${GERRIT_CENTRAL_HTTP}/a/${REPO}"
        HELM_INTERNAL_REPO = "https://arm.epk.ericsson.se/artifactory/proj-enm-dev-internal-helm/"
        HELM_DROP_REPO = "https://arm.epk.ericsson.se/artifactory/proj-enm-dev-internal-helm/"
        HELM_RELEASED_REPO = "https://arm.epk.ericsson.se/artifactory/proj-enm-dev-internal-helm/"
    }
    stages {
        stage('Clean') {
            steps {
                deleteDir()
            }
        }
        stage('Checkout Cloud-Native eric-enm-cluster-scoped-resources Git Repository') {
            steps {
                git branch: 'master',
                        url: '${GERRIT_MIRROR}/OSS/ENM-Parent/SQ-Gate/com.ericsson.oss.containerisation/eric-enm-cluster-resources'
                sh '''
                    git remote set-url origin --push ${GERRIT_CENTRAL}/${REPO}
                '''
            }
        }
        stage('Getting sprint tag') {
            steps {
                script {
                    env.SPRINT_TAG = sh(script: 'wget -q -O - --no-check-certificate https://ci-portal.seli.wh.rnd.internal.ericsson.com//api/product/ENM/latestdrop/|cut -d\':\' -f2|sed \'s/[},"]//g\'', returnStdout: true).trim()
                }
            }
        }
        stage('Timestamp') {
            steps {
               script {
                  sh '''
                          echo `date` > timestamp
                          git add timestamp
                          git commit -m "NO JIRA - Time Stamp "
                          git push origin HEAD:master
                     '''
                    //wait for gerrit sync
                     checkGerritSync()
                }
            }
        }
        stage('Lint Helm') {
            steps {
                sh "${bob} lint-helm"
            }
        }
        stage('Generate New Version') {
            steps {
                sh "${bob} generate-new-version"
            }

        }
        stage('Build Chart') {
            steps {
                script {
                       def bobwithbuild = new BobCommand()
                            .bobImage(defaultBobImage)
                            .needDockerSocket(true)
                            .envVars(['HELM_USER': env.HELM_USER,
                                      'HELM_TOKEN': env.HELM_TOKEN,
                                      'SPRINT_TAG': env.SPRINT_TAG,
                            ])
                            .toString()
                        sh "${bobwithbuild} build-helm"
                    }
            }
        }
        stage('Publish Helm Chart') {
            steps {
                script {
                    def bobWithHelmToken = new BobCommand()
                            .bobImage(defaultBobImage)
                            .needDockerSocket(true)
                            .envVars(['HELM_REPO_TOKEN': env.HELM_REPO_TOKEN])
                            .toString()
                    sh "${bobWithHelmToken} helm-push"
                }
            }
        }
        stage('Generate INT Parameters') {
            steps {
                sh "${bob} generate-output-parameters"
                archiveArtifacts 'artifact.properties'
                archiveArtifacts '.bob/var.commit-hash'
            }
        }
        stage('Tag Cloud-Native eric-enm-cluster-scoped-resources Repository') {
            steps {
                wrap([$class: 'BuildUser']) {
                    script {
                        def bobWithCommitterInfo = new BobCommand()
                                .bobImage(defaultBobImage)
                                .needDockerSocket(true)
                                .envVars([
                                        'AUTHOR_NAME'        : "${GIT_COMMITTER_NAME}",
                                        'AUTHOR_EMAIL'       : "${GIT_COMMITTER_EMAIL}",
                                        'GIT_COMMITTER_NAME' : "${GIT_COMMITTER_NAME}",
                                        'GIT_COMMITTER_EMAIL': "${GIT_COMMITTER_EMAIL}"
                                ])
                                .toString()
                        sh "${bobWithCommitterInfo} create-git-tag"
                        sh """
                            tag_id=\$(cat .bob/var.version)
                            git push origin \${tag_id}
                        """
                    }
                }
            }
            post {
                always {
                    script {
                        sh "${bob} remove-git-tag"
                    }
                }
            }
        }
        stage('CLEAN') {
            steps {
                sh "${bob} clean"
            }
        }
    }
    post {
        success {
            script {
                sh '''
                    set +x
                    git tag --annotate --message "Tagging latest in sprint" --force $SPRINT_TAG HEAD
                    git push --force origin $SPRINT_TAG
                '''
            }
        }
        failure {

            // mail to: 'EricssonHyderabad.ENMMisty@tcs.com,EricssonHyderabad.ENMDewdrops@tcs.com',
            // mail only evormax for debug
            mail to: 'maxim.vorontsov@ericsson.com',
                    subject: "Failed Pipeline: ${currentBuild.fullDisplayName}",
                    body: "Failure on ${env.BUILD_URL}"
        }
        cleanup {
            deleteDir()
        }
    }
}

def checkGerritSync() {
    sh '''
       RETRY=20
       SLEEP=30

       if [ -z ${BRANCH+x} ]; then
           echo "BRANCH is unset using master"
           branch="master"
       else
           echo "Using branch '$BRANCH'"
           branch=${BRANCH}
       fi

       retry=0
       while (( retry < RETRY )); do
           echo "INFO: Attempting retry #$((retry+1)) of $RETRY in $SLEEP seconds."
           # get the commit ID's on GC master and mirror
           echo "INFO: Checking commit ID's for '$branch' branch on Gerrit Central."
           gcr=$(git ls-remote -h ${GERRIT_CENTRAL}/${REPO} ${branch} | awk '{print $1}')
           gmr=$(git ls-remote -h ${GERRIT_MIRROR}/${REPO} ${branch} | awk '{print $1}')
           echo "INFO: central: ${gcr}"
           echo "INFO: mirror:  ${gmr}"
               if [[ "${gcr}" != "${gmr}" ]]; then
                   echo "INFO: Gerrit central and mirror are out of sync."
                   let "retry=retry+1"
                   if [[ "${retry}" == "${RETRY}" ]]; then
                       echo "Gerrit mirror not in sync with central"
                       exit 1
                   else
                       echo "Waiting for sync...."
                       sleep $SLEEP
                   fi
               else
                   break
               fi
       done
       local_head=$(git rev-parse HEAD)
       [ "${local_head}" != "${gmr}" ] && echo -e "Fetching upstream changes" && git pull origin ${branch}
       echo "INFO: Branch in sync between Gerrit central and mirror."
       '''
}

// More about @Builder: http://mrhaki.blogspot.com/2014/05/groovy-goodness-use-builder-ast.html
import groovy.transform.builder.Builder
import groovy.transform.builder.SimpleStrategy

@Builder(builderStrategy = SimpleStrategy, prefix = '')
class BobCommand {
    def bobImage = 'bob.2.0:latest'
    def envVars = [:]
    def needDockerSocket = false

    String toString() {
        def env = envVars
                .collect({ entry -> "-e ${entry.key}=\"${entry.value}\"" })
                .join(' ')

        def cmd = """\
            |docker run
            |--init
            |--rm
            |--workdir \${PWD}
            |--user \$(id -u):\$(id -g)
            |-v \${PWD}:\${PWD}
            |-v /etc/group:/etc/group:ro
            |-v /etc/passwd:/etc/passwd:ro
            |-v \${HOME}/.m2:\${HOME}/.m2
            |-v \${HOME}/.docker:\${HOME}/.docker
            |${needDockerSocket ? '-v /var/run/docker.sock:/var/run/docker.sock' : ''}
            |${env}
            |\$(for group in \$(id -G); do printf ' --group-add %s' "\$group"; done)
            |--group-add \$(stat -c '%g' /var/run/docker.sock)
            |${bobImage}
            |"""
        return cmd
                .stripMargin()           // remove indentation
                .replace('\n', ' ')      // join lines
                .replaceAll(/[ ]+/, ' ') // replace multiple spaces by one
    }
}
