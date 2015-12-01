#!/bin/bash

seqCenter=$1
sampleID=$2
chr=$3
option=$4

#fa_dir="./"
scripts_dir="/home/jmalamon/scripts"
ref_file="/project/lswanglab/adsp/data/REF/human_g1k_v37.fasta"
gap_file="/project/lswanglab/adsp/data/REF/human_g1k_v37.fasta.gaphc.bed"

if [[ $seqCenter = 'Broad' ]]; then
  data_dir="/project/lswanglab/adsp/data/broad"
elif [[ $seqCenter = 'Baylor' ]]; then
  data_dir="/project/lswanglab/adsp/data/baylor"
elif [[ $seqCenter = 'WashU' ]]; then
  data_dir="/project/lswanglab/adsp/data/washu"
fi

if [[ $seqCenter = 'test' ]]; then
    sample_path="/projects/lswanglab/adsp/data/NGS/swan/test/example"
    bam_path="/project/lswanglab/adsp/data/NGS/swan/test/example/example.lib1.bam"
else
    sample_path=`ls -d $data_dir/*$sampleID*`
    bam_file=`basename $sample_path `
    bam_path="$sample_path/${bam_file}.chr${chr}.bam"
fi 
################## SWAN Workflow ##################################################
###
###                |---> swan_scan.R --------->|
### swan_stat.R ---|                           |--->swan_join.R  
###                |---> sclip_scan.R -------->|
###
###################################################################################

### BEGIN ###
### SWAN STAT ###
file_designation=`basename $sample_path`
if [[ "$option" = "-p1" ]]; then
  PATH=$PATH:"/opt/software/samtools/samtools-0.1.19/samtools"
  module load samtools-0.1.19

  if [[ ! -d $sample_path/stat ]]; then 
    mkdir $sample_path/stat
  fi 
  file_designation=`basename $sample_path` 
  if [[ $seqCenter = 'test' ]]; then
      $scripts_dir/swan_stat.R -c all $bam_path
  else
      $scripts_dir/swan_stat.R -c $chr -o $sample_path/$file_designation.chr$chr $bam_path
  fi 
fi

### SWAN_SCAN ###
if [[ $option = "-p2a" ]]; then
  if [[ $seqCenter = 'test' ]]; then     
      $scripts_dir/swan_scan.R -r 0.5 -w 100 -q -c $chr -n $gap_file $ref_file $bam_path
  else
      $scripts_dir/swan_scan.R -r 0.5 -w 100 -q -c all -n $gap_file $ref_file $bam_path
  fi
fi

if [[ $option = "-p2b" ]]
then
  PATH=$PATH:"/home/jmalamon/R/x86_64-redhat-linux-gnu-library/3.0"
  if [[ ! -d $sample_path/sclip_scan ]]; then
    mkdir $sample_path/sclip_scan
  fi 
  if [[ $seqCenter = 'test' ]]; then
    $scripts_dir/sclip_scan.R -a -q -c all -s $sample_path/sclip_events/${sampleID}.sclip_events.RData -n $gap_file $ref_file $bam_path
  else
    $scripts_dir/sclip_scan.R -a -q -c all -n $gap_file -o $ref_file $bam_path 
  #$scripts_dir/sclip_scan.R -a -q -c a -n $gap_file -o $sample_path/sclip_events/$sampleID.sclip.RData $ref_file $bam_path
  fi
fi

### SWAN_JOIN ###
lCdthresh=7.0
lDxthresh="level4"
swanopt="track=lCd,method=empr,thresh=level8,sup=100,gap=100_track=lDr+lDl,method=theo,thresh=level3,sup=100,gap=100_track=ins,sup=50,cvg=5_track=del,sup=50,cvg=5"
#swanopt="track=lCd,method=empr,thresh=$lCdthresh,sup=200,gap=200_tracl=lDl+lDr,method=theo,thresh=$lDxthresh,tele=200,sup=100,gap=100_track=ins,sup=50,cvg=5_track=del,sup=20,cvg=5"
bigdopt="minmpr=3,maxins=100000"
discopt="minmpr=3,maxins=100000"
confirm="hot"
if [[ "$option" = "-p3" ]]; then
  if [[ $seqCenter = 'test' ]]; then
    $scripts_dir/swan_join.R -a -q -c all -m $sample_path/example.lib1.1.disc.txt -i $sample_path/example.lib1.1.swan.txt.gz -j $sample_path/example.lib1.1.bigd.txt -l $sample_path/example.lib1.sclip.RData -u $swanopt -v $bigdopt $ref_file $bam_path
  else
    $scripts_dir/swan_join.R -a -q -c $chr -m $sample_path/$bam_file.chr$chr.disc.txt -i $sample_path/$bam_file.chr$chr.swan.txt.gz -j $sample_path/$bam_file.chr$chr.bigd.txt -l $sample_path/sclip_events/${sampleID}.sclip.RData -u $swanopt -v $bigdopt $ref_file $bam_path
  fi
fi
