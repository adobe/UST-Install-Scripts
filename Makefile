output_dir = dist
build:
	-rmdir /S /Q $(output_dir)
	makensis.exe ust_setup.nsi
