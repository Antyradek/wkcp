#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use Fcntl ':flock';

# Czas blokowania planety dla użytkownika
my $TAKENTIME = 15;

my $c = CGI->new;
print $c->header(
-type => "text/html",
-charset => "utf-8"
);
# print "Content-type: text/html\n\n";

print "<html><head><title>Witaj Królu Czasoprzestrzeni</title></head><body>";
print "<h1>Cywilizacja potrzebuje twojego ratunku</h1>\n";

sub runCore
{
	open(my $planets, "+<", "planets") or die "Nie można otworzyć pliku planet";
	flock($planets, LOCK_EX);
	my @sortids = ();
	my %planetuse = ();
	my %planetalive = ();
	my %planetname = ();
	my %planetavailable = ();
	my $timestamp = time();
	while(<$planets>)
	{
		my @words = split / /, $_;
		my $id = $words[0];
		my $last_use = int($words[1]);
		my $alive = int($words[2]);
		my $name = uc(substr($id, 0, 1)) . substr($id, 1);
		$planetuse{$id} = $last_use;
		$planetalive{$id} = $alive;
		$planetname{$id} = $name;
		if($last_use + $TAKENTIME < $timestamp)
		{
			$planetavailable{$id} = 1;
		}
		else
		{
			$planetavailable{$id} = 0;
		}
		push(@sortids, $id);
	}
	sort @sortids;

	my @freeplanets = ();
	foreach(@sortids)
	{
		my $id = $_;
		if($planetalive{$id} and $planetavailable{$id})
		{
			push(@freeplanets, $id);
		}
	}
	
	# Wypisz wszystkie światy
	print "<h2>Światy wołające o pomoc:</h2>\n";
	print "<table>\n";
	foreach(@sortids)
	{
		my $id = $_;
		my $state = "";
		if(not $planetalive{$id})
		{
			$state = "Zagłada";
		}
		elsif(not $planetavailable{$id})
		{
			$state = "W wirze czasu";
		}
		else
		{
			$state = "Dostępna";
		}
		
		print "<tr>";
		print "<td>$planetname{$id}</td>";
		print "<td>$state</td>";
		print "</tr>\n";
	}
	print "</table>\n";

	if(int(@freeplanets) == 0)
	{
		print "<h2>Brak planet do interakcji</h2>";
		return;
	}

	# Losowanie żywej planety
	my $randindex = int(rand(@freeplanets));
	my $randplanet = $freeplanets[$randindex];

	# Ustawienie ostatniego czasu
	$planetuse{$randplanet} = $timestamp;

	# Zrzut do bazy
	seek($planets, 0, 0);
	foreach(@sortids)
	{
		my $id = $_;
		print $planets "$id $planetuse{$id} $planetalive{$id}\n"
	}

	close($planets);

	#print TESTFILE "zapisane\n";

	print "<h2>Planeta $planetname{$randplanet} potrzebuje twojej pomocy!</h2>";
}

runCore

print "</body></html>\n";

