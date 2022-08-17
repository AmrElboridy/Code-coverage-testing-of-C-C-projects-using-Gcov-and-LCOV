import subprocess
import perl

#def lcov_cmd(x):
   #     lcov_path = "C:\ProgramData\chocolatey\lib\lcov\tools\bin\lcov"
  #      lcov_creating_result = subprocess.call(["perl", "lcov_path", --capture --output-file lcov.info --directory ], stdin=subprocess.PIPE)
 #       return lcov_creating_result
#perl C:\ProgramData\chocolatey\lib\lcov\tools\bin\lcov  -c -d . -o lcov.info

testfolder = "C:\Projects\EB\Vcpu\Tasks\1-Video-wall_task\File\."
lcov_creating_result = subprocess.Popen( 
        ["perl", "lcov_path", "-c","-o lcov.info"],
        cwd=testfolder , capture_output=True)
        
        
#lcov_cmd('C:\Projects\EB\Vcpu\Tasks\1-Video-wall_task\File')


#subprocess.run(["ls", "-l", "/dev/null"], capture_output=True)


#pipe = subprocess.Popen(["perl", "./uireplace.pl", var], stdin=subprocess.PIPE)
##pipe.stdin.write(var)
#pipe.stdin.close()





#def f(x):
 #       return x**2 + 1

#print (f(5))
