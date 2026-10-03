node {
    stage('Preparation') {
        catchError(buildResult: 'SUCCESS') {
            sh 'docker stop rise-running'
            sh 'docker rm rise-running'
        }
    }
    stage('Build') {
        sh 'bash ./app.sh'
    }
}
