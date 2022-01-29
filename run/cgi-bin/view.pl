#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use Fcntl ':flock';

# Czas blokowania planety dla użytkownika
my $TAKENTIME = 15;
# Które problemy kończą cywilizację
my %PROBLEMDESTR = (10 => 1, 15 => 1);
my %PROBLEMFIX = (26 => 1);
# Główny graf
# id problemu
# problem po spowolnieniu czasu
# problem po przyspieszeniu czasu
my %PROBLEMLIST = (
	0 => [4, 5],
	1 => [6, 6],
	2 => [7, 7],
	3 => [8, 9],
	4 => [10, 11],
	5 => [11, 12],
	6 => [12, 26],
	7 => [26, 13],
	8 => [13, 14],
	9 => [14, 15],
	10 => [10, 10],
	11 => [16, 17],
	12 => [17, 18],
	13 => [19, 20],
	14 => [20, 21],
	15 => [15, 15],
	16 => [0, 0],
	17 => [0, 1],
	18 => [0, 2],
	19 => [1, 3],
	20 => [2, 3],
	21 => [3, 3],
);

my $c = CGI->new;
print $c->header(
-type => "text/html",
-charset => "utf-8"
);

print "<html><head><title>Witaj Królu Czasoprzestrzeni</title></head><body>";

my @sortids = ();
my %planetuse = ();
my %planetalive = ();
my %planetname = ();
my %planetavailable = ();
my %planetproblem = ();
my $timestamp = time();
my $planets;

sub printError
{
	print "<h1>Nastąpił paradoks czasoprzestrzenny!</h1>";
	print "<a href='?'>Odzyskaj władzę nad czasem</a>";
}

sub parseGet
{
	my $buffer = $ENV{'QUERY_STRING'};
	my %getargs = ();
	if(not $buffer)
	{
		$buffer = "";
	}
	my @pairs = split(/&/, $buffer);
	foreach(@pairs) 
	{
		my $pair = $_;
		my $name = "";
		my $value = "";
		($name, $value) = split(/=/, $pair);
		$value =~ s/[^a-z0-9]//g;
		$getargs{$name} = $value;
	}
	return %getargs;
}

sub readDatabase
{
	open($planets, "+<", "planets") or die "Nie można otworzyć pliku planet";
	flock($planets, LOCK_EX);
	@sortids = ();
	%planetuse = ();
	%planetalive = ();
	%planetname = ();
	%planetavailable = ();
	%planetproblem = ();
	$timestamp = time();
	while(<$planets>)
	{
		my @words = split / /, $_;
		my $id = $words[0];
		my $last_use = int($words[1]);
		my $problem = int($words[2]);
		my $alive = int($words[3]);
		if($id eq "-")
		{
			last;
		}
		my $name = uc(substr($id, 0, 1)) . substr($id, 1);
		$planetuse{$id} = $last_use;
		$planetalive{$id} = $alive;
		$planetname{$id} = $name;
		$planetproblem{$id} = $problem;
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
}

sub writeDatabase
{
	# Zrzut do bazy
	seek($planets, 0, 0);
	foreach(@sortids)
	{
		my $id = $_;
		print $planets "$id $planetuse{$id} $planetproblem{$id} $planetalive{$id}\n"
	}
	print $planets "- 0 0 0\n";
	close($planets);
}

sub runCore
{
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
	print "<h1>Cywilizacja potrzebuje twojego ratunku</h1>\n";
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
	my $currentproblem = $planetproblem{$randplanet};

	# Ustawienie ostatniego czasu
	$planetuse{$randplanet} = $timestamp;

	print "<h2>Planeta $planetname{$randplanet} potrzebuje twojej pomocy!</h2>";
	
	print "<a href='?id=$randplanet&problem=$currentproblem&action=backward'>Cofnij czas</a>\n";
	print "<a href='?id=$randplanet&problem=$currentproblem&action=forward'>Przyspiesz czas</a>\n";
}

sub runReaction
{
	my $id = $_[0];
	my $forward = $_[1];
	my $problem = $_[2];
	if($problem != $planetproblem{$id})
	{
		printError;
		return;
	}
	print "<h1>Twoje czyny zmieniły oblicza świata $planetname{$id}</h1>\n";
	if($forward)
	{
		print "<h2>Użyłeś czasoprzestrzennych mocy, aby przyspieszyć upływ czasu</h2>\n";
	}
	else
	{
		print "<h2>Odwróciłeś bieg wydarzeń za pomocą swojej mocy</h2>\n";
	}
	my $currentproblem = $planetproblem{$id};
	my $nextproblem = $PROBLEMLIST{$currentproblem}[$forward];
	# Zmiana bazy
	$planetproblem{$id} = $nextproblem;
	$planetuse{$id} = 0;
	if($PROBLEMDESTR{$nextproblem})
	{
		print "<p>Nastąpiła zagłada cywilizacji $planetname{$id}.</p>";
		$planetalive{$id} = 0;
	}
	if($PROBLEMFIX{$nextproblem})
	{
		print "<p>Cywilizacja planety $planetname{$id} została permanentnie ocalona.</p>";
		$planetalive{$id} = 0;
	}
	print "Problemy $currentproblem → $nextproblem\n";
	
	print "<a href='?'>Zamąć czasoprzestrzenią ponownie</a>";
}

my %getargs = parseGet;
my $forward;

sub checkArgs
{
	my $id = $getargs{'id'};
	my $action = $getargs{'action'};
	my $name = $planetname{$id};
	if(not $id or not $name)
	{
		return 0;
	}
	if($action eq 'forward')
	{
		$forward = 1;
	}
	elsif($action eq 'backward')
	{
		$forward = 0;
	}
	else
	{
		return 0;
	}
	
	return 1;
}


readDatabase;
if(not $getargs{"action"})
{
	# Wyświetlenie listy
	runCore;
}
elsif(checkArgs)
{
	# Wykonanie akcji
	runReaction($getargs{'id'}, $forward, int($getargs{'problem'}));
}
else
{
	printError
}

writeDatabase;
print "</body></html>\n";

