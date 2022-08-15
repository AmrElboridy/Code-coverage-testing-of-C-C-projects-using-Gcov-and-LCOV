::Code-coverage-testing-of-C-C-projects-using-Gcov-and-LCOV
:: to generate XML file to be used in the video-wall tool
@ECHO OFF 
:: 1- Go to the directory after make build command
cd File
:: Compile 
:: needed the files in the makefile  to generate executable
make
:: Running the executable
.\main.exe
:: 2-  Gcov to Analyze Code Coverage
:: all generated files are in the current directory .gcno and .gcda
gcov main.c cond.c
:: 3- generate a visual code coverage report
::  Generate the lcov.info data file
perl C:\ProgramData\chocolatey\lib\lcov\tools\bin\lcov  --capture --directory . --output-file lcov.info
:: 4- Generate coverage\html
perl C:\ProgramData\chocolatey\lib\lcov\tools\bin\genhtml -o .\coverage_html lcov.info
:: 5- Run the python script to generate the coverage.xml file 
C:\Projects\tools\Python39\python lcov_cobertura.py lcov.info --output coverage.xml
:: 6- Rename the coverage.xml to cobetura.xml–to be clarified with Mbition
rename "coverage.xml" "cobetura.xml"
