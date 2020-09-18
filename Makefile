
version = $(file < version.txt)
output_dir = bin
signed_dir = signed

build:
	@rm ${output_dir} -rf
	@rm ${signed_dir} -rf
	@mkdir ${output_dir}
	@mkdir ${signed_dir}
	makensis.exe ust_setup.nsi

sign:
	java -jar "${BAST_HOME}\client.jar" -s \
	-b "${output_dir}" \
	-d "${signed_dir}" \
	-ri "${UST_SIGN_INSTALLER_RULEID}" \
	-u "${UST_SIGN_USERID}" \
	-p "${UST_SIGN_PASSWORD}" \
	-k "${BAST_HOME}\sehkmet"
	mv ${signed_dir}\AdobeUSTSetup.exe ${signed_dir}\AdobeUSTSetup-${version}.exe