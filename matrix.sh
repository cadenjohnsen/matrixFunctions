#!/bin/bash
###############################################################################
###	This program is meant to take input from up to two files containing a single
#		matrix each. Then it will complete a desired function: dimensions, addition,
#		mean, and transpose. Below are listed examples of each function.
#		dimensions: calculates the dimensions of a given matrix file, including from
#								a piped input, and returned the height and width.
#			Input: 	./matrix.sh dims m2x4
#			Output: 2	4
#			Input: 	cat m2x4 | ./matrix.sh dims
#			Output:	2	4
#		addition: adds each variable of a matrix to a variable at the same positon
#							of another matrix with the same dimensions.
#			Input: 	./matrix.sh add m2x4 m2x4R
#			Output:	9 9 9 9
#							9 9 9 9
#		mean: calculates the average number in each column of a single given matrix
#					and prints the result.
#			Input: 	./matrix.sh mean m2x4
#			Output:	3	4	5	6
#		transpose: executes a transpose of a single chosen matrix inverting its
#							 dimensions and returning the new matrix.
#			Input:	./matrix.sh transpose m4x2
#			Output: 1	2	3	4
#							5	6	7	8
###
###############################################################################

# initialize all global variables to zero
i=0
j=0
k=0
l=1
width=0
height=0
width2=0
height2=0
linenum=0
sum=0
temp=0
tempFlag=0
count=0
average=0
counter=0
counter2=0
counter3=0
counter4=0
mean=0
index=0
index2=0
rownum=0
colnum=0
arg_num=0

# exits when there are no errors
cleanExit () {
	# remove all temp files and exit normally
	rm -f "tempfile$$"
	rm -f "secondtempfile$$"
	exit 0
}

# exits if invalid arguments
invalidArg () {
	# remove all temp files and exit with error
	rm -f "tempfile$$"
	rm -f "secondtempfile$$"
	1>&2 echo "Invalid arguments"	# print invalid arguments and trigger STDERR
	exit 1
}

# exits if invalid matrices
invalidMat () {
	# remove all temp files and exit with error
	rm -f "tempfile$$"
	rm -f "secondtempfile$$"
	1>&2 echo "Invalid matrices"	# print invalid arguments and trigger STDERR
	exit 1
}

# exits if invalid file
invalidFile () {
	# remove all temp files and exit with error
	rm -f "tempfile$$"
	rm -f "secondtempfile$$"
	1>&2 echo "Invalid file"	# print invalid arguments and trigger STDERR
	exit 1
}

# gets number of command line argmuents
arg_num=`expr $#`

# checks if command line has a pipe input
if [ -p /dev/stdin ]
then
	tempFlag=1	# acts as a flag
	# if it is piped, take in file
		while IFS= read -r myLine
		do
			printf '%s\n' "$myLine" >> "tempfile$$"	# move input to temp file
			height=`expr $height + 1`	# find the height of the file using counter
		done
		width=$(wc -w "tempfile$$" | cut -d ' ' -f 1)	# find the width of the file using cut
		width=`expr $width / $height`	# divide width to get correct value

		row=$(cat "tempfile$$" | head -n 1 | tail -n 1)
else
	# if it is not piped, take normal file area
	if [[ -a $2 && -r $2 ]]	# checks if the file exists and is readable
	then
		while read myLine
		do
			echo "$myLine" >> "tempfile$$"
			height=`expr $height + 1`	# find the height of the file using counter
		done < $2
		width=$(wc -w "tempfile$$" | cut -d ' ' -f 1)	# find the width of the file using cut
		width=`expr $width / $height`	# divide width to get correct value

		row=$(cat "tempfile$$" | head -n 1 | tail -n 1)	# cuts out the first row of the file
	else
		invalidFile
	fi
fi

# gets width and height of matrix two
	if [ $arg_num == 3 ]	# checks if number of arguments includes a second matrix file input
	then
		while read myLine	# read in second file
		do
			echo "$myLine" >> "secondtempfile$$"
			height2=`expr $height2 + 1`	# find the height of the file using counter
		done < $3
		width2=$(wc -w "secondtempfile$$" | cut -d ' ' -f 1)	# find the width of the file using cut
		width2=`expr $width2 / $height2`	# divide width to get correct value

		row2=$(cat "secondtempfile$$" | head -n 1 | tail -n 1)	# cuts out the first row of the second file
	fi

