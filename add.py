#!/usr/bin/python

import os
import sys

#get a list of filenames from directory of interest
filenames=os.listdir(sys.argv[1])
d={}
print

#open the first file in the directory and write the output to a dictionary where key is the isoform name and val is the confusion matrix
with open(sys.argv[1] + "/" + filenames[0], 'r') as first_file:
    for line in first_file:
        line=line.strip('\n')
        key,val=line.split(",", 1)
        val=val.split(",")
        val=map(int,val)
        d[key]=val

os.remove(sys.argv[1] + "/" + filenames[0])

#loop through all the other files in the directory and convert their output to a key, val pair
for other_files in filenames[1:]:
    with open(sys.argv[1] + "/" + other_files, 'r') as other_file:
        for line in other_file:
            line=line.strip('\n')
            key,val=line.split(",", 1)
            val=val.split(",")
            val=map(int,val)
            #update confusion matrix array for each key in the dictionary
            d[key]=[x+y for x,y in zip(d[key], val)]

    os.remove(sys.argv[1] + "/" + other_files)

#Write the dictionary to the master file
with open(sys.argv[2], "w") as f:
    for item in d:
        f.write(item + "," + ",".join(map(str,d[item])) + "\n")
