////////////////////////////////////////////////////////////////////////////////
// Looks for global macros and writes to the dofile
mata:
void globals_export(|string scalar outname , real scalar ou_fh)
	{
	
	real   scalar ismacro, forbidden, in_fh, isnewfile
	string scalar line, macname, macvalu, typeofmacro, REGEX, FORBIDDEN
	string scalar logname

	if (outname == J(1,1,"")) outname = randomid(10,"",1,1,1)
	
	if (ou_fh == J(1,1,.)) {
		ou_fh = fopen(outname, "w", 1)
		isnewfile = 1
	}
	else isnewfile = 0
	
	// Writing log
	logname = randomid(10,"",1,1,1)
	
	stata("cap log close log"+logname)
	stata("log using "+logname+".log, text replace name(log"+logname+")")
	stata("noisily macro dir")
	stata("log close log"+logname)
	
	in_fh = fopen(logname+".log", "r", 1)
	
	// Step 1
	REGEX = "^([0-9a-zA-Z_]+)([:][ ]*)(.*)"
	FORBIDDEN = "^(S[_]FNDATE|S[_]FN|F[0-9]|S[_]level|S[_]ADO|S[_]FLAVOR|S[_]OS|S[_]MACH)([ ]*.*$)"
	
	line = fget(in_fh)
	while (line!=J(0,0,""))
	{
		// Check wheater it is a macro or not (and not system macros)
		forbidden = regexm(line, FORBIDDEN)
		ismacro = regexm(line, REGEX)
		
		if (ismacro & !forbidden)
		{
			macname = regexs(1)
			
			// Checks wheather if it is a local or global macro
			if (!regexm(macname, "^[_]"))
			{
				macvalu = st_macroexpand("$"+macname)
				typeofmacro = "global "
				line = typeofmacro+macname+" "+macvalu
				fput(ou_fh, line)
			}
		}
		line = fget(in_fh)
	}
	
	fclose(in_fh)
	unlink(logname+".log")
	if (isnewfile) fclose(ou_fh)
}
end
