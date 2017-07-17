# coverage_cell_number_study

Prerequisites:

-virtualenv

-github account

-reference genome gtf and fasta files. Note that if your data contains ERRCC spike-ins, you should concatenate the reference genome gtf file with the ERRCC gtf file, and concatenate the reference and ERRCC fastq files (see https://tools.thermofisher.com/content/sfs/manuals/cms_095048.txt)

-directory containing single cell RNA-seq data. This data should be demultiplexed, have any adaptors trimmed and should be in the format of gzipped fastq files.

To run the pipeline:

1. Execute ./setup.sh setup. This will create a new directory called Simulation into which all the software required for this pipeline will be locally installed. In addition, empty directories are created within the Simulation directory which will eventually contain the RSEM references, various indices, the raw and simulated data, results matrices and graphs. This step will take ~30 minutes - 1 hour depending on your network speed.

2. Execute ./RSEM_ref.sh make_ref /path/to/gtf path/to/fasta, where the gtf and fasta files are the reference genome. This builds the RSEM reference.

3. Execute ./benchmark_real_data.sh benchmark RSEM /path/to/data, where the data is your demultiplexed adaptor trimmed fastq files.

4. Execute ./final_coverage_script.sh run_simulations /path/to/data number_of_cells, where data is your demultiplexed adaptor trimmed fastq files and number_of_cells is the number of cells you want to simulate. Note that this program should be executed once for each number of cells you want to simulate. It is recommended that you wait until the program completes for that cell number before rerunning the program at a different cell number

5. Execute ./clean_up.sh number_of_cells.

