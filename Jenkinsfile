pipeline {
	agent any
	environment {
		msi_name = 'AdobeUSTSetup.msi'
		cert_name = 'AdobeIOCertgen.zip'
		msi_file = "Installer/bin/Signing/Finished/${msi_name}"
		cert_file = "CertGui/bin/Signing/Finished/${cert_name}"
	}
	stages {
		stage('Configure') {
			steps {
				script{
					env.MESSAGE = sh(returnStdout: true, script: 'git log -1 --pretty=format:%s') + "\n\n" + params.message
					env.DO_RELEASE = env.MESSAGE.matches("release:" + "(.*)") || params.release == "true"
					env.MESSAGE = java.net.URLEncoder.encode(env.MESSAGE, "UTF-8")
				}
			}
		}	
		stage('Build') {
			steps {
				script{     
					dir("windows/Installer") {
						sh 'powershell -File build.ps1 -sign'
					}
					dir("windows"){
						archiveArtifacts artifacts: "$msi_file", fingerprint: true
						archiveArtifacts artifacts: "$cert_file", fingerprint: true		
						withAWS(credentials:'aws-upload', region:'us-east-2') {
							s3Upload(file:"$cert_file", bucket:"adobe-ust-installer", path:"$cert_name", acl:"PublicRead")
							s3Upload(file:"$msi_file", bucket:"adobe-ust-installer", path:"$msi_name", acl:"PublicRead")
						}						
					}
				}
			}
		}
		stage('Release') {
			when {expression { env.DO_RELEASE == 'true' }}
			steps {
				script{     
					dir("windows") {			
						env.msg = MESSAGE
						sh 'powershell -File Installer/push_release.ps1 -filepaths "$msi_file","$cert_file" -message "$msg"'
					}
				}
			}
		}
	}

	post { always { deleteDir()}}
}

