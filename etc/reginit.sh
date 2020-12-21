#! /usr/bin/env bash

# Reg initialization - disallowed

grep -nrP '(reg)(.*)([=<])(.*)(;)' src/*

grep -nrP '(.*)([=<])(.*)(;)' src/* | grep -v 'assign' | grep -v 'wire' | grep -v '<='