# dimensions function
dims () {
	if [ -a $1 ]	# checks if the file exists
		then
		if [ $arg_num == 2 ] || [ $arg_num == 1 ]	# checks if number of arguments is correct
		then
			echo "$height $width"	# print dimensions
		else
			invalidArg	# calls function for invalid argument
		fi
	else
		invalidFile	# calls function for invalid file input
	fi
	cleanExit	# calls function to exit normally
}

# transpose function
transpose () {
	if [ -r $1 ]	# checks if the file is readable
	then
		if [ $arg_num == 2 ]	# checks if the correct number of files are there
		then
			result=''	# create file to store results of function
			for i in $row	# loop through matrix 1 row 1
			do
				index=$((index + 1))	# increment index
				column=$(cat "tempfile$$" | cut -f${index})	# gets column numbers
				counter=0

				for j in $column	# loop through matrix 1 columns
				do
					result+="${j}\t"	# prints column numbers in reverse order
				done
				result="${result::-2}"	# removes trailing tab or new line characters
				result+="\n"	# adds new line at the end of the file
			done
			result="${result::-2}"	# removes trailing tab or new line characters
			echo -e "$result"	# print out answer
		else
			invalidArg	# calls function for invalid argument
		fi
	else
		invalidFile	# calls function for invalid file input
	fi
	cleanExit	# calls function to exit normally
}

# mean function
mean () {
	if [ $arg_num == 2 ]	# checks if the correct number of files are there
	then
		result=''	# create file to store results of function
		for i in $row	# loop through matrix 1 row 1
		do
			index=$((index + 1))	# increment index
			column=$(cat "tempfile$$" | cut -f${index})	# cut out columns one by one
			counter=0

			for j in $column	# loop through columns
			do
				counter=`expr $counter + $j`	# adds up all numbers in a column
			done
			# calculate mean value
			mean=$(((counter + (height/2)*((counter>0)*2-1)) / height))
			result+="${mean}\t"	# store result in variable to be printed
		done
		result="${result::-2}"	# remove trailing characters
		echo -e "$result"	# print out result
	else
		invalidArg	# calls function for invalid argument
	fi
	cleanExit	# calls function to exit normally
}

# addition function
add () {
	if [ $arg_num == 3 ]	# checks if correct number of input files
	then
		if [ $width == $width2 ]	# checks if widths of the two files are the same
		then
			if [ $height == $height2 ]	# checks if heights of the two files are the same
			then
				result=''	# creates variable to store results
				counter=0
				sum=0
				index=0
				index2=0
				IFS=$'\t\n'
				for next in `cat "tempfile$$"`; do	# reads in next variable in the first matrix
					index2=0
					for next2 in `cat "secondtempfile$$"`; do	# reads in next variable in the second matrix
						if [ $index == $index2 ]	# checks if the files are at the same spot to add correctly
						then
							sum=$((next + next2))	# adds the two variables from the files at their current index
							result+="${sum}\t"	# add results to result file
							sum=0
						fi
						index2=$((index2 + 1))	# increment index
					done
					index=$((index + 1))	# increment index
					if [ $((index % width)) == 0 ]	# checks if the current number to be manipulated is at the end of its row
					then
						result="${result::-2}"	# remove trailing characters
						result+="\n"	# add new line
					fi
				done
				result="${result::-2}"	# remove trailing characters
				echo -e "$result"	# print out result
			else
				invalidMat	# calls function for invalid matrix
			fi
		else
			invalidMat	# calls function for invalid matrix
		fi
	else
		invalidArg	# calls function for invalid arguments
	fi
	cleanExit	# calls function to exit normally
}

# flag that is set if there is piping into STDIN
if [ $tempFlag == 1 ]
then
	dims
fi

# creates array of command line arguments
ARGS=( $@ )
if [ ! -t 0 ]; then
  readarray STDIN_ARGS < /dev/stdin
  ARGS=( $@ ${STDIN_ARGS[@]} )
fi

# checks command line arguments for functions to be called and calls them
for ARG in "${ARGS[@]}"; do
	if [ $ARG == "dims" ]
	then
		dims
	elif [ $ARG == "mean" ]
	then
		mean
	elif [ $ARG == "add" ]
	then
		add
	elif [ $ARG == "transpose" ]
	then
		transpose
	elif [ $ARG == "multiply" ]
	then
		multiply
	else
		invalidArg
	fi
done

rm -f "tempfile$$"
rm -f "secondtempfile$$"
