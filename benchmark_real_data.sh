#!/bin/bash
#Quantification pipeline

benchmark(){

  data=$2
  memory=`pwd`

  #If the SMEM index doesn't exist, make it
  if [ ! "$(ls -A Simulation/indices/Salmon_SMEM)" ]; then
    start_Salmon_SMEM_index=`date +%s`
    ./Simulation/Salmon-0.7.2_linux_x86_64/bin/salmon index -t Simulation/ref/reference.transcripts.fa -i Simulation/indices/Salmon_SMEM/transcripts_index_SMEM --type fmd -p 8
    stop_Salmon_SMEM_index=`date +%s`
    printf $data","$((stop_Salmon_SMEM_index-start_Salmon_SMEM_index)) >> Simulation/time_stats/time_Salmon_SMEM_index.csv
  fi

  #Run tool on simulated cells. Each cell is submitted as a seperate job.
  cd $data #This line needs to be edited to allow the user to input where the data is stored
  for i in $(find . -name '*_1.fastq*' -o -name '*_1.fq*');
  do
    base=`echo $i |awk -F/ '{print $2}'`
    filename=`echo $base |awk -F_ '{print $1}'`
    cd $memory
    #The line below will need to be edited for your LSF job system.
    bsub -n8 -R"span[hosts=1]" -c 99999 -G team_hemberg -q normal -o $TEAM/temp.logs/"output."$filename$1 -e $TEAM/temp.logs/"error."$filename$1 -R"select[mem>200000] rusage[mem=200000]" -M 200000 ./quantify_real_data.sh $1 $filename
  done

}

"$@"
