#!/bin/sh
gcc -o main fuzzgoat.c main.c

# integer buffer overflow only accept range between [0, 2^31-1] 
for FILE in "/Users/oliviajohansen/Desktop/CS4239/fuzzgoat/input-files/ints"/*; do
    printf "\n";
    echo ${FILE:46:30}; 
    ./main $FILE;
done

# stack buffer overflow - overwrite return addr when string length >= 60
for FILE in "/Users/oliviajohansen/Desktop/CS4239/fuzzgoat/input-files/strings"/*; do
    printf "\n";
    echo ${FILE:46:30}; 
    ./main $FILE;
done

# heap buffer overflow - overwrite previous field in struct when the ((int) double) is in range [-4, -1]
for FILE in "/Users/oliviajohansen/Desktop/CS4239/fuzzgoat/input-files/doubles"/*; do
    printf "\n";
    echo ${FILE:46:35}; 
    ./main $FILE;
done

# Use after free when input is empty array
echo "running input-files/emptyArray"
./main input-files/emptyArray

# double free when input is array of length 12
echo "running input-files/arrayLenTwelve"
./main input-files/arrayLenTwelve

# invalid free when input is valid json obj (undefined behaviour - no err on mac m1)
# not sure while validObject4 segfaults why validObject2 does not
for FILE in "/Users/oliviajohansen/Desktop/CS4239/fuzzgoat/input-files/objects"/*; do
    printf "\n";
    echo ${FILE:46:35}; 
    ./main $FILE;
done

# invalid free 
echo "running input-files/emptyString"
./main input-files/emptyString

# null pointer deref 
echo "running input-files/oneByteString"
./main input-files/oneByteString

# format string vulnerabilities - mismatch num of arguments when string input is length 6 (excl quotation marks)
echo "running input-files/sixByteString"
./main input-files/sixByteString
