#!/bin/bash
### THIS SCRIPT IS USED TO EXECUTE SWAN ###
### User must provide sampleID and SWAN processing step
### Also, can be used with LSF or Sungrid Engine ###
fa_dir="./"
scripts_dir="/home/jmal/scripts"

file="wgs"

#seqCenter="Broad"
#seqCenter="Baylor"
#seqCenter="WashU"
seqCenter="test"

jobScheduler="LSF"
#jobScheduler="SGE"

sampleID=$1
option=$2
phase=${option:2}

if [[ -z $option ]] ; then
    echo 'Please supply SWAN processing step (-p1, -p2a, -p2b, -p3..)'
    exit 0
fi

if [[ $seqCenter = 'test' ]]; then
    declare -a chrArray=("a")
else
    declare -a chrArray=("1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" "21" "22" "X" "Y")
fi
### Allocate memroy based on phase
    case "$option" in
        "-p1")
            mem=20000
            ;;
        "-p2a")
            mem=60000
	    ;;
        "-p2b")
    	    mem=30000
            ;;
        "-p3")
            mem=55000
            ;;
        *) echo invalid option;;
    esac

if [[ $seqCenter = 'Broad' ]]; then
  data_dir="/project/lswanglab/adsp/data/broad"
elif [[ $seqCenter = 'Baylor' ]]; then 
  data_dir="/project/lswanglab/adsp/data/baylor"
elif [[ $seqCenter = 'WashU' ]]; then 
  data_dir="/project/lswanglab/adsp/data/washu"
fi

sample_path=`ls -d $data_dir/*$sampleID*`

for chr in "${chrArray[@]}"
do
    bam_file=`basename $sample_path`
    bam_file="/project/lswanglab/adsp/data/NGS/swan/test/example/example.lib1.bam"

    if [[ $seqCenter = 'Broad' ]]; then
      bam_path="$sample_path/${bam_file}.chr${chr}.bam"
    else
      bam_path="$sample_path/${bam_file}.chr${chr}.bam"
    fi

    if [[ $option = "-p2a" ]]; then
        ### Calculate memory for phase 2 (swan_scan) based on metrics from previous runs
	fsize=$(stat $bam_path | grep -Po "Size: \d+"|grep -Po "\d+")
        mb=$(echo "(.000002375 * $fsize)+75000"|bc|cut -d"." -f1);
 
	if [[ $jobScheduler = "LSF" ]]; then
            bsub -q denovo -o $file.$seqCenter.$sampleID.$phase.${chr}.log -M $mem "sh swan.sh $seqCenter $sampleID $chr $option"
        elif [[ $jobScheduler = "SGE" ]]; then
 	    qsub -cwd -j y -o $file.$seqCenter.$sampleID.$phase.$chr.log -l h_vmem=${mem}M -N $file.$seqCenter.$sampleID.$phase.$chr -b y ./swan.sh $seqCenter $sampleID $chr $option 
        else 
	    echo "Must use job scheduler" exit 
	fi 
    else
        if [[ $jobScheduler = "LSF" ]]; then
	    bsub -q denovo -o $file.$seqCenter.$sampleID.$phase.${chr}.log -M $mem "sh swan.sh $seqCenter $sampleID $chr $option"
        elif [[ $jobScheduler = "SGE" ]]; then
	    qsub -cwd -j y -o $file.$seqCenter.$sampleID.$phase.$chr.log -l h_vmem=$mem -N $file.$seqCenter.$sampleID.$phase.$chr -b y ./swan.sh $seqCenter $sampleID $chr $option
            echo "Must use job scheduler" exit
	fi 
    fi
done

