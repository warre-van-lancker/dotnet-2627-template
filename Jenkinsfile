node {
    stage('Checkout') {
        // Clones the repo containing app.sh and the source code
        checkout scm
    }

    stage('Preparation') {
        // Force-remove running or stopped container without erroring if it doesn't exist
        sh 'docker rm -f rise-running || true'
    }

    stage('Build & Run') {
        // Ensure script has execution permissions and run it
        sh 'chmod +x ./app.sh'
        sh 'bash ./app.sh'
    }
}
