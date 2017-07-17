#!/bin/bash
#Note users will require a github account and need to have virtualenv installed

setup(){

#First make a directory in which simulation data and programs will be kept
mkdir ./Simulation

#Install programs in directory
cd Simulation

#Install RSEM
wget https://github.com/deweylab/RSEM/archive/v1.3.0.tar.gz
tar -xvzf v1.3.0.tar.gz
rm v1.3.0.tar.gz
cd RSEM-1.3.0
make
make install prefix=.
cd ..
if ! command -v ./RSEM-1.3.0/rsem-generate-data-matrix >/dev/null 2>&1; then
  echo "Failed to install RSEM"
  exit 1
else
  echo "Successfully installed RSEM"
fi

#Install Salmon
wget https://github.com/COMBINE-lab/salmon/releases/download/v0.8.2/Salmon-0.8.2_linux_x86_64.tar.gz
tar -xvzf Salmon-0.8.2_linux_x86_64.tar.gz
rm Salmon-0.8.2_linux_x86_64.tar.gz
if ! command -v ./Salmon-0.8.2_linux_x86_64/bin/salmon >/dev/null 2>&1; then
  echo "Failed to install Salmon"
  exit 1
else
  echo "Successfully installed Salmon"
fi

#Install STAR
git clone https://github.com/alexdobin/STAR.git
if ! command -v ./STAR/bin/Linux_x86_64/STAR >/dev/null 2>&1; then
echo "Failed to install STAR"
exit 1
else
echo "Successfully installed STAR"
fi

#Make a directory for RNA-seq data including raw and simulated data
mkdir data
cd data
mkdir simulated
mkdir temp
cd ..

mkdir indices
mkdir indices/STAR
mkdir indices/Salmon_SMEM
mkdir indices/Salmon_quasi

mkdir bamfiles
mkdir bamfiles/raw
mkdir bamfiles/simulated

mkdir time_stats

mkdir ref

}

"$@"
