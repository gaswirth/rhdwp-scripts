#!/bin/bash

for D in ./*; do
	if [ -d "$D" ]; then
		echo "$D"
		cd "$D"
		./build.sh
		cd ..
	fi
done
