#!/bin/sh
gcc -o main fuzzgoat.c main.c

# # tar -czf strings_zip.tar.gz ./input-files/strings

# # /Users/oliviajohansen/Desktop/CS4239/fuzzgoat/strings_zip.tar.gz

# radamsa/bin/radamsa /Users/oliviajohansen/Desktop/CS4239/fuzzgoat/strings_zip.tar.gz > fuzzed.gz
# # gzip -dc fuzzed.gz
# # test $? -gt 127 && break

# # bc sample-* < /dev/null
# # radamsa/bin/radamsa /Users/oliviajohansen/Desktop/CS4239/fuzzgoat/input-files/sixByteString

#  while true
#  do
path=/Users/oliviajohansen/Desktop/CS4239/fuzzgoat/input-files
rootPath=/Users/oliviajohansen/Desktop/CS4239/fuzzgoat
# /Users/oliviajohansen/Desktop/CS4239/fuzzgoat/input-files/sixByteString
radamsa/bin/radamsa -o fuzz-%n -n 10 $path/doubles/validDouble 
# $path/ints/zero $path/ints/validInt $path/validObject $path/validObject2 $path/shortString $path/twentyByteString $path/sixByteString
#    bc fuzz-* < /dev/null
declare -A error_codes_dict
declare -i exitWithFailureCount = 0
declare -i totalCount = 0
declare -i exit = 0
declare -i err_code_count = 0

for FILE in "/Users/oliviajohansen/Desktop/CS4239/fuzzgoat"/fuzz-*; do
    printf "\n";
    echo ${FILE:45:30}; 
    let totalCount++
    ./main $FILE;
    exit=`echo $?`
    echo "exit $exit"

    if [ $exit != '0' ]
    then
      let exitWithFailureCount++
    fi 

    if [[ -v error_codes_dict[$exit] ]]
    then 
    echo "contains $exit"
    err_code_count=$((error_codes_dict[$exit]+1))
    echo "new err_code count $err_code_count"
    error_codes_dict[$exit]=$(( err_code_count ))
    else 
    echo "does not contain $exit"
    error_codes_dict[$exit]=1
    fi
done

printf "\n---------------------------SUMMARY---------------------------\n";
echo "exit with failure count : total count is $exitWithFailureCount : $totalCount";
for key in "${!error_codes_dict[@]}"; do
    echo "error code $key occured ${error_codes_dict[$key]} times"
done


