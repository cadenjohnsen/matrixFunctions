#!/bin/bash

# This first section processe the flags used in while calling the grading script.
#   h - will list the proper syntax and list of flags, then exits the code
#   d - enter debug mode. Failures will send outpipe or errpipe to log. Matrices
#       will be saved.
#   u - enters unit testing mode. Grading script will exit after first error.
#   e - The flag for error tests
#   i - The flag for dims tests
#   t - The flag for tranpose tests
#   m - The flag for mean tests
#   a - The flag for add tests

# The following are the variables used to store the test statuses, with 1 = do not run tests, 0 = run tests
# Exit statuse codes introduced:
#   11: Normal ext status for exiting help
#   12: Invalid flag used
#   13: Exited on the first error encountered
log=/dev/null
debugMode=1
unitMode=1
runFlag=0
ERR=1
DIMS=2
TRANS=4
MEAN=8
ADD=16
while getopts :hdueitmalgx flag; do
	case $flag in
		h)
			echo "To use grading script, type ./p1gradingscript -listOfFlags yourFileName"
			echo -en "The flags are as follows:
      h - will list the proper syntax and list of flags, then exits the code.
      d - enter debug mode. Failures will send outpipe or errpipe to log. Matrices
          will be saved.
      u - enters unit testing mode. Grading script will exit after first error.
      e - The flag for error tests.
      i - The flag for dims tests.
      t - The flag for tranpose tests.
      m - The flag for mean tests.
      a - The flag for add tests.\n"
			exit 11
			;;
		d)
			debugMode=0
      log=Error_Log_$(date "+%Y-%m-%d---%H:%M:%S")
			;;
		u)
		  unitMode=0
      ;;
		e)
		  runFlag=$(( runFlag | ERR ))
			;;
		i)
		  runFlag=$(( runFlag | DIMS ))
			;;
		t)
		  runFlag=$(( runFlag | TRANS ))
			;;
		m)
		  runFlag=$(( runFlag | MEAN ))
			;;
		a)
		  runFlag=$(( runFlag | ADD ))
			;;
		\?)
			echo "Bad flag entered, exiting"
			exit 12
			;;
	esac
done
if [ $runFlag -ne 0 ]
then
    runFlag=$(( ~ runFlag ))
fi

# NAME
# 	generate - generates a matrix of specified size
#	SYNOPSIS
#		generate ROWS COLS MIN MAX
# DESCRIPTION
#		Prints a matrix of size ROWS*COLS with random values ranging from MIN to MAX

#Font Modifiers
OKGREEN='\033[92m'
FAIL='\033[91m'
ENDC='\033[0m'
if ! [ -t 1 ]; then # If the output is not being sent to a terminal, don't use colors
    FAIL=''
    OKGREEN=''
    ENDC=''
fi

function generate(){
	y=0
	a=$3
	b=$4
	while [ "$y" -lt "$1" ]
	do
		x=0
		((y++))
		while [ "$x" -lt "$2" ]
		do
			((x++))
			echo -n $((RANDOM%(b-a+1)+a))
			if [ "$x" -ne "$2" ]
			then
			echo -ne "\t"
			else
				echo
			fi
		done
	done
}

# NAME
# 	ident - generate identity matrix of specified size
# SYNOPSIS
#		ident ROWS COLS
function ident(){
	y=0
	while [ "$y" -lt "$1" ]
	do
		x=0
		((y++))
		while [ "$x" -lt "$2" ]
		do
			((x++))
			if [ $x -eq $y ]
			then
				echo -n 1
			else
				echo -n 0
			fi
			if [ "$x" -ne "$2" ]
			then
				echo -ne "\t"
			else
				echo
			fi
		done
	done
}

# NAME
#	Error
# SYNOPSIS
#	Dump error message and exit

err(){
	echo "$1" >&2
	exit 1
}

# NAME
#   expect_error
# SYNOPSIS
#   expect_error SCORE SECONDS CMD
# DESCRIPTION
#   Runs a CMD that is expected to fail. Times out after SECONDS. If test fails
#   (CMD does not error correctly), then prints message and returns 0. Otherwise
#   returns SCORE.

