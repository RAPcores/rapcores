#! /usr/bin/env bash

# Synchronous assigns 
syncs="$(grep -nrP '(.*)([=<])(.*)(;)' src/* | grep -v 'assign' | grep -v 'wire' | grep -v 'parameter' | grep -v '==' | grep -v '<=')"
printf "Synchronous assigns:\n"
echo "$syncs"

# Reg initialization - disallowed
regs="$(grep -nrP '(reg)(.*)([=<])(.*)(;)' src/*)"
printf "\nRegister initializations:\n"
echo "$regs"

# Stats
synccount=`echo "$syncs" | wc -l`
count=`echo "$regs" | wc -l`

printf "\n"
echo Synchronous count: $synccount
echo Register initialization count: $count
