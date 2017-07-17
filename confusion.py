#!/usr/bin/python

import sys

#rename input args
truth_file=sys.argv[1]
salmon_file=sys.argv[2]
outfile=sys.argv[3]

#Function that takes two floats as input and returns a confusion matrix
def confusion_mat(val_truth,val_estimate):
    if isinstance(val_truth,float)==False or isinstance(val_estimate,float)==False:
        raise TypeError("Non floats passed to confusion_mat function")
    confusion=[0,0,0,0]
    if val_truth>0 and val_estimate>0:
        confusion[0]=1
    elif val_truth>0 and val_estimate==0:
        confusion[1]=1
    elif val_truth==0 and val_estimate>0:
        confusion[2]=1
    else:
        confusion[3]=1
    return confusion

#for testing whilst writing code
#truth_file="salmon_test.txt"
#salmon_file="ground_test.txt"
#outfile="test.txt"

#Function that creates new file of confusion matrices
def make_confusion(truth_file, salmon_file, outfile):

    #write cell number at top of outfile
    with open(outfile, "w") as f:
        f.write("cell_number,1\n")

    #open truth file and skip first line
    with open(truth_file,"r") as truth:
        next(truth)
        #open salmon file and make readlines array
        with open(salmon_file, "r") as estimate:
            line_estimate=estimate.readlines()
            counter=0

            for line_truth in truth:
                #increment counter, initialise confusion matrix, create key (transcript name) and value (expression estimate) for truth and estimate
                counter = counter + 1
                line_truth=line_truth.strip('\n')
                key_truth,val_truth=line_truth.split("\t", 1)
                line_est=line_estimate[counter].strip('\n')
                key_estimate,val_estimate=line_est.split("\t", 1)

                #give an error message and exit if keys don't match
                if key_truth!=key_estimate:
                    print("rownames don't match - check files are correctly sorted")
                    sys.exit()

                #convert vals to floats
                val_truth=float(val_truth)
                val_estimate=float(val_estimate)

                confusion=confusion_mat(val_truth, val_estimate)

                #write results out to file
                with open(outfile, "a+") as f:
                    f.write(key_truth + "," + ",".join(map(str,confusion)) + "\n")

make_confusion(truth_file,salmon_file,outfile)
