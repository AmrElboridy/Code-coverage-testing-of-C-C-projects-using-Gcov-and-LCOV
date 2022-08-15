@echo off
:: 1- Go to the directory after make build command
cd File\2_sample_files
:: Compile 
make
:: Running the executable
.\main.exe
:: 1- Go to the directory after make build command
cd File\2_sample_files
:: 2-  Gcov to Analyze Code Coverage
:: all generated files are in the current directory .gcno and .gcda
echo Generating .gcov file 
gcov main.c cond.c
:: 3- generate a visual code coverage report
::  Generate the coverage.info data file
:: change the path to the lcov
perl C:\ProgramData\chocolatey\lib\lcov\tools\bin\lcov  --capture --directory . --output-file locv.info



perl C:\ProgramData\chocolatey\lib\lcov\tools\bin\genhtml -o coverage\html coverage\lcov.info
:: 4- Run the python script to generate the coverage.xml file 
C:\Projects\EB\TOOLS\Python39\python lcov_cobertura.py locv.info  --output coverage.xml 
::5- Rename the coverage.xml to cobetura.xml–to be clarified with Mbition
rename "coverage.xml" "cobetura.xml"
