# script to count forward/rev chrM reads in:
# project dir $1 (dir that contains BAM files)
# Region of interest $2 (format chrom:start-end)
# to output $3 (a text file)
# March 2023
# requires samtools

# check if output already exists
[ -f $3 ] && { echo "ERROR: output file $3 already exists, either delete it or choose a new name!" ; exit ; }
[ -f ${3}.gz ] && { echo "ERROR: output file ${3}.gz already exists, either delete it or choose a new name!" ; exit ; }

# create output file with header
echo -e "cell\tflag\tCHROM\tPOS\tinsert\treadlen\tstrand" > $3
echo "writing individual read counts file to $3"

# run loop to count chrM reads in all bam files in $1
for mybam in $(ls $1/*.bam)
do
	echo "working on $mybam"

	cellname=$(echo $mybam | rev | cut -f1 -d / | rev | sed 's/.bam//')

	readlen=$(samtools view $mybam | head -n1 | cut -f10 | wc -c)
	# perform for forward reads
	# see flag selection at https://broadinstitute.github.io/picard/explain-flags.html
	samtools view -f 66 -F 1172 $mybam $2 \
       		| cut -f2,3,4,9 \
		| awk -v cellname="$cellname" -v readlength="$readlen"  -F'\t' '{OFS = FS} {print cellname,$0,readlength,"C"}' \
       		>> $3


	# repeat for reverse reads, note the flag changes
	samtools view -f 82 -F 1156 $mybam $2 \
		| cut -f2,3,4,9 \
		| awk -v cellname="$cellname" -v readlength="$readlen"  -F'\t' '{OFS = FS} {print cellname,$0,readlength,"W"}' \
		>> $3
done

gzip $3
