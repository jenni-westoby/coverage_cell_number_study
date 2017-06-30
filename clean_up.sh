#!/usr/bin/env bash

read_array=(1000 2000 3000)
for k in "${read_array[@]}";
do
  for l in $(seq 1 $i);
  do
    #TODO
    #check filenumbers in dirs and check no temp files present
    file_number=`ls Simulation/confusion_matrices_dropouts/coverage_$num_cells"_"$k"_"$l | wc -l | awk '{print $1}'`
    echo "file_number "$file_number
    #if exceed threshold
    if [ "$file_number" -ge "$threshold" ];
    then
      #mkdir Simulation/confusion_matrices_dropouts/tmp_coverage_$num_cells"_"$k"_"$l
      echo "file number greater than threshold"
      file_names=`ls Simulation/confusion_matrices_dropouts/coverage_$num_cells"_"$k"_"$l`
      #move all the completed files into a temporary directory
      for file in $file_names:
      do
        num_lines=`wc -l Simulation/confusion_matrices_dropouts/coverage_$num_cells"_"$k"_"$l/$file | awk '{print $1}'`
        echo "num_lines "$num_lines
        if [ "$num_lines" -ne "111799" ];
        then
          echo "wrong number of lines in some files...exiting"
          continue 2
          #mv Simulation/confusion_matrices_dropouts/coverage_$num_cells"_"$k"_"$l/$file Simulation/confusion_matrices_dropouts/tmp_coverage_$num_cells"_"$k"_"$l/$file
        fi
      done

      #pause ongoing jobs (only normal - final_coverage_script.sh itself should be submitted as a long job). First sleep for 30 to give time for recently submitted jobs to appear in bjobs
      sleep 30
      ongoing_jobs=`bjobs | grep 'normal' | awk '{print $1}'`
      echo "ongoing_jobs "$ongoing_jobs
      echo "ongoing "$ongoing
      if [ "$ongoing" == "true" ];
      then
        for job in $ongoing_jobs;
        do
          bstop $job
          echo "job "$job
        done
        ongoing="false"
        sleep 600
      fi

      #call a function to add up all files
      mkdir Simulation/tmp_dropouts
      python add.py Simulation/confusion_matrices_dropouts/coverage_$num_cells"_"$k"_"$l Simulation/tmp_dropouts/coverage_$num_cells"_"$k"_"$l"_master.txt"
      #rm Simulation/confusion_matrices_dropouts/tmp_coverage_$num_cells"_"$k"_"$l
    fi
  done
done
