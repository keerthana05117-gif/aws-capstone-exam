pipeline {
    agent any

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/keerthana05117-gif/aws-capstone-exam.git'
            }
        }

        stage('Deploy with Ansible') {
            steps {
                sh '''
                cd ansible
                ansible-playbook -i hosts deploy.yml
                '''
            }
        }
    }
}

