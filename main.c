/* vim: set et ts=4
 *
 * Copyright (C) 2015 Mirko Pasqualetti  All rights reserved.
 * https://github.com/udp/json-parser
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <limits.h>
#include <string.h>

#include "fuzzgoat.h"


static void print_depth_shift(int depth)
{
        int j;
        for (j=0; j < depth; j++) {
                printf(" ");
        }
}

static void process_value(json_value* value, int depth, int len);

static void process_object(json_value* value, int depth)
{
        int length, x;
        if (value == NULL) {
                return;
        }
        length = value->u.object.length;
        for (x = 0; x < length; x++) {
                print_depth_shift(depth);
                printf("object[%d].name = %s\n", x, value->u.object.values[x].name);
                process_value(value->u.object.values[x].value, depth+1, -1);
        }
}

static void process_array(json_value* value, int depth)
{
        int length, x;
        if (value == NULL) {
                return;
        }
        length = value->u.array.length;
        printf("array\n");
        for (x = 0; x < length; x++) {
                process_value(value->u.array.values[x], depth, -1);
        }
}

// Adapted from CS4239 Lab7 ex3
static void f(char* str, int len) { // vulnerable to stack buffer overflow, overwriting the return address/instr of this function
        char buf[60]; 
        char c;
        int i;

        /******************************************************************************
	WARNING: Fuzzgoat Vulnerability
	
	The line of code below assigns each element in char* str to char buf[]

	Diff       - Added: for (i = 0; i < len; i++) buf[i] = c;
	Payload    - String length greater than or equal to 60 (excl the quotation marks)
        Input File - longString, twentyByteString
	Triggers   - Writing out of bounds/ into unallocated memory
        ******************************************************************************/

        for (i = 0; i < len; i++) buf[i] = c;
        /****** END vulnerable code **************************************************/
        buf[i] = '\0';
} 

static void process_value(json_value* value, int depth, int file_size)
{
        int j, i;
        int* x;
        int* y;
        uint64_t ui;
        char* str;
        double d;
        
        if (value == NULL) {
                return;
        }
        if (value->type != json_object) {
                print_depth_shift(depth);
        }
        switch (value->type) {
                case json_none: // test double free
                        printf("none\n");
                        break;
                case json_object:
                        process_object(value, depth+1);
                        break;
                case json_array:
                        process_array(value, depth+1);
                        break;
                case json_integer:
                        ui = value->u.integer;
                        /******************************************************************************
                        WARNING: Fuzzgoat Vulnerability
                        
                        The line of code below will catch the case when the int input is not within the 
                        signed int range on a 64 bit machine: [0, 2^31-1] 

                        Diff       - see below
                        Payload    - Outside range: [0, 2^31-1] 
                        Input File - intMaxPlusOne, uintMaxPlusOne, uintMaxTimesTwo, negativeInt
                        Triggers   - Integer overflow
                        ******************************************************************************/
                        if (ui > INT_MAX || INT_MAX - ui < 0) {
                         printf("overflow detected in %llu\n", ui);
                         abort();
                        /****** END vulnerable code **************************************************/
                        } else {
                         printf("int: %10" PRId64 "\n", value->u.integer);
                        }
                        break;
                case json_double:
                        d = value->u.dbl;
                        printf("double: %f\n", d);
                        i = d;
                        if (i >= -4 && i <= -1) {
                                y = malloc(sizeof(int));
                                x = malloc(sizeof(int));
                                y[0] = 0;
                                /******************************************************************************
                                WARNING: Fuzzgoat Vulnerability
                                
                                The line of code below will heap overflow to write to another field.

                                Diff       - x[-4] = 9;
                                Payload    - range: [-4, -1] 
                                Input File - invalidDouble
                                Triggers   - Heap buffer overflow
                                ******************************************************************************/
                                x[-4] = 9;
                                /****** END vulnerable code **************************************************/
                                printf("heap buffer overflow detected, y[0] = %d\n", y[0]);
                                abort();
                        }
                        break;
                case json_string:
                        str = value->u.string.ptr;
                        printf("string: %s\n", str);
                        if (file_size != -1) f(str, file_size - 2); // - 2 to substract the front and back quotation marks
                        if (file_size - 2 == 6) printf("%s%s%s", str);
                        printf("Here99");
                        break;
                case json_boolean:
                        printf("bool: %d\n", value->u.boolean);
                        break;
                case json_null: 
                        // will never reach here because of a previous check for null
                        break;
        }
}

int main(int argc, char** argv)
{
        char* filename;
        FILE *fp;
        struct stat filestatus;
        int file_size;
        char* file_contents;
        json_char* json;
        json_value* value;

        if (argc != 2) {
                fprintf(stderr, "%s <file_json>\n", argv[0]);
                return 1;
        }
        filename = argv[1];

        if ( stat(filename, &filestatus) != 0) {
                fprintf(stderr, "File %s not found\n", filename);
                return 1;
        }
        file_size = filestatus.st_size;
        file_contents = (char*)malloc(filestatus.st_size);
        if ( file_contents == NULL) {
                fprintf(stderr, "Memory error: unable to allocate %d bytes\n", file_size);
                return 1;
        }

        fp = fopen(filename, "rt");
        if (fp == NULL) {
                fprintf(stderr, "Unable to open %s\n", filename);
                fclose(fp);
                free(file_contents);
                return 1;
        }
        if ( fread(file_contents, file_size, 1, fp) != 1 ) {
                fprintf(stderr, "Unable t read content of %s\n", filename);
                fclose(fp);
                free(file_contents);
                return 1;
        }
        fclose(fp);

        printf("%s\n", file_contents);

        printf("--------------------------------\n\n");

        json = (json_char*)file_contents;

        value = json_parse(json,file_size);

        if (value == NULL) {
                fprintf(stderr, "Unable to parse data\n");
                free(file_contents);
                exit(1);
        }

        process_value(value, 0, file_size);
        json_value_free(value);
        free(file_contents);
        return 0;
}
