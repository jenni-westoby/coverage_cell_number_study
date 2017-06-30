#!/usr/bin/env bash
#script which simulates data at varying cell number and read number

#Function which submits RSEM simulations as LSF style jobs. Takes one arg, the directory where the data to be simulated is stored. Checks number of arguments and calls set_of_simulations
run_simulations(){
  if [ $# -ne 2 ]
    then
      echo "Incorrect number of arguments supplied. Two arguments should be passed to this function. The first argument should be the path to the directory in which the data is stored. The second should be
 the number of cells to simulate."
      exit 1
  fi

  #make results directories
  mkdir Simulation/confusion_matrices_dropouts
  mkdir Simulation/coverage
  mkdir Simulation/Salmon_SMEM_coverage_results
  mkdir Simulation/Salmon_coverage_matrices
  mkdir Simulation/coverage_matrices

  num_cells=$2

  #if number of files in the confusion matrix directory equals some kind of threshold, I need to add files together. This threshold should be the total cell number.
  threshold=$num_cells

  echo "threshold before set_of_simulations "$threshold

  #perform simulations at each read number
  #read_number=( 250000 500000 1000000 2000000 4000000 8000000 16000000 )
  read_number=(1000 2000 3000)
  for i in "${read_number[@]}";
  do
    set_of_simulations $1 $num_cells $i $threshold
  done
}

#Function which takes the path to the raw data directory, the number of cells to simulate and the read number to simulate at as input arguments.
#Sets up for simulate
set_of_simulations() {

  raw_data_dir=${1%/}
  echo "raw_data_dir "$raw_data_dir
  num_cells=$2
  echo "num_cells "$num_cells
  read_number=$3
  echo "read_number "$read_number
  threshold=$4
  echo "threshold "$threshold
  #ongoing is equal to true when jobs are not suspended
  ongoing="true"

  #There are 10 rounds of simulations per cell number and read number
  for i in {1..10};
  do
    mkdir Simulation/confusion_matrices_dropouts/coverage_$num_cells"_"$read_number"_"$i

    for j in $(seq 1 $num_cells);
    do
      #Make directorys for simulation results and for salmon results
      mkdir Simulation/coverage/coverage_$num_cells'_'$read_number'_'$i'_'$j
      mkdir Simulation/Salmon_SMEM_coverage_results/coverage_$num_cells'_'$read_number'_'$i'_'$j

      #Perform the simulation
      bsub -n4 -R"span[hosts=1]" -c 99999 -G team_hemberg -q normal -o $TEAM/temp.logs/output.coverage_$num_cells'_'$read_number'_'$i'_'$j -e $TEAM/temp.logs/error.coverage_$num_cells'_'$read_number'_'$i'_'$j -R"select[mem>10000] rusage[mem=10000]" -M10000 simulate $raw_data_dir $read_number coverage_$num_cells'_'$read_number'_'$i'_'$j Simulation/confusion_matrices_dropouts/coverage_$num_cells"_"$read_number"_"$i

      read_array=(1000 2000 3000)
      for k in "${read_array[@]}";
      do
        for l in $(seq 1 10);
        do
          #TODO
          #check filenumbers in dirs and check no temp files present
          file_number=`ls Simulation/confusion_matrices_dropouts/coverage_$num_cells"_"$k"_"$l | wc -l | awk '{print $1}'`
          echo "file_number "$file_number
          #if exceed threshold
          if [ "$file_number" -eq "$threshold" ];
          then
            #mkdir Simulation/confusion_matrices_dropouts/tmp_coverage_$num_cells"_"$k"_"$l
            echo "file number greater than threshold"
            dir="Simulation/confusion_matrices_dropouts/coverage_$num_cells"_"$k"_"$l"
            #move all the completed files into a temporary directory
            for file in "$dir"/*
            do
              num_lines=`wc -l $file | awk '{print $1}'`
              echo "num_lines "$num_lines
              if [ "$num_lines" -ne 111799 ];
              then
                echo "wrong number of lines in some files...exiting"
                continue 2
              fi
            done

            #pause ongoing jobs (only normal - final_coverage_script.sh itself should be submitted as a long job). First sleep for 30 to give time for recently submitted jobs to appear in bjobs
            sleep 60
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

      #if jobs were stopped, restart them
      if [ "$ongoing" == "false" ];
      then
        for job in $ongoing_jobs;
        do
          bresume $job
        done

        #give jobs some time to actually run
        sleep 300
      fi




      num_jobs=`bjobs | wc -l`
      max_jobs=30

      #This prevents the number of queued jobs greatly exceeding 30.
      while [[ $num_jobs -gt $max_jobs ]];
      do
        sleep 100
        num_jobs=`bjobs | wc -l`
      done
    done
  done

}


#Function which takes the path to the raw data directory, a filename, the read number to simulate at, a seed and an outdir as input args and performs simulations
simulate() {

  raw_data_dir=${1%/}
  read_number=$2
  outdir=$3
  confusion_dir=$4
  cell_number=`echo $outdir | awk -F_ '{print $2}'`
  read_coverage=`echo $outdir | awk -F_ '{print $3}'`
  simulation_num=`echo $outdir | awk -F_ '{print $4}'`
  cell_of_total=`echo $outdir | awk -F_ '{print $5}'`

  #Randomly select a file
  memory=`pwd`
  cd $raw_data_dir
  echo "line 62 "$raw_data_dir
  filename=`find . -name '*_1.fastq*' -o -name '*_1.fq*' | grep 'B' | sort -R | tail -1`

  #Make filename strings
  base=`echo $filename |awk -F/ '{print $2}'`
  filename=`echo $base | rev | cut -d _ -f2- | rev`
  cd $memory
  echo "line 69 "$memory

  #Randomly select a seed
  seed=`shuf -i 0-4294967295 -n 1`

  #Extract first number of third line of filename.theta, which is an estimate of the portion of reads due to background noise
  background_noise=`sed '3q;d' Simulation/RSEM_real_results/$filename".stat"/$filename".theta" | awk '{print $1}'`


  #Simulate reads
  ./Simulation/RSEM-1.3.0/rsem-simulate-reads Simulation/ref/reference Simulation/RSEM_real_results/$filename".stat"/$filename".model" \
                        Simulation/RSEM_real_results/$filename".isoforms.results" $background_noise $read_number Simulation/coverage/$outdir/$seed$filename \
                        --seed $seed



  #Run salmon
  Salmon $seed$filename $outdir

  #Create results matrix for ground truth
  python generate.py $outdir `pwd` Simulation/coverage/$outdir
  chmod +x $outdir'_TPM.sh'
  ./$outdir'_TPM.sh'
  rm $outdir'_TPM.sh'

  #Tidy up ground truth results matrix
  coverage_matrix_name=$outdir"_TPM.txt"
  sed 's/"//g' Simulation/coverage_matrices/$coverage_matrix_name | sed "s|/lustre/scratch117/cellgen/team218/jw28/BLUEPRINT_wkdir/Benchmarking_pipeline/Simulation/coverage/$outdir/||g" | sed 's/.sim.isoforms.results//g' > Simulation/coverage_matrices/clean_$coverage_matrix_name
  mv Simulation/coverage_matrices/clean_$coverage_matrix_name Simulation/coverage_matrices/$coverage_matrix_name
  head -n 1 Simulation/coverage_matrices/$coverage_matrix_name > Simulation/coverage_matrices/clean_$coverage_matrix_name
  tail -n +2  Simulation/coverage_matrices/$coverage_matrix_name | sort -n -k1.8 >> Simulation/coverage_matrices/clean_$coverage_matrix_name
  mv Simulation/coverage_matrices/clean_$coverage_matrix_name Simulation/coverage_matrices/$coverage_matrix_name
  #Add a line sorting the matrix

  #Create results matrices for Salmon
  python generate_Salmon_coverage.py $outdir `pwd` Simulation/Salmon_SMEM_coverage_results/$outdir
  chmod +x $outdir'_TPM.sh'
  ./$outdir'_TPM.sh'
  rm $outdir'_TPM.sh'

  #Tidy up Salmon results matrix
  sed 's/"//g' Simulation/Salmon_coverage_matrices/$coverage_matrix_name | sed "s|/lustre/scratch117/cellgen/team218/jw28/BLUEPRINT_wkdir/Benchmarking_pipeline/Simulation/Salmon_SMEM_coverage_results/$outdir/||g" | sed 's|/quant.sf||g' > Simulation/Salmon_coverage_matrices/clean_$coverage_matrix_name
  mv Simulation/Salmon_coverage_matrices/clean_$coverage_matrix_name Simulation/Salmon_coverage_matrices/$coverage_matrix_name
  head -n 1 Simulation/Salmon_coverage_matrices/$coverage_matrix_name > Simulation/Salmon_coverage_matrices/clean_$coverage_matrix_name
  tail -n +2  Simulation/Salmon_coverage_matrices/$coverage_matrix_name | sort -n -k1.8 >> Simulation/Salmon_coverage_matrices/clean_$coverage_matrix_name
  mv Simulation/Salmon_coverage_matrices/clean_$coverage_matrix_name Simulation/Salmon_coverage_matrices/$coverage_matrix_name


  #delete data except results matrices
  rm -r Simulation/coverage/$outdir
  rm -r Simulation/Salmon_SMEM_coverage_results/$outdir

  #find statistics using R
  /software/R-3.3.0/bin/Rscript ./find_coverage_stats.R Simulation/coverage_matrices/$coverage_matrix_name Simulation/Salmon_coverage_matrices/$coverage_matrix_name $cell_number $read_coverage $simulation_num $cell_of_total

  echo /software/R-3.3.0/bin/Rscript ./find_coverage_stats.R Simulation/coverage_matrices/$coverage_matrix_name Simulation/Salmon_coverage_matrices/$coverage_matrix_name $cell_number $read_coverage $simulation_num $cell_of_total


  #write to an output file
  line=$(head -n 2 $outdir | tail -n 1 )
  echo $line >> Simulation/coverage_statistics.txt
  rm $outdir

  #run a piece of code that takes salmon and coverage as input and returns a table of TP,FP,FN and TN
  python confusion.py Simulation/coverage_matrices/$coverage_matrix_name Simulation/Salmon_coverage_matrices/$coverage_matrix_name $confusion_dir/$coverage_matrix_name

  #delete results matrices
  rm Simulation/Salmon_coverage_matrices/$coverage_matrix_name
  rm Simulation/coverage_matrices/$coverage_matrix_name

}


Salmon() {
  #rename input args
  filename=$1
  directory=$2

  #make directory to store output isoform quantification estimates
  mkdir Simulation/Salmon_SMEM_coverage_results/$directory/$filename

  #execute Salmon
  Simulation/Salmon-0.8.2_linux_x86_64/bin/salmon --no-version-check quant -i Simulation/indices/Salmon_SMEM/transcripts_index_SMEM -l A -1 Simulation/coverage/$directory/$filename'_1.fq' -2 Simulation/coverage/$directory/$filename'_2.fq' -o Simulation/Salmon_SMEM_coverage_results/$directory/$filename -p 8

  #Tidy up
  rm -r Simulation/Salmon_SMEM_coverage_results/$directory/$filename/aux_info
        rm -r Simulation/Salmon_SMEM_coverage_results/$directory/$filename/cmd_info.json
        rm -r Simulation/Salmon_SMEM_coverage_results/$directory/$filename/lib_format_counts.json
        rm -r Simulation/Salmon_SMEM_coverage_results/$directory/$filename/libParams
        rm -r Simulation/Salmon_SMEM_coverage_results/$directory/$filename/logs

  #Sort the results file
  echo "Name    Length  EffectiveLength TPM     NumReads" > Simulation/Salmon_SMEM_coverage_results/$directory/$filename/quantsorted.sf
  tail -n +2 Simulation/Salmon_SMEM_coverage_results/$directory/$filename/quant.sf | sort -n -k1.8 >> Simulation/Salmon_SMEM_coverage_results/$directory/$filename/quantsorted.sf
  mv Simulation/Salmon_SMEM_coverage_results/$directory/$filename/quantsorted.sf Simulation/Salmon_SMEM_coverage_results/$directory/$filename/quant.sf

}


export -f Salmon
export -f simulate
export -f set_of_simulations

"$@"
