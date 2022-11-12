#!/bin/sh
gcc -o main fuzzgoat.c main.c

path=/Users/oliviajohansen/Desktop/CS4239/fuzzgoat/input-files
rootPath=/Users/oliviajohansen/Desktop/CS4239/fuzzgoat

radamsa/bin/radamsa -o fuzz-%n -n 10000 sample-*

declare -A error_codes_dict
declare -i exitWithFailureCount = 0
declare -i totalCount = 0
declare -i exit = 0
declare -i err_code_count = 0

for FILE in "/Users/oliviajohansen/Desktop/CS4239/fuzzgoat"/fuzz-*; do
    printf "\n";
    let totalCount++
    ./main $FILE;
    exit=`echo $?`

    if [ $exit != '0' ]
    then
      let exitWithFailureCount++
    fi 

    if [[ -v error_codes_dict[$exit] ]]
    then 
    err_code_count=$((error_codes_dict[$exit]+1))
    error_codes_dict[$exit]=$(( err_code_count ))
    else 
    error_codes_dict[$exit]=1
    fi
done

printf "\n---------------------------------------SUMMARY---------------------------------------\n";
echo "exit with failure count : total count is $exitWithFailureCount : $totalCount";
for key in "${!error_codes_dict[@]}"; do
    printf("error code $key occured ${error_codes_dict[$key]} times");
    if [ $key == 1 ] 
    then printf(" (ignore - due to invalid parsing of data structure)")
    else if [ $key == 139]
    then printf(" (Segfault)")
    else if [ $key == 138]
    then printf( " (SIGBUS)")
    else if [ $key == 136 ]
    then printf( "(SIGFPE) - floating point err or interger overflow")
    else if [ $key == 0 ]
    then printf( "(OK)")
    fi
    printf("\n")
done


