#!/usr/bin/perl -W
# Author: Burns
# Date: 12-16-18
# 
# This is quick tool to generate JSON for another project.  
# Yes, I am using Perl to write JavaScript.  Why?
# Rather than manually creating the 1500 lines of code with multi-dimensinal data
# I wrote a 200 line Perl script (before comments/improvements)
# and a handful of CSV files that totaled 100 lines. 

# Sean Kirkpatrick taught me this in my first Unix class:
# I really hate this damn machine,
# I wish that the would sell it.
# It never does what I want,
# only what I tell it.

# You can pull your hair out looking for an errant comma.
# When you need to be consistent, and fast - automate.

# Todo:
# Clean up CSV logic to use actual libraries, not a lame hack
# Switch the order on the payloads.csv file columns

my @persona;
my %services;
my @payloads;
my %payloadTitle;
my %personas;
my %demoName;

# Read file for Personas
# Store them in an array we'll walk through later
# Plus a hash to be used later
# Each persoga goes to a demo station
open(CAT, "csv/personas.csv") || die "Can't open personas.csv - $!\n";
my $count = 0;
while (<CAT>) {
	my $line = $_;
	chomp($line);
	if ($line =~ /^#/)  { # Comment - so skip
		next;
	}
	my @tempData = split(",", $line);
	my $key = $tempData[0];
	my $name = $tempData[1];
	push(@personas, $name);
	$personas{$key} = $name;
	$count++;
	#print "Found persona $key is $name\n";
}
print "Found $count personas.\n";

# Read file for Services
# Store them in a hash for later
open(CAT, "csv/services.csv") || die "Can't open services.csv - $!\n";
$count = 0;
while (<CAT>) {
	my $line = $_;
	chomp($line);
	if ($line =~ /^#/)  { # Comment - so skip
		next;
	}
	$count++;
	my @tempData = split(",", $line);
	my $key = $tempData[0];
	my $name = $tempData[1];
	$services{$key} = $name; # we use this in a few spots - don't remove
	#print "Found integration $key is $name\n";
}
print "Found $count integrations.\n";

# Read file for JSON Payload Titles
# Store short titles in an array for later
# We also create $payloadConent - which gets added to payloads.js file later
open(CAT, "csv/payloads.csv") || die "Can't open pqyloads.csv - $!\n";
my $payloadContent = "var payloads = {\n";
$count = 0;
while (<CAT>) {
	my $line = $_;
	chomp($line);
	if ($line =~ /^#/)  { # Comment - so skip
		next;
	}
	my @tempData = split('",', $line);
	my $title = $tempData[0];
	my $shortTitle = $tempData[1];
	$shortTitle =~ s/,$//;
	$shortTitle =~ s/,$//;
	$shortTitle =~ s/^\s+//;
	$title =~ s/^"//;
	#print "Found $title is $shortTitle\n";
	$payloadTitle{$shortTitle} = $title;
	push(@payloads, $shortTitle);
	if ($count > 0) {
		$payloadContent = $payloadContent.",\n";
	}
	$count++;
	$payloadContent = $payloadContent."    \"$title\": $shortTitle";
}
$payloadContent = $payloadContent."\n};\n\n";
print "Processed $count payload file (payloads.csv) entries.\n";

# Read directory JSON and see that each title has a Title.  Sanity check
opendir(DIR, "JSON") || die "Can't open JSON directory - $!\n";
$count = 0;
my @files = readdir(DIR);
foreach my $filename(@files) {
	if ($filename =~ /\.json$/) {
		$count++;
		#print "Found file $filename\n";
		my $shortTitle = $filename;
		$shortTitle =~ s/\.json$//;
		if ($payloadTitle{$shortTitle}) {
			#print "$shortTitle is $payloadTitle{$shortTitle}\n";
		} else {
			print "ERROR - no title for $shortTitle. Update the csv/payloads.csv file to include it.\n";
			# Do we error here?  This could break something.
		}
	}
}
print "Processed $count JSON files in JSON directory.\n";

# create payloads.js file
open (FILE, ">payloads.js") || die "Can't write to payloads.js - $!\n";
$count = 0;
foreach my $payloadFile(@payloads) {
	my $payloadShortTitle = $payloadFile;
	$payloadShortTitle =~ s/\.json$//;
	print FILE "\n\n";
	print FILE "var $payloadShortTitle = {\n";
	my $filename = "JSON/$payloadFile.json";
	#print "Adding $filename\n";
	$count++;
	open(CAT, "$filename") || die "Can't open $filename - $!\n";
	while(<CAT>) {
		print FILE $_;
	}
	print FILE "};\n";
	print FILE "\n\n";
}
print FILE $payloadContent;
close FILE;
print "Processed $count payloads.  Created payloads.js file.\n";


