#!/bin/bash
for file in *.in; do ruby main.rb "$file"; done
