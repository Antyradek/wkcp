#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use Fcntl ':flock';

# Czas blokowania planety dla użytkownika
my $TAKENTIME = 60;
# Które problemy kończą cywilizację
my %PROBLEMDESTR = (10 => 1, 15 => 1);
my %PROBLEMFIX = (22 => 1);
# Główny graf
# id problemu
# problem po spowolnieniu czasu
# problem po przyspieszeniu czasu
my %PROBLEMLIST = (
	0 => [5, 4, "Wielka kometa zmierza w stronę planety. Jeśli przyspieszysz czas, niewątpliwie przeleci bokiem, ale wtedy planeta wpadnie na jej ogon. Jeśli odwrócisz czas, kometa zacznie lecieć w przeciwnym kierunku, co może wpłynąć na orbitę planety.", "Lecąca w stronę planety kometa odwróciła swój bieg, co zachwiało grawitacją, a orbita ciała niebieskiego przybliżyła się do gwiazdy.", "Planeta wpadła w warkocz lecącej komety, asteroidy z pyłu zaczęły nawiedzać cywilizację."],
	1 => [6, 6, "Choroby nawiedzają mieszkańców. Wynaleziono panaceum, ale ma nieprzyjemne skutki uboczne. Czy chcesz przyspieszyć wstrzykiwanie specyfiku u mieszkańców, czy niech wysysają sobie go z żył zamiast tego?", "Mieszkańcy planety zaczęli wysysać sobie z żył lekarstwa, a potem nawet krew i organy wewnętrzne, co spowodowało że ludzkość zamieniła się w wyschłe trupy. Lecz teraz nie mogą i tak umrzeć, bo już nie ma co w nich umierać. Są jak zjawy i duchy.", "Mieszkańcy zaczęli wstrzykiwać sobie panaceum ze zwielokrotnioną siłą. Spowodowało to, że zmienili swoje ciała tak, że sami stali się lekarstwem. Osiągnęli nadczłowieczeństwo."],
	2 => [7, 7, "Planeta już nie jest zamieszkała przez żywe istoty, a jakieś transhumanistyczne konstrukty. Ponieważ osiągnęła już wszystko, istoty stoją w stagnacji w losowych miejscach planety i rozmyślają. Możesz przyspieszyć ich rozmyślanie, to może coś wymyślą. Albo jeśli cofniesz potok myśli, to może będziesz mógł naprawić szkody.", "Ludzie zaczęli myśleć wstecz, co spowodowało że zdegradowali się do kompletnych prymitywów.", "Mieszkańcy zaczęli intensywnie myśleć i myśleli tak długo, że ich mózgi się spaliły od nadmiaru pracy."],
	3 => [8, 9, "", "", ""],
	4 => [10, 11, "Asteroidy nawiedzają powierzchnię, burząc co się da i siejąc spustoszenie. Możesz przyspieszyć ich strumień, co spowoduje ich szybsze się wyczerpanie, albo odwrócić, aby zaczęły lecieć w przeciwnym kierunku.", "Asteroidy, które nawiedziły planetę, zaczęły lecieć w przeciwnym kierunku, zlepiać razem i tworzyć grubą warstwę na orbicie, przez którą nic się nie przeciśnie. Gruba skorupa asteroid blokuje promienie słoneczne. Planeta zamarza, a mieszkańcy dostają depresji. To koniec tej cywilizacji.", "Asteroidy, które nawiedziły planetę były tak szybkie, że zaczęły tworzyć dziury w podłożu planety, przez co wygląda teraz jak ser."],
	5 => [11, 12, "Planeta zbliżyła się do swojej gwiazdy, co spowodowało wzrost temperatury na jej powierzchni. Mieszkańcy zaczęli budować wiertła aby wwiercić się w skorupę i uciec przed gorącem. Możesz przyspieszyć wiertła w czasie, co pomoże cywilizacji, albo odwrócić w czasie, co spowoduje że prawdopodobnie wyjdą na powierzchnię.", "Cywilizacja zaczęła wiercić wielkimi wiertłami w ziemi, ale zmiana kierunku ich rotacji spowodowała ich katapultację w kosmos. Planeta wygląda jak dziurawa.", "Mieszkańcy zaczęli masowo wiercić wiertłami w swojej planecie. Wkręcające się wiertła spowodowały aktywność wulkaniczną, trzęsienia ziemi i potoki lawy nawiedzają cywilizację."],
	6 => [12, 22, "Færie zamieszkują planetę. Nadnaturalne istoty, których potrzeby życiowe są teraz zupełnie inne. Magiczne rytuały są teraz odprawiane przez całe społeczeństwo. Magia krąży w kręgach. Możesz odwrócić kierunek krążenia magii i zobaczyć co się stanie, albo przyspieszyć i zobaczyć co społeczeństwo planuje.", "Magia, którą mieszkańcy zaczęli stosować, odwróciła bieg i zachwiała równowagą czasoprzestrzeni. Ziemia poczęła się wykrzywiać w nienaturalne kształty, a trzęsienia trzęsą mieszkańcami.", "Rytuał magiczny, który postanowili przeprowadzić mieszkańcy, się powiódł. Cywilizacja osiągnęła czwartą gęstość i nie potrzebuje już króla do pomocy. Planeta została uratowana na zawsze."],
	7 => [22, 13, "Mieszkańcy planety są zidioceni. Nie myślą za wiele i mają problemy z pojmowaniem wszystkiego, co bardziej skompilowane. Z chęcią za to wynaleźli telewizję i oglądają tylko ją, powoli zdychając z głodu. Możesz cofnąć lecący serial, aby ciągle leciały powtórki. Jeśli przyspieszysz telewizję, to ludzie obejrzą jej jeszcze więcej.", "Cywilizacja uzależniła się od telewizji. Ciągłe powtórki w niej lecące spowodowały, że cywilizacja tak się ich nauczyła na pamięć, że sami stali się telewizją. Nie potrzebują realnego świata, ani nawet telewizora aby oglądać telewizję. Można powiedzieć, że nie potrzebują nawet Króla Czasoprzestrzeni. Zostali ocaleni przed realnym światem na zawsze.", "Masowe oglądanie telewizji w przyspieszonej wersji spowodowało, że każdy obejrzał wszystko, co mógł i teraz zaczął się nudzić."],
	8 => [13, 14, "", "", ""],
	9 => [14, 15, "", "", ""],
	10 => [10, 10, "Gruba skorupa asteroid blokuje promienie słoneczne. Planeta zamarza, a mieszkańcy dostają depresji. To koniec tej cywilizacji.", "", ""],
	11 => [16, 17, "Planeta posiada wiele dziur w podłożu, przez które począł się ulatniać groźny gaz. Mieszkańcy poczęli budować wielkie wentylatory, aby przegonić gaz w niezamieszkałe rejony. Jeśli odwrócisz czas, cały gaz zostanie zassany w drugą stronę. Jeśli przyspieszysz czas, być może ktoś lub coś zostanie porwane.", "Gaz z wyziewów, które powstały w skorupie planety, został zassany do miast. Mieszkańcy duszą się i umierają masowo.", "Gaz, który począł się ulatniać z wnętrza planety, nie jest już problemem, bo został zdmuchnięty razem z atmosferą planety."],
	12 => [17, 18, "Trzęsienia ziemi i wulkany zaczęły nawiedzać świat. Lawa wypływa z każdego miejsca. Jeśli odwrócisz proces stygnięcia lawy, to zwiększysz jej temperaturę na tyle, aby może mogła wyparować. W przeciwnym wypadku przyspieszysz proces jej solidyfikacji.", "Rosnąca temperatura wyciekającej z wulkanów lawy spowodowała wzrost temperatury atmosfery, przez co zwiększyła swoją objętość i odleciała w przestrzeń.", "Lawa wydobywająca się ze szczelin wulkanicznych bardzo szybko wystygła, zamieniając krajobraz nie do poznania. Wysokie góry i pionowe ściany teraz są powszechnym widokiem."],
	13 => [19, 20, "Nuda", "", ""],
	14 => [20, 21, "", "", ""],
	15 => [15, 15, "", "", ""],
	16 => [0, 0, "Miasta są wypełnione gazem. Ludzie duszą się i nie mają ratunku. Zaczęli się modlić do starożytnych bóstw o zakończenie cierpienia. Czy chcesz przyspieszyć czy odwrócić w czasie ich śpiewy?", "Religijne śpiewy śpiewane przez mieszkańców wspak nie spodobały się bogom. Za karę cisnęli w planetę wielkim lodowym głazem.", "Śpiewy ludzi do bogów zadziałały ze zdwojoną siłą. Na nieboskłonie pojawił się ich bóg. I zmierza na ratunek."],
	17 => [0, 1, "Atmosfery już nie ma. Teraz istnieje tylko goła ziemia. Mieszkańcy cywilizacji przyzwyczaili się do chodzenia wszędzie w skafandrach. Używają reaktorów chemicznych do produkcji tlenu. Czy chcesz odwrócić reakcję chemiczną w tych reaktorach, czy może przyspieszyć jeszcze bardziej.", "Mieszkańcy muszą chodzić w skafandrach i produkować powietrze reakcjami chemicznymi, które działają wspak i zamiast powietrza produkują ciało stałe. Przerażeni mieszkańcy katapultują jego kawałki w kosmos, gdzie tworzą wielką kulę.", "Skafandry są noszone przez wszystkich mieszkańców. Przyspieszenie reakcji chemicznych do produkcji powietrza dało mieszkańcom go tak dużo, że aż zaczęli pękać. Rany i infekcje bakteryjne nękają wszystkich."],
	18 => [0, 2, "Mieszkańcy chodzą codziennie w labiryncie skał. To trenuje ich inteligencję. Zaczęli tworzyć nowe i wspaniałe dzieła, a każdy jest teraz wykształcony na poziomie doktora. Możesz cofnąć naukę albo przyspieszyć ją aby jeszcze szybciej ludzie się uczyli.", "Nauka wśród mieszkańców została cofnięta w czasie, rakiety wysyłane w kosmos nie potrafiły wykonywać swoich misji i zamiast tego zawieszały się w przestrzeni i zlepiały razem, tworząc wielką bryłę.", "Mieszkańcy tak bardzo posunęli się w nauce, że zaczęli modyfikować samych siebie. Ciężko powiedzieć, czy są teraz jeszcze żywymi istotami."],
	19 => [1, 3, "", "", ""],
	20 => [2, 3, "", "", ""],
	21 => [3, 3, "", "", ""],
	22 => [22, 22, "Ludzkość została wyniesiona ponad płaszczyzny astralne", "", ""]
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

sub readLog
{
	# Odczyt logów
	my $id = $_[0];
	my $filename = "log" . "$id";
	if(! -e $filename)
	{
		open(my $logfile, ">", $filename) or die "Nie można stworzyć pliku logu";
		print $logfile "Planeta $planetname{$id} zdobyła uwagę Króla Czasoprzestrzeni.\n";
		close($filename);
	}
	open(my $logfile, "<", $filename) or die "Nie można otworzyć pliku logu";
	while(<$logfile>)
	{
		my $line = $_;
		print "<p>$line</p>\n";
	}
	close($logfile);
}

sub appendLog
{
	# Doklejenie logów
	my $id = $_[0];
	my $text = $_[1];
	my $filename = "log" . "$id";
	open(my $logfile, ">>", $filename) or die "Nie można dodać pliku logu";
	print $logfile $text . "\n";
	close($filename);
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
		if($planetalive{$id} > 0 and $planetavailable{$id})
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
		if($planetalive{$id} == 0)
		{
			$state = "Zagłada";
		}
		elsif($planetalive{$id} == -1)
		{
			$state = "Ocalona";
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
	my $problemtext = $PROBLEMLIST{$currentproblem}[2];

	# Ustawienie ostatniego czasu
	$planetuse{$randplanet} = $timestamp;

	print "<h2>Planeta $planetname{$randplanet} potrzebuje twojej pomocy!</h2>";
	
	print "<p>$problemtext</p>\n";
	
	print "<p><a href='?id=$randplanet&problem=$currentproblem&action=backward'>Cofnij czas</a></p>\n";
	print "<p><a href='?id=$randplanet&problem=$currentproblem&action=forward'>Przyspiesz czas</a></p>\n";
	
	print "<h2>Dotychczasowa historia tej cywilizacji:</h2>\n";
	readLog($randplanet);
}

sub runReaction
{
	my $id = $_[0];
	my $forward = $_[1];
	my $problem = $_[2];
	my $problemtext = $PROBLEMLIST{$problem}[2];
	my $reversesolution = $PROBLEMLIST{$problem}[3];
	my $forwardsolution = $PROBLEMLIST{$problem}[4];
	if($problem != $planetproblem{$id})
	{
		printError;
		return;
	}
	print "<h1>Twoje czyny zmieniły oblicza świata $planetname{$id}</h1>\n";
	if($forward)
	{
		print "<h2>Użyłeś czasoprzestrzennych mocy, aby przyspieszyć upływ czasu</h2>\n";
		print "<p>$forwardsolution</p>\n";
		appendLog($id, $forwardsolution);
	}
	else
	{
		print "<h2>Odwróciłeś bieg wydarzeń za pomocą swojej mocy</h2>\n";
		print "<p>$reversesolution</p>\n";
		appendLog($id, $reversesolution);
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
		$planetalive{$id} = -1;
	}
	
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

