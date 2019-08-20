#
# Deutsch pipeline: Extract Text from Speech 
# Apdated from Chinese pipeline

# MAINTAINER: AASHISH AGARWAL

# exit when any command fails
# set -e

echo "   Starting infer.sh for Automated Speech Recognition   "

cd ..
# The directory of /kaldi 
PWDDIR=$(pwd)
MYHOME=$PWDDIR/axa1142
BASEDIR="/mnt/rds/redhen/gallina"
# FAILED="/tmp/check-recordings-daemon-sysdown"
# TO=`cat $BASEDIR/Singularity/Chinese_Pipeline/e-mail`

# Move to the main tv storage directory N days ago and list the contents
if [ -z "$1" ] ; then DAY=0 ; else DAY=${1:0:10} ; fi
if [ "$( echo "$1" | egrep '^[0-9]+$' )" ] ; then DAY="$1"
  elif [ "${#1}" -eq "7" ] ; then cd $BASEDIR/tv/${1%-*}/$1 ; DAY=""
  elif [ "$1" = "here" ] ; then DAY="$( pwd )" DAY=${DAY##*/} DAY="$[$[$(date +%s)-$(date -d "$DAY" +%s)]/86400]"
  elif [ "$1" = "+" ] ; then DAY=`pwd` ; DAY=${DAY##*/}
    DAY="$[$[$(date +%s)-$(date -ud "$DAY" +%s)]/86400]" ; DAY=$[DAY-$2]
  elif [ "$1" = "-" ] ; then DAY=`pwd` ; DAY=${DAY##*/}
    DAY="$[$[$(date +%s)-$(date -ud "$DAY" +%s)]/86400]" ; DAY=$[DAY+$2]
  elif [ "${#DAY}" -eq "10" ] ; then DAY="$[$[$(date +%s)-$(date -ud "$DAY" +%s)]/86400]"
  else echo "$1?"
fi #;  echo "DAY is $DAY ; 1 is $1 ; 2 is $2"
     
if [ -n "$DAY" ] ; then DIR="$BASEDIR/tv/$(date -ud "-$DAY day" +%Y)/$(date -ud "-$DAY day" +%Y-%m)/$(date -ud "-$DAY day" +%F)" ; fi 
# DIR="$BASEDIR/tv/2019/2019-01/2019-01-12"
if [ -d $DIR ] ; then cd $DIR ; else echo "No $DIR" ; exit ; fi

echo "Working on `pwd`"

# get the date name of this day
DAT=$(basename `pwd`) 
MONTH=${DAT:0:7}
YEAR=${DAT:0:4}

# Generate a list of files to process -- make sure to exclude _KCET_ files in English
# Using find $DIR will generate a list with full path -- find . a list without path

rm $MYHOME/temp_data/*

find . -name '*_DE_*.mp4' ! -iname "*KCET*" -exec cp {} $MYHOME/temp_data/ \;

# Working directory -- it's unclear we really need to copy the files -- a downside is that unprocessed files remain in this location
cd $MYHOME/temp_data

# If there are no files for a particular day, alert us with an e-mail
# if [ -z "$(ls -A $DAT*.mp4)" ]; then
#       which mail
#       echo -e "\n\tInfer.sh reports that $DAT doesn't have any Chinese files.\n\tPlease intervene as needed." > $FAILED
#       /usr/bin/mailx -s "No Chinese files on $DAT\n" $TO < $FAILED
#       exit 0
# fi

# Initialize counters
n=0 m=0

for FIL in $DAT*.mp4 ; do n=$[n+1]

# Skip existing files
#  if [ -f "$PWDDIR/new_text/$YEAR/$MONTH/$DAT/${FIL%.*}.txt" ] ; then echo -e "\t${FIL%.*}.txt has already been processed" ; m=$[m+1] ; continue ; fi

# Extract and split the a32000 {FIL%%.*}.wav
  ffmpeg -i $FIL -ac 1 -ar 32000 ${FIL%%.*}.wav
#  mkdir -p ${FIL%%.*}

# Use VAD to split the whole audio into piece
#  python ../code/audiosplit.py \
#    --target_dir=$PWDDIR/temp_data/${FIL%%.*}.wav \
#    --output_dir=$PWDDIR/temp_data/${FIL%%.*}
  
  rm ${FIL%%.*}.mp4
#  rm $FIL

# For all the pieces that are longer than 30 seconds, split them again
#  python ../code/audiosplit.py \
#    --target_dir=$PWDDIR/temp_data/${FIL%%.*}  --output_dir=$PWDDIR/temp_data/${FIL%%.*}
#  echo $FIL' split completed' 
done

# Completed
# if [ "$m" -eq "$n" ] ; then exit ; fi

# Create manifests
#for FIL in `ls -d $DAT*` ; do

	# Skip existing files
#   if [ -f $PWDDIR'/new_text/'$YEAR/$MONTH/$DAT/${FIL%.*}.txt ] ; then echo -e "\tSkipping manifest for $FIL" ; continue ; fi

#   python manifest.py \
#     --target_dir=$PWDDIR/temp_data/$FIL  \
#     --manifest_path=$PWDDIR/temp_manifest/$FIL
#done

for manifest in $DAT* ; do
	 echo -e "\n\tRunning ASR on $manifest ...\n"
         mkdir -p $MYHOME'/new_text/'$YEAR/$MONTH/$DAT
	 mkdir $MYHOME'/temp_manifest/'$YEAR/$MONTH/$DAT
	 python /mnt/rds/redhen/gallina/home/axa1142/kaldi/tools/kaldi-gstreamer-server/kaldigstserver/client.py -r 32000 --save-adaptation-state adaptation-state.json $manifest > $MYHOME'/temp_manifest/'$YEAR/$MONTH/$DAT/${manifest%%.*}'.txt'
         sleep 2m
	 python -u ../infer.py \
            --output_file=$MYHOME'/new_text/'$YEAR/$MONTH/$DAT/${manifest%%.*}'.asr' \
	    --infer_manifest=$MYHOME'/temp_manifest/'$YEAR/$MONTH/$DAT/${manifest%%.*}'.txt' \
            --input_file=$BASEDIR'/tv/'$YEAR/$MONTH/$DAT/${manifest%%.*}'.txt'
done

exit 0
