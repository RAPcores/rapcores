#! /usr/bin/env bash

for file in *.md
do
    aspell check --mode=markdown --lang=en "$file"
done