# Read through each persona - do an entry each
# Create services.js file
open(FILE, ">services.js") || die "Can't write to services.js file - $!\n";
print FILE "var services = {";
open(CAT, "csv/personas.csv") || die "Can't read personas.csv file - $!\n";
# we have a section for each persona
$personaCount = 0;
while (<CAT>) {
	my $line = $_;
	chomp($line);
	if ($line =~ /^#/)  { # Comment - so skip
		next;
	}
	my @tempData = split(",",$line);
	my $personaID = $tempData[0];
	my $persona = $tempData[1];
	if ($personaCount > 0) { # We have seen one, so we need to preceed the next one with a comma
		print FILE ",";
	}
	print FILE "\n    \"$persona\": {\n";
	$personaCount++;
	
	$count = 0;

	# Now we read though this file each time - simpler.
	open(NEXTCAT, "csv/persona2integration2key.csv") || die "Can't open persona2integration2key.csv - $!\n";
	while(<NEXTCAT>) {
		my $line = $_;
		chomp($line);
		if ($line =~ /^#/)  { # Comment - so skip
			next;
		}
		my @tempData = split(",",$line);
		if (! $tempData[2] || $tempData[3]) {
			print "Wrong number of entries in persona2integration2key.csv file.\n";
			print "Line was:\n$line\n";
			exit(2);
		}
		my $id = $tempData[0];
		my $service = $tempData[1];
		my $integrationID = $tempData[2];
		if ($id == $personaID) {  # We are doing this one - add to services.js file
			if ($count == 0) { # First entry - no comma preceeding
				#print FILE "";
			} else { # Later entries need a comma preceeding
				print FILE ",\n";
			}
			print FILE "        \"".$services{$tempData[1]}."\": \"".$integrationID."\"";
			$count++;
		}
	}
	# Done with that persona
	print FILE "\n    }";
	# We need logic for comma here . . .
}
print FILE "\n}\n\n\n";
#var services = {
        #"01 Demo (Ken)": {
                #"CloudTrail": "d7c25cd46de04b41afd0412266b560da",
                #"CloudWatch": "704feb51158e47359ebf872a3ad43aee",
                #"GuardDuty": "7d481e115c294f9cbf77c2796137607d",
                #"New Relic": "f56a6e39342c42f4bf3dc05015f3123a",
                #"PHD": "f377979711fa41b593f57284fb6ebce4"
        #},
        #"02 Demo (Eric)": {
                #"CloudTrail": "55e8ab68e5f046849c5a5729431a6d77",
                #"CloudWatch": "61b6d2a5944b453292291dcc34d180e1",
#
close FILE;
print "Created services.js file.\n";
# Get the demo titles hash
# I REALLY need to remember right way to do CSV . . . 
open(CAT, "csv/demos.csv") || die "Can't open demos.csv - $!\n";
while (<CAT>) {
	my $line = $_;
	chomp($line);
	if ($line =~ /^#/)  { # Comment - so skip
		next;
	}
	my @tempData = split(",\"", $line);
	my $demo = $tempData[0];
	my $name = $tempData[1];
	$name =~ s/"$//;
	$demoName{$demo} = $name;
}

# Read flow.csv file
# For each persona you do a sequence.  
# Create sequences.js file
# I am not proud of the following code.
# But it works.
# Edit at your own peril.
open(FILE, ">sequences.js") || die "Can't write to sequence.js file - $!\n";
print FILE "var sequences = {\n";
my $personaCount = 0;
foreach my $persona(@personas) {
	my %seenFlow;
	open(CAT, "csv/flows.csv") || die "Can't open flows.csv - $!\n";
	#print "DOING $persona\n";

	if ($personaCount == "0") { # If this is the first one we don't need a comma before it
		print FILE "    \"$persona\": {\n";
		$personaCount++;
	} else { # This isn't the first one, so preceed with a comma
		print FILE "    },\n";
		print FILE "    \"$persona\": {\n";
		$personaCount++;
	}
	my $stepCount = 0;
	my $seqCount = 0;
	while(<CAT>) {
		my $line = $_;
		#print "->  $line | $stepCount | $seqCount | $personaCount\n";
		chomp($line);
		if ($line =~ /^#/)  { # Comment - so skip
			next;
		}
		my @tempData = split(",", $line);
		my $flow = $tempData[0];
		my $service = $tempData[1];
		my $payloadShort = $tempData[2];
		my $delay = $tempData[3];
		my $payloadTitle = $payloadTitle{$payloadShort};
		if (! $payloadTitle{$payloadShort}) {
			print "ERROR - no payload title for $payloadShort\n";
			exit(1);
		}
		if (! $seenFlow{$flow}) { # First one, no comma preceeding it
			#print "I have not seen $flow yet\n";
			if ($seqCount > 0) {
				print FILE "\n    ],";
			}
			$seqCount++;
			$seenFlow{$flow} = 1;
			print FILE "\n    \"$demoName{$flow}\": [\n";
		} else {  # Later ones need a comma preceeding if there are multiple steps
			if ($stepCount > 0) {
				print FILE ",\n";
			} else {
				print FILE "\n";
			}

		}
		print FILE "        {\n";
		print FILE "            \"routing_key\": services[\"$persona\"][\"$services{$service}\"],\n";
		print FILE "            \"payload\": payloads[\"$payloadTitle{$payloadShort}\"],\n";
		print FILE "            \"delay\": $delay\n";
		print FILE "        }";
		$stepCount++;
	}
	print FILE "       ],\n"; # NOTE - this causes an extra comma at end of file.
				# It works with Chrome, bur really should be patched to not print
				# last one.
}
print FILE "    }\n";
print FILE "};\n";
close(FILE);
print "Finished sequence.js file.\n";
print "DONE!\n";
exit(0);
