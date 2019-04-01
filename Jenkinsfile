pipeline {
    agent "fcc-ubuntu-01"

    stages {
        stage('Build') {
            steps {
                sh 'cd docpage; npm install jquery; npm install bootstrap-sass; jekyll build --safe --config "_config.yml,_config_ci.yml"'
            }
        }
        stage('Test') {
            steps {
                echo 'Testing..'
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying.... (skip)'
            }
        }
    }
}
