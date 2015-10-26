#!/bin/bash

for file in *.change-to-mhtml
do
    mv -i "${file}" "${file/change-to-mhtml/mhtml}"
done
