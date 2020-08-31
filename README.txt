This  folder contains two bash programs to execute matrix functions.
matrix.sh: a bash script that has the ability to solve matrix functions using input matrices from text files. These functions include dimensions, addition, mean, and transpose.
testScript.sh: a bash script to test all of the functions of the matrix.sh program.
To Compile:
chmod u+x matrix.sh
chmod u+x testScript.sh

To Run matrix.sh:
./matrix.sh dims m2x4
cat m2x4 | ./matrix.sh dims
./matrix.sh add m2x4 m2x4R
./matrix.sh mean m2x4
./matrix.sh transpose m2x4

To Run testScript.sh:
./testScript.sh matrix.sh
