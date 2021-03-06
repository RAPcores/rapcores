#! /usr/bin/env bash

directory="src/*"

# Synchronous assigns 
syncs="$(grep -nrP '(.*)([=<])(.*)(;)' $directory | grep -v 'assign\|wire\|reg\|parameter\|localparam\|for\|==\|<=\|>=\|!=\|<\|>' )"
printf "Synchronous assigns:\n"
echo "$syncs"

# Reg initialization - disallowed unless tagged "FPGA ONLY"
regs="$(grep -nrP '(reg)(\s*$)(.*)([=<])(.*)(;)' $directory | grep -v 'FPGA ONLY')"
printf "\nRegister initializations:\n"
echo "$regs"

# Stats
synccount=`printf "$syncs" | wc -l`
count=`printf "$regs" | wc -l`

printf "\n"
echo Synchronous count: $synccount
echo Register initialization count: $count


if [ $synccount -eq 0 ] && [ $count -eq 0 ]
  then
    exit 0
  else
    exit 1
fi