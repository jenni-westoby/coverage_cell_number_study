#!/usr/bin/env bash

read_array=( 250000 500000 1000000 2000000 4000000 8000000 16000000 )
num_cells=$1
for k in "${read_array[@]}";
do
  for l in $(seq 1 10);
  do
    #TODO
    #check filenumbers in dirs and check no temp files present
    file_number=`ls Simulation/confusion_matrices_dropouts/coverage_$num_cells"_"$k"_"$l | wc -l | awk '{print $1}'`
    echo "file_number "$file_number
    #if exceed threshold
    if [ "$file_number" -eq "$num_cells" ];
    then
      #mkdir Simulation/confusion_matrices_dropouts/tmp_coverage_$num_cells"_"$k"_"$l
      echo "file number greater than threshold"
      dir="Simulation/confusion_matrices_dropouts/coverage_$num_cells"_"$k"_"$l"
      #file_names=`ls Simulation/confusion_matrices_dropouts/coverage_$num_cells"_"$k"_"$l`
      #move all the completed files into a temporary directory
      for file in "$dir"/*
      do
        num_lines=`wc -l $file | awk '{print $1}'`
        echo "num_lines "$num_lines
        if [ "$num_lines" -ne 111799 ];
        then
          echo "wrong number of lines in some files...exiting"
          continue 2
          #mv Simulation/confusion_matrices_dropouts/coverage_$num_cells"_"$k"_"$l/$file Simulation/confusion_matrices_dropouts/tmp_coverage_$num_cells"_"$k"_"$l/$file
        fi
      done
      python add.py Simulation/confusion_matrices_dropouts/coverage_$num_cells"_"$k"_"$l Simulation/tmp_dropouts/coverage_$num_cells"_"$k"_"$l"_master.txt"
      #rm Simulation/confusion_matrices_dropouts/tmp_coverage_$num_cells"_"$k"_"$l
    fi
  done
done

mkdir Simulation/tmp
cd Simulation/tmp_dropouts

for i in *
do
grep -v "cell_number" $i > ../tmp/$i
done

cd ..
rm -r tmp_dropouts
mv tmp tmp_dropouts
