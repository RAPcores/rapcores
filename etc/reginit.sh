#! /usr/bin/env bash

grep -nrP '(reg)(.*)([=<])(.*)(;)' src/*
