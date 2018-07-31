#
# Parse and process options
#
if (!GetOptions('number_of_files|n=s'		=> \$number_of_files,
		'min_size|m=s'			=> \$min_size,
		'maxsize|x=s'			=> \$maxsize,
		'min_filename_length|b=s'	=> \$min_filename_length,
		'max_filename_length|e=s'	=> \$max_filename_length
	)) {
	die "$usage";
}

#
# Check arguments
#
foreach ($number_of_files, $min_size, $maxsize, $min_filename_length, $max_filename_length) {
	die "! $usage" if (! defined ($_) );
}