expect_error(){
    ((tests+=1))
    score="$1"
    timeout --foreground -s9 "$2" $3 >"$outpipe" 2>"$errpipe"
    result=$?
    if
    	[ "$result" -eq 124 ]
    then
        echo -e "${FAIL}- Hung process (killed)${ENDC}" | tee -a "$log"
    	score=0
    else
    	if [ "$result" -eq 0 ]
    	then
    		score=0
    		echo -e "${FAIL}- Returned 0${ENDC}" | tee -a "$log"
    	fi
    	if [ -s "$outpipe" ]
    	then
    		score=0
    		echo -e "${FAIL}- stdout is non-empty${ENDC}" | tee -a "$log"
    		cat "$outpipe" >> "$log"
    	fi
    	if [ ! -s "$errpipe" ]
    	then
    		score=0
    		echo -e "${FAIL}- stderr is empty${ENDC}" | tee -a "$log"
    	fi
    fi
    if [ $score -ne 0 ]
    then
    	echo -e "${OKGREEN}+ Passed!${ENDC}"
    	return
    fi
    if [ "$unitMode" -eq 0 ]; then
        exit "$score"
    fi

}

# NAME
#   expect_success
# SYNOPSIS
#   expect_success SCORE SECONDS CMD [MESSAGE] [EXPECTED_RESULT]
# DESCRIPTION
#   Runs a CMD that is expected to succeed. Times out after SECONDS. If test
#   succeeds, it prints a success message and returns SCORE. If test fails in
#   any way then it returns 0. If  MESSAGE is provided then CMD output is
#   compared to EXPECTED_RESULT and MESSAGE is sent to stdout upon failure. If
#   MESSAGE is provided but EXPECTED_RESULT is not, then EXPECTED_RESULT is read
#   from stdin.
expect_success(){
    ((tests+=1))
    score="$1"
    if [ $# -eq 4 ]
    then
        expected="$(cat)"
    fi
    timeout --foreground -s9 "$2" bash -c "$3" >"$outpipe" 2>"$errpipe"
    result=$?
    if
    	[ "$result" -eq 124 ]
    then
    	echo -e "${FAIL}- Hung process (killed)${ENDC}" | tee -a "$log"
    	score=0
    else
    	if [ "$result" -ne 0 ]
    	then
    		score=0
    		echo -e "${FAIL}- Returned $result${ENDC}" | tee -a "$log"
    	fi
      if [ $# -eq 4 ]
      then
    	  cmp -s "$outpipe" <<< "$expected"
      else
    	  cmp -s "$outpipe" "$5"
      fi
      result=$?
      if
          [[ $result -ne 0 && $# -ge 4 ]]
    	then
    		score=0
    		echo -e "${FAIL}- $message${ENDC}" | tee -a "$log"
    		cat "$outpipe" >> "$log"
    	fi
    	if [ -s "$errpipe" ]
    	then
    		score=0
    		echo -e "${FAIL}- stderr is non-empty${ENDC}" | tee -a "$log"
    		cat "$errpipe" >> "$log"
    	fi
    fi
    if [ $score -ne 0 ]
    then
    	echo -e "${OKGREEN}+ Passed!${ENDC}"
    	return "$score"
    fi
    if [ "$debugMode" -eq 0 ]; then
        args=($3)
        echo "First matrix stored in m$tests.1" >> "$log"
        if [ ${args[0]} = "cat" ]; then
            cp ${args[1]} m$tests.1
        else
            cp ${args[2]} m$tests.1
            case ${args[1]} in
                "add" | "multiply" )
                    echo "Second matrix stored in m$tests.2" >> "$log"
                    cp ${args[3]} m$tests.2
                    ;;
                *)
                    ;;
            esac
        fi
    fi
    if [ "$unitMode" -eq 0 ]; then
        exit "$score"
    fi
    return 0
}


if [ $# -ge 1 ]
then
	if [ -f "$1" ]
	then
		cmd=$1
  elif [ -f "$2" ]
  then
    cmd=$2
	else
		err "Given file not found."
	fi

else
	err "Usage: $0 [bash_program_file]"
fi

chmod +x "$cmd" # Make sure submission is executable
dos2unix "$cmd" # Fix windows newlines (^M errors)

cd "$(dirname "$cmd")" # Change working directory to submission file
cmd="$(basename "$cmd")"



score=0

# Generate temp files to use for grading purposes
m1="$(mktemp matrix.XXXXX)"
m2="$(mktemp matrix.XXXXX)"
m3="$(mktemp matrix.XXXXX)"
m4="$(mktemp matrix.XXXXX)"
m5="$(mktemp matrix.XXXXX)"
outpipe="$(mktemp stdout.XXXXX)"
outpipe2="$(mktemp stdout.XXXXX)"
errpipe="$(mktemp stderr.XXXXX)"
errpipe2="$(mktemp stderr.XXXXX)"

trap 'rm -rf "$m1" "$m2" "$m3" "$m4" "$m5" "$outpipe" "$outpipe2" "$errpipe" "$errpipe2"; trap - EXIT; exit ' INT HUP TERM EXIT

result=0

# Populate matrix files
generate 5 6 -10 10 >"$m1"
generate 6 7 -10 10 >"$m2"
generate 3 8 -10 10 >"$m3"
generate 8 5 -10 10 >"$m4"
generate 3 8 -10 10 >"$m5"

if [ $(( runFlag & ERR )) -eq 0 ]
then

echo "Dims with 2 arguments should throw error:" | tee -a "$log"
expect_error 1 5 "./$cmd dims $m1 $m2"
((points+=score))

echo "Add with 0 arguments should throw error:" | tee -a "$log"
expect_error 1 5 "./$cmd add"
((points+=score))

echo "Adding mismatched matrices should throw error:" | tee -a "$log"
expect_error 4 5 "./$cmd add $m1 $m2"
((points+=score))


chmod -r "$m1"
echo "Transposing unreadable file should throw error:" | tee -a "$log"
expect_error 2 5 "./$cmd transpose $m1"
((points+=score))
chmod +r "$m1"


echo "Dims on nonexistent file should throw error:" | tee -a "$log"
expect_error 1 5 "./$cmd dims $(mktemp -u)"
((points+=score))


echo "badcommand should throw error:" | tee -a "$log"
expect_error 1 5 "./$cmd badcommand"
((points+=score))
fi


if [ $(( runFlag & DIMS )) -eq 0 ]
then
echo "Piping m1 (5x6) into dims:" | tee -a "$log"
message="dimensions output is incorrect"
expect_success 3 5 "cat $m1 | ./$cmd dims" "$message" <<< "5 6"
((points+=score))


echo "Piping m2 (6x7) into dims:" | tee -a "$log"
message="dimensions output is incorrect"
expect_success 3 5 "cat $m2 | ./$cmd dims" "$message" <<< "6 7"
((points+=score))


echo "Piping m3 (3x8) into dims:" | tee -a "$log"
message="dimensions output is incorrect"
expect_success 3 5 "cat $m3 | ./$cmd dims" "$message" <<< "3 8"
((points+=score))


echo "Passing m4 (8x5) to dims on stdin:" | tee -a "$log"
message="dimensions output is incorrect"
expect_success 3 5 "./$cmd dims $m4" "$message" <<< "8 5"
((points+=score))


echo "Passing m1 (5x6) to dims on stdin:" | tee -a "$log"
message="dimensions output is incorrect"
expect_success 3 5 "./$cmd dims $m1" "$message" <<< "5 6"
((points+=score))


echo "Passing m2 (6x7) to dims on stdin:" | tee -a "$log"
message="dimensions output is incorrect"
expect_success 3 5 "./$cmd dims $m2" "$message" <<< "6 7"
((points+=score))
fi



echo "-93	-92	29	-45	-55	-87	-36	39	-88	71	7	-69	52	45	-22
50	-27	85	11	-76	-3	23	68	58	-5	34	7	-29	-49	41
-61	2	-44	-62	47	-77	33	6	-7	55	-45	99	2	20	89
52	-97	57	-39	-76	62	24	69	-74	89	-76	1	-46	-27	-9
55	77	42	10	-98	-22	15	-48	26	33	-7	29	-34	78	-19
23	25	-40	16	-63	-12	42	45	-22	20	44	-23	78	-50	17
-67	14	-9	-58	38	-78	2	99	-87	-92	-34	-29	-7	-31	11
65	-32	27	91	-46	-13	-71	37	24	-5	34	-92	6	15	-15
-49	23	-52	-9	59	-57	-78	-10	17	-27	44	-34	-62	22	-94
-45	-45	88	-12	-64	1	-60	-35	11	1	-10	52	5	52	-17
-91	61	90	22	82	-9	82	85	10	56	18	4	-18	-92	-46
31	98	47	-12	-60	20	54	-8	92	24	-71	-23	24	91	37
-12	98	-13	66	72	-14	88	51	75	5	40	-91	91	-94	26
0	60	-41	6	28	-54	97	56	40	-17	94	-92	-23	-3	-91
10	-26	78	-22	-55	73	-82	-49	-26	-63	-80	8	97	87	-27
80	17	90	22	6	45	23	91	16	-93	-38	-64	-75	35	61
21	-24	-38	92	-43	98	-14	35	39	-65	-20	65	65	19	-81
79	-32	62	-93	89	19	-83	-47	45	20	93	49	43	73	80
24	81	19	-15	48	-46	-23	-63	65	2	75	-16	1	-98	14
-40	-68	-89	-10	90	29	3	-15	58	86	-85	36	-55	31	-79" > "$m1"

echo "-93	50	-61	52	55	23	-67	65	-49	-45	-91	31	-12	0	10	80	21	79	24	-40
-92	-27	2	-97	77	25	14	-32	23	-45	61	98	98	60	-26	17	-24	-32	81	-68
29	85	-44	57	42	-40	-9	27	-52	88	90	47	-13	-41	78	90	-38	62	19	-89
-45	11	-62	-39	10	16	-58	91	-9	-12	22	-12	66	6	-22	22	92	-93	-15	-10
-55	-76	47	-76	-98	-63	38	-46	59	-64	82	-60	72	28	-55	6	-43	89	48	90
-87	-3	-77	62	-22	-12	-78	-13	-57	1	-9	20	-14	-54	73	45	98	19	-46	29
-36	23	33	24	15	42	2	-71	-78	-60	82	54	88	97	-82	23	-14	-83	-23	3
39	68	6	69	-48	45	99	37	-10	-35	85	-8	51	56	-49	91	35	-47	-63	-15
-88	58	-7	-74	26	-22	-87	24	17	11	10	92	75	40	-26	16	39	45	65	58
71	-5	55	89	33	20	-92	-5	-27	1	56	24	5	-17	-63	-93	-65	20	2	86
7	34	-45	-76	-7	44	-34	34	44	-10	18	-71	40	94	-80	-38	-20	93	75	-85
-69	7	99	1	29	-23	-29	-92	-34	52	4	-23	-91	-92	8	-64	65	49	-16	36
52	-29	2	-46	-34	78	-7	6	-62	5	-18	24	91	-23	97	-75	65	43	1	-55
45	-49	20	-27	78	-50	-31	15	22	52	-92	91	-94	-3	87	35	19	73	-98	31
-22	41	89	-9	-19	17	11	-15	-94	-17	-46	37	26	-91	-27	61	-81	80	14	-79" > "$m2"



if [ $(( runFlag & TRANS )) -eq 0 ]
then
echo "Transposing hardcoded matrix:" | tee -a "$log"
message="Transposed matrix does not match known result"
expect_success 10 30 "./$cmd transpose $m1" "$message" "$m2"
((points+=score))


echo "Transpose involution test on m3:"  | tee -a "$log"
message="Transpose is not involutory"
output=$(expect_success 5 3 "./$cmd transpose $m3")
result=$?
((tests+=1)) # Ran in subshell; tests won't be updated
if
    [ $result -eq 0 ]
then
    echo -e "$output"
fi
cp "$outpipe" "$outpipe2"
expect_success $result 30 "./$cmd transpose $outpipe2" "$message" "$m3"
((points+=score))


echo "Transpose involution test on m4:" | tee -a "$log"
message="Transpose is not involutory"
output=$(expect_success 5 3 "./$cmd transpose $m4")
result=$?
((tests+=1)) # Ran in subshell; tests won't be updated
if
    [ $result -eq 0 ]
then
    echo -e "$output"
fi
cp "$outpipe" "$outpipe2"
expect_success $result 30 "./$cmd transpose $outpipe2" "$message" "$m4"
((points+=score))


echo "Transpose involution test on m5:" | tee -a "$log"
message="Transpose is not involutory"
output=$(expect_success 5 3 "./$cmd transpose $m5")
result=$?
((tests+=1)) # Ran in subshell; tests won't be updated
if
    [ $result -eq 0 ]
then
    echo -e "$output"
fi
cp "$outpipe" "$outpipe2"
expect_success $result 30 "./$cmd transpose $outpipe2" "$message" "$m5"
((points+=score))
fi


echo "-28	91	29	-5	12	83
-94	-16	41	-28	6	86
-44	83	-9	64	92	-70
41	22	66	29	55	49
6	52	4	17	-29	52
-8	-33	96	-73	-76	92
-32	94	45	4	43	-97
-57	36	86	90	35	75
46	8	4	-83	-94	-52
0	-6	-90	48	70	11
-33	-41	-76	68	30	-19
70	96	-85	-1	-9	-62
58	63	-4	22	-69	-25
-75	-65	-78	76	39	10
-99	-69	63	53	35	67
73	51	55	-26	-14	9
-90	-19	-19	-63	-96	23
-62	89	93	98	48	-21
-56	-86	24	45	-79	-65
-79	-60	87	-74	44	20
-38	50	-50	-38	-36	30
-69	-66	-23	42	55	-5
-62	98	47	-86	23	-85
-2	-55	-79	-41	-12	-31
-84	-10	46	16	-56	-26
70	-16	-17	99	24	-41
80	47	-59	-55	80	96
-54	43	24	-82	1	-46
25	-1	92	16	44	-21
62	58	79	-97	-21	-62
-46	-23	-68	59	-72	-6
-78	59	11	52	-96	-77
5	77	64	-29	-98	69
-68	69	74	32	-71	91
38	-75	25	-61	-29	73
40	25	29	93	93	-27
-1	-16	-14	48	99	-36
81	6	35	-90	4	-57
80	84	63	-10	80	-99
96	-5	-81	11	37	-46" > "$m1"
echo "-10	16	13	4	2	-4" > "$m2"
if [ $(( runFlag & MEAN )) -eq 0 ]
then

echo "Mean on hardcoded matrix:" | tee -a "$log"
message="Output result does not match known result"
expect_success 15 30 "./$cmd mean $m1" "$message" "$m2"
((points+=score))


generate 5 10 0 0 > "$m1"
generate 1 10 0 0 > "$m2"
echo "Mean on 5x10 zero matrix:" | tee -a "$log"
message="Output result does not match known result"
expect_success 2 30 "./$cmd mean $m1" "$message" "$m2"
((points+=score))


generate 5 10 1 1 > "$m1"
generate 1 10 1 1 > "$m2"
echo "Mean on 5x10 all ones matrix:" | tee -a "$log"
message="Output result does not match known result"
expect_success 5 30 "./$cmd mean $m1" "$message" "$m2"
((points+=score))


ident 10 10 > "$m1"
generate 1 10 0 0 > "$m2"
echo "Mean on 10x10 identity matrix:" | tee -a "$log"
message="Output result does not match known result"
expect_success 5 30 "./$cmd mean $m1" "$message" "$m2"
((points+=score))
fi


if [ $(( runFlag & ADD )) -eq 0 ]
then
generate 5 10 0 0 > "$m1"
generate 5 10 0 0 > "$m2"
echo "0 + 0 == 0?:" | tee -a "$log"
message="Output result does not match known result"
expect_success 2 30 "./$cmd add $m1 $m2" "$message" "$m1"
((points+=score))


generate 5 10 -100 100 > "$m1"
generate 5 10 0 0 > "$m2"
echo "X + 0 == X?:" | tee -a "$log"
message="Output result does not match known result"
expect_success 5 30 "./$cmd add $m1 $m2" "$message" "$m1"
((points+=score))


generate 5 10 0 0 > "$m1"
generate 5 10 -100 100 > "$m2"
echo "0 + X == X?:" | tee -a "$log"
message="Output result does not match known result"
expect_success 5 30 "./$cmd add $m1 $m2" "$message" "$m2"
((points+=score))


generate 10 10 -100 100 > "$m1"
generate 10 10 -100 100 > "$m2"
echo "A + B == B + A?:" | tee -a "$log"
message="The two results are not equal"
output=$(expect_success 1 30 "./$cmd add $m1 $m2")
result=$?
((tests+=1)) # Ran in subshell; tests won't be updated
if
    [ $result -eq 0 ]
then
    echo -e "$output"
fi
cp "$outpipe" "$outpipe2"
output=$(expect_success $result 30 "./$cmd add $m2 $m1")
score=$?
((tests+=1)) # Ran in subshell; tests won't be updated
if
    [ $score -eq 0 ]
then
    echo -e "$output"
fi
if
	! cmp -s "$outpipe" "$outpipe2"
then
	score=0
	echo -e "${FAIL}- The two results are not equal${ENDC}" | tee -a "$log"
fi
if [ $score -ne 0 ]
then
	echo -e "${OKGREEN}+ Passed!${ENDC}"
elif [ "$unitMode" -eq 0 ]; then
    exit "$score"
fi
((points+=score))



echo "68	86	-22	95	-97	44	68	-98	70	-65	69	94	-5	-84	3	83	71	31	-10	0
-82	74	-87	94	56	27	-45	-45	12	-75	-76	0	42	-76	75	14	21	-30	87	-8
-58	62	78	70	57	-93	2	-82	-2	-55	46	68	98	-91	40	73	-87	-45	58	78
45	45	42	93	47	-66	62	-70	84	92	82	-18	51	-55	-5	19	-16	58	-29	56
-95	-24	-72	23	40	67	-8	58	41	-5	54	-11	-22	68	73	90	92	20	89	39
74	-7	59	27	39	-97	-97	75	40	21	13	36	-83	-85	-84	-92	44	-7	83	-88
-33	-59	-91	-33	-23	-55	-77	-50	14	39	91	-39	58	-29	-75	-25	28	-84	-91	35
94	-78	97	24	94	-74	10	81	67	42	-67	-72	-66	-48	71	11	77	0	56	92
56	-36	70	-8	50	53	92	-81	99	45	96	-37	38	60	-37	61	-62	99	23	79
93	47	-87	-56	-60	-43	-7	75	82	-13	-81	-66	38	-23	30	-46	7	-30	-25	89
-8	73	1	-25	-53	-82	-82	23	0	-5	26	-13	-13	-4	-57	-52	26	96	-40	47
66	-83	84	-51	6	-5	62	-51	-54	-50	31	-6	88	55	-73	35	32	-91	-23	2
73	37	89	90	-45	89	-56	-12	3	79	-26	-18	81	93	-92	3	-17	23	-64	-4
-45	-57	59	-72	-84	44	38	70	47	-91	-10	-86	18	-40	-21	98	42	79	7	-80
-33	-93	78	-16	91	-62	55	82	-93	1	72	-31	-52	-8	-55	-89	66	-99	10	-25
64	-66	-56	19	19	80	-32	-16	73	10	25	-20	-57	30	29	81	30	-90	33	-54
68	-7	53	52	-55	-44	-94	-20	-76	29	88	33	-26	30	-45	90	-56	85	60	38
-28	17	90	-42	-35	87	-2	-47	94	-35	78	-33	59	-22	8	-5	0	-36	33	-27
-92	75	91	-97	19	76	33	20	-10	-80	-20	3	98	-35	75	-28	-48	-73	-68	72
17	45	43	-90	-12	4	86	-49	88	-92	39	-18	5	-10	-69	-5	-56	3	-21	10" > "$m1"
echo "24	52	55	-34	-9	74	-79	-78	5	-42	48	-53	-77	47	-53	97	-72	20	77	-28
-66	-54	72	-46	-25	53	-95	-3	-75	-62	92	-43	-57	0	78	-63	-90	12	-60	-77
65	43	-17	65	25	-77	57	27	71	98	83	53	28	-87	-56	-20	67	-3	-16	-61
-99	19	30	34	-10	-73	1	-18	7	99	-76	71	-72	-78	20	56	66	20	10	34
-54	-37	54	18	-11	56	-81	-97	64	-56	68	-36	25	-26	-56	91	-60	12	-9	17
-41	-78	-54	-19	-38	-76	17	-90	91	-5	82	-31	-92	93	-57	43	-56	14	29	-45
78	22	-94	12	-76	44	-63	-11	-11	-89	-81	53	56	6	27	30	-26	-79	-12	-50
52	15	-44	63	8	40	91	10	-26	-35	-61	21	-55	82	-97	-90	-25	10	-60	2
-33	-48	-46	-64	-41	-61	84	54	0	26	-56	75	-81	-53	-68	-2	-93	-46	29	85
53	-93	-31	51	78	75	69	10	-20	-68	-67	-67	-54	23	76	32	-11	-86	-55	-14
5	93	35	41	-26	41	77	88	43	44	-89	91	66	-11	90	-44	-61	-10	-66	-51
82	83	-44	55	69	80	1	-29	8	-87	-93	-91	-53	44	3	-3	24	13	86	33
92	5	-75	58	-4	-52	-2	-3	78	9	83	59	82	-4	-57	76	25	-49	-44	15
75	64	44	-23	43	56	60	0	46	26	39	53	-85	53	14	81	77	-11	-32	33
75	0	68	-5	-78	-13	90	-51	-15	-40	77	-95	-37	59	-20	30	38	-32	4	-76
-63	-28	58	-62	-42	93	15	79	32	-42	4	-98	85	-85	-31	-38	28	-31	-17	17
-65	-66	-8	26	-7	79	18	33	21	66	41	-22	20	66	-9	-64	-71	-67	-16	68
19	12	55	6	-90	-60	1	26	64	-29	62	96	89	11	-77	-26	76	-62	-48	-36
-76	-21	-93	85	-5	-99	41	-74	47	1	-44	47	16	83	30	-38	33	-53	80	-11
94	20	-76	-25	17	-5	3	-78	92	-33	-13	14	85	-52	-55	5	75	-89	9	-16" >"$m2"
echo "92	138	33	61	-106	118	-11	-176	75	-107	117	41	-82	-37	-50	180	-1	51	67	-28
-148	20	-15	48	31	80	-140	-48	-63	-137	16	-43	-15	-76	153	-49	-69	-18	27	-85
7	105	61	135	82	-170	59	-55	69	43	129	121	126	-178	-16	53	-20	-48	42	17
-54	64	72	127	37	-139	63	-88	91	191	6	53	-21	-133	15	75	50	78	-19	90
-149	-61	-18	41	29	123	-89	-39	105	-61	122	-47	3	42	17	181	32	32	80	56
33	-85	5	8	1	-173	-80	-15	131	16	95	5	-175	8	-141	-49	-12	7	112	-133
45	-37	-185	-21	-99	-11	-140	-61	3	-50	10	14	114	-23	-48	5	2	-163	-103	-15
146	-63	53	87	102	-34	101	91	41	7	-128	-51	-121	34	-26	-79	52	10	-4	94
23	-84	24	-72	9	-8	176	-27	99	71	40	38	-43	7	-105	59	-155	53	52	164
146	-46	-118	-5	18	32	62	85	62	-81	-148	-133	-16	0	106	-14	-4	-116	-80	75
-3	166	36	16	-79	-41	-5	111	43	39	-63	78	53	-15	33	-96	-35	86	-106	-4
148	0	40	4	75	75	63	-80	-46	-137	-62	-97	35	99	-70	32	56	-78	63	35
165	42	14	148	-49	37	-58	-15	81	88	57	41	163	89	-149	79	8	-26	-108	11
30	7	103	-95	-41	100	98	70	93	-65	29	-33	-67	13	-7	179	119	68	-25	-47
42	-93	146	-21	13	-75	145	31	-108	-39	149	-126	-89	51	-75	-59	104	-131	14	-101
1	-94	2	-43	-23	173	-17	63	105	-32	29	-118	28	-55	-2	43	58	-121	16	-37
3	-73	45	78	-62	35	-76	13	-55	95	129	11	-6	96	-54	26	-127	18	44	106
-9	29	145	-36	-125	27	-1	-21	158	-64	140	63	148	-11	-69	-31	76	-98	-15	-63
-168	54	-2	-12	14	-23	74	-54	37	-79	-64	50	114	48	105	-66	-15	-126	12	61
111	65	-33	-115	5	-1	89	-127	180	-125	26	-4	90	-62	-124	0	19	-86	-12	-6" >"$m3"
echo "(hardcoded) A + B == C?:" | tee -a "$log"
message="Output result does not match known result"
expect_success 15 30 "./$cmd add $m1 $m2" "$message" "$m3"
((points+=score))
fi

# echo "Total: $points" >&2
exit "$points"
