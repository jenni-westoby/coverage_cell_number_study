#!/bin/bash
#Run Salmon SMEM on cells

Salmon(){
  filename=$1
  #Salmon alignment free SMEM
  Simulation/Salmon-0.7.2_linux_x86_64/bin/salmon --no-version-check quant -i Simulation/indices/Salmon_SMEM/transcripts_index_SMEM -l A -1 $TEAM/BLUEPRINT_prac/$filename'_1.fq.gz' -2 $TEAM/BLUEPRINT_prac/$filename'_2.fq.gz' -o Simulation/Salmon_results/Salmon_SMEM_results_real_data/$filename -p 8

  rm -r Simulation/Salmon_results/Salmon_SMEM_results_real_data/$filename/aux_info
  rm -r Simulation/Salmon_results/Salmon_SMEM_results_real_data/$filename/cmd_info.json
  rm -r Simulation/Salmon_results/Salmon_SMEM_results_real_data_real_data/$filename/lib_format_counts.json
  rm -r Simulation/Salmon_results/Salmon_SMEM_results_real_data/$filename/libParams
  rm -r Simulation/Salmon_results/Salmon_SMEM_results_real_data/$filename/logs

#Sort the results file
echo "Name    Length  EffectiveLength TPM     NumReads" > Simulation/Salmon_results/Salmon_SMEM_results_real_data/$filename/quantsorted.sf
tail -n +2 Simulation/Salmon_results/Salmon_SMEM_results_real_data/$filename/quant.sf | sort -n -k1.8 >> Simulation/Salmon_results/Salmon_SMEM_results_real_data/$filename/quantsorted.sf
mv Simulation/Salmon_results/Salmon_SMEM_results_real_data/$filename/quantsorted.sf Simulation/Salmon_results/Salmon_SMEM_results_real_data/$filename/quant.sf

}

Kallisto() {

      #make a directory for the results of Kallisto for each cell
      filename=$1
      mkdir Simulation/Kallisto_results_real_data/$filename

      ./Simulation/kallisto_linux-v0.43.0/kallisto quant -i Simulation/indices/Kallisto/transcripts.idx --threads=8 --output-dir=Simulation/Kallisto_results_real_data/$filename $TEAM/BLUEPRINT_prac/$filename'_1.fq.gz' $TEAM/BLUEPRINT_prac/$filename'_2.fq.gz'

      echo "target_id       length  eff_length      est_counts      tpm" >> Simulation/Kallisto_results_real_data/$filename/abundancesorted.tsv
      tail -n +2 Simulation/Kallisto_results_real_data/$filename/abundance.tsv | sort -n -k1.8 >> Simulation/Kallisto_results_real_data/$filename/abundancesorted.tsv
      mv Simulation/Kallisto_results_real_data/$filename/abundancesorted.tsv Simulation/Kallisto_results_real_data/$filename/abundance.tsv

}

#!/bin/bash
#Quantification pipeline

RSEM(){

filename=$1


#RSEM
./Simulation/RSEM-1.3.0/rsem-calculate-expression --paired-end --star\
                  --star-gzipped-read-file --star-path Simulation/STAR/bin/Linux_x86_64 \
                  -p 8 \
      --append-names \
                  --single-cell-prior --calc-pme \
      $TEAM/BLUEPRINT_prac/$filename'_1.fq.gz' $TEAM/BLUEPRINT_prac/$filename'_2.fq.gz' \
      Simulation/ref/reference Simulation/RSEM_real_results/$filename


#Trim the text added to the transcript names in the results file
python ./trim.py `pwd` Simulation/RSEM_real_results/$filename'.isoforms.results'
mv Simulation/RSEM_real_results/'trimmed'$filename'.isoforms.results' Simulation/RSEM_real_results/$filename'.isoforms.results'

#Sort the results file
echo "transcript      gene_id length  effective_length        expected_count  TPM     FPKM    IsoPct  posterior_mean_count    posterior_standard_deviation_of_count   pme_TPM pme_FPKM        IsoPct_from_pme_TPM" > Simulation/RSEM_real_results/$filename'.sortedisoforms.results'
tail -n +2  Simulation/RSEM_real_results/$filename'.isoforms.results' | sort -n -k1.8 >> Simulation/RSEM_real_results/$filename'.sortedisoforms.results'
mv Simulation/RSEM_real_results/$filename'.sortedisoforms.results' Simulation/RSEM_real_results/$filename'.isoforms.results'


}

"$@"
