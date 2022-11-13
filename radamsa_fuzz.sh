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
declare -i unique_err_code_count = 0
declare -i err_code_one_count = 0

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
echo "crashes : total runs is $exitWithFailureCount : $totalCount";
for key in "${!error_codes_dict[@]}"; do
    echo -n "error code $key occured ${error_codes_dict[$key]} times";
    if [ $key == 1 ] 
    then echo -n " (ignore - due to invalid parsing of data structure)";
    elif [ $key == 139 ]
    then echo -n " (SEGFAULT)";
    elif [ $key == 138 ]
    then echo -n " (SIGBUS)";
    elif [ $key == 136 ]
    then echo -n "(SIGFPE) - floating point err or integer overflow";
    elif [ $key == 134 ]
    then echo -n " (SIGABRT)"
    elif [ $key == 0 ]
    then echo -n " (OK)";
    fi
    echo "."

    if [ $key != 1 ] 
    then 
      let unique_err_code_count++
    fi
done
err_code_one_count=$(( error_codes_dict[1] ))
echo "excluding exit code 1, crashes : total runs is $((exitWithFailureCount-err_code_one_count)) : $((totalCount-err_code_one_count))"
echo "unique crashes count: $unique_err_code_count"
