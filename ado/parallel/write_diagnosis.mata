mata:
void write_diagnosis(string scalar diagnosis, string scalar fname, | string scalar msg) {
	real scalar fh
	if (fileexists(fname)) unlink(fname)
	fh = fopen(fname, "w")
	fput(fh, diagnosis)
	fput(fh, msg)
	fclose(fh)
	
}
end
