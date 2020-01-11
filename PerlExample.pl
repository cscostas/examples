#! /usr/bin/perl

=pod
	ppOracle.pl	< oracle_input_file > tab-delimited_output_file

	Reads an input file (from STDIN) containing output from an Oracle SQL query and outputs
	the data in tab-delimited format.  Removes extraneous headers, etc.

=cut

use utf8;

use Text::Tabs;		# needed for expand()

##############################################################################
####  SUBFUNCTIONS
##############################################################################

##############################################################################
####
####  ckformat
####
####  Subfunction to load the format variables.
####
##############################################################################

sub ckformat
{
    local($data_in) = @_;

####
####  Check for a line of dashes.  This is going to give us the format for
####  the following lines.
####

    if ( $data_in =~ /^-.*$/ )
    {
		$format_num = 0;
        foreach $frmt (split(' ',$data_in))
		{
			$format_len[$format_num] = length($frmt);
			$format_num++;
		}
		$format_on = "Y";

		return $SUCCESS;
    }

    return $FAILURE;
}

##############################################################################
####
####  ckendsql
####
####  Subfunction to check data for the "rows", "SQL>", or "Disconnected"
####  keywords.
####
##############################################################################

sub ckendsql
{
    local($data_in) = @_;

####
####  Check for the "rows" keyword.  If found, turn the format off.
####

    if ( $data_in =~ /^.* rows* .*$/ )
    {
        @format_len = "";
        $format_on  = "N";
        return $SUCCESS;
    }

####
####  Check for the "SQL>" keyword.  If found, turn the format off.
####

    if ( $data_in =~ /^SQL>.*$/ )
    {
        @format_len = "";
        $format_on  = "N";
        return $SUCCESS;
    }

####
####  Check for the "Disconnected" keyword.  If found, turn the 
####  format off.
####

    if ( $data_in =~ /^Disconnected.*$/ )
    {
        @format_len = "";
        $format_on  = "N";
        return $SUCCESS;
    }

    return $FAILURE;
}

##############################################################################
####
####  procstr
####
####  Subfunction to process a data string, based on the formatting
####  information obtained earlier.
####
##############################################################################

sub procstr
{
    local($data_in) = @_;

####
####  If the data string is a blank line, ignore it.
####

    return $FAILURE if $data_in =~ /^\s*$/;

####
####  If we've gotten the format, and we haven't hit a blank line yet,
####  we need to split the data into fields.  Since Oracle uses tabs 
####  instead of spaces to format its output, we need to replace all the
####  tabs first, so we know where the fields should go.
####

    $data_string	= expand($data_in);

####
####  Break the string into a series of bytes.
####

    @data_utf8		= unpack "C*", $data_string;
   
####
####  Break the line into the appropriate fields based on the field lengths.
####  Strip spaces from the field ends.  Move the offset counter the length
####  of the current field before the next search (plus one to skip over
####  the space between fields.)
####

    @outfields 		= "";
    $data_utf8_ptr	= 0;

    for ($outfldnum = 0; $outfldnum < @format_len; $outfldnum++)
    {
		@hold_utf8	= "";
		$fld_format_len	= $format_len[$outfldnum];

		# Walk the string one character at a time.  
		for ( 	$hold_utf8_ptr = 0; 
				$hold_utf8_ptr < $fld_format_len;
				$hold_utf8_ptr++, $data_utf8_ptr++ )
		{
			$hold_utf8[$hold_utf8_ptr]	= $data_utf8[$data_utf8_ptr];
	
			# check for extra bytes
			$fld_format_len++ if $data_utf8[$data_utf8_ptr] >= 192;
		}

		$outfields[$outfldnum]	= pack "C*", @hold_utf8;
	
		# replace all null bytes with spaces
		$outfields[$outfldnum]	=~ s/\x00/ /g;
	
		# take off leading and trailing spaces
		$outfields[$outfldnum] 	=~ s/^\s*//;
		$outfields[$outfldnum]	=~ s/\s*$//;
	
		# skip over the space field separator
		$data_utf8_ptr++;
    }

####
####  Print the fields, tab-delimited, to stdout
####

    print join('	',@outfields);
    print "\n";

    return $SUCCESS;
}

##############################################################################
####  MAIN
##############################################################################

$SUCCESS = 0;
$FAILURE = 1;

@format_len = "";
$format_on  = "N";

$atEOF = "N";

binmode(STDIN,'raw');
binmode(STDOUT,'raw');

MAINLOOP:
while (<>)
{
    $data_in = $_;
    chop($data_in);

####
####  Check for a line of dashes.  This is going to give us the format for
####  the following lines.
####

    next if (ckformat($data_in) == $SUCCESS);

####
####  Check for the ending "rows" or "SQL" line.  If we hit it, turn the 
####  format off and continue.
####

    next if (ckendsql($data_in) == $SUCCESS);

####
####  If we don't have a format yet, continue.
####

    next if $format_on eq "N";

####
####  Test for a blank line.
####

    if ( $data_in =~ /^\s*$/ )
    {
		$data1 = $data_in;

		last if eof;

		$data2 = <>;
		chop($data2);

####
####  If we hit a blank line, check the next line for the "rows" and "SQL>"
####  keyword.  If there, turn the format off and continue. 
####

		next if (ckendsql($data2) == $SUCCESS);
	
####
####  If the second line didn't contain "rows" or "SQL>", read another line, 
####  then check for the "rows" and "SQL>" keywords and for a format line.  
####  If found, turn off or reset the format as appropriate and continue.  
####  If not found, reset the variables to start with the second line and 
####  check again.  Keep going until the test line isn't blank.
####
####  I realize the algorithm isn't the cleanest, but it is safe and it
####  does work.  With multiple blank lines, the inner blank check runs
####  1 extra time, and the procstr($data2) may not be necessary.  If
####  anybody figures out a way to make this run more cleanly (while
####  remaining safe), please let me know.  -- CSC
####


		while ($data1 =~ /^\s*$/)
		{
		    last if eof;

		    while ($data1 =~ /^\s*$/)
		    {
				last if eof;

		        $data3 = <>;
		        chop($data3);

		        next MAINLOOP if (ckendsql($data3) == $SUCCESS);
		        next MAINLOOP if (ckformat($data3) == $SUCCESS);

		        $data1 = $data2;
		        $data2 = $data3;
				$data3 = "";
		    }

####
####  When we get a non-blank, non-"endsql" string in the first data field,
####  process it.  Start again with the second field.
####

		    procstr($data1);

		    $data1 = $data2;
		    $data2 = $data3;
		    $data3 = "";
		} 

		procstr($data1);
		procstr($data2);

		next;
    }

    procstr($data_in);
}

exit($SUCCESS);
