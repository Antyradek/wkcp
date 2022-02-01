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
# problem po odwróceniu czasu
# problem po przyspieszeniu czasu
my %PROBLEMLIST = (
	0 => [5, 4, "Na drodze komety", "Wielka kometa zmierza w stronę planety. Jeśli przyspieszysz czas, niewątpliwie przeleci bokiem, ale wtedy planeta wpadnie na jej ogon. Jeśli odwrócisz czas, kometa zacznie lecieć w przeciwnym kierunku, co może wpłynąć na orbitę planety.", "Lecąca w stronę planety kometa odwróciła swój bieg, co zachwiało grawitacją, a orbita ciała niebieskiego przybliżyła się do gwiazdy.", "Planeta wpadła w warkocz lecącej komety, asteroidy z pyłu zaczęły nawiedzać cywilizację."],
	1 => [6, 6, "Chorujący mieszkańcy", "Choroby nawiedzają mieszkańców. Wynaleziono panaceum, ale ma nieprzyjemne skutki uboczne. Czy chcesz przyspieszyć wstrzykiwanie specyfiku u mieszkańców, czy niech wysysają sobie go z żył zamiast tego?", "Mieszkańcy planety zaczęli wysysać sobie z żył lekarstwa, a potem nawet krew i organy wewnętrzne, co spowodowało że ludzkość zamieniła się w wyschłe trupy. Lecz teraz nie mogą i tak umrzeć, bo już nie ma co w nich umierać. Są jak zjawy i duchy.", "Mieszkańcy zaczęli wstrzykiwać sobie panaceum ze zwielokrotnioną siłą. Spowodowało to, że zmienili swoje ciała tak, że sami stali się lekarstwem. Osiągnęli nadczłowieczeństwo."],
	2 => [7, 7, "Transhumanistyczne społeczeństwo", "Planeta już nie jest zamieszkała przez żywe istoty, a jakieś transhumanistyczne konstrukty. Ponieważ mieszkańcy osiągnęli już wszystko, stoją teraz w stagnacji w losowych miejscach planety i rozmyślają. Możesz przyspieszyć ich rozmyślanie, to może coś ostatecznie wymyślą. Albo jeśli cofniesz potok myśli, to może będziesz mógł naprawić szkody, jakie siedzą w ich umysłach.", "Ludzie zaczęli myśleć wstecz, co spowodowało że zdegradowali się do kompletnych prymitywów.", "Mieszkańcy zaczęli intensywnie myśleć i myśleli tak długo, że ich mózgi się spaliły od nadmiaru pracy."],
	3 => [8, 9, "Powstanie cywilizacji", "Cywilizacja się sprzeciwiła tobie, Królu Czasoprzestrzeni, nie mają ochoty już więcej być kontrolowanymi przez twoje fluktuacyjne zachcianki. Zamierzają przebudować kod tej gry aby była strzelanką. Przy okazji zdetronizują ciebie, pozbawiając cię twojej jedenastowymiarowej korony i przekuwając ją na folię do pieczenia. Pieczenia ciebie, Królu Czasoprzestrzeni. Musisz się ratować. Możesz przyspieszyć grę, aby spowodować przedwczesny koniec, albo cofnąć ją aż do początku. Jedno albo drugie z pewnością zakończy tę cywilizację.", "Cywilizacja sprzeciwiła się tobie, Królu Czasoprzestrzeni, więc aby się ratować musiałeś cofnąć czas w grze. Teraz wszechświat płynie w przeciwnym kierunku.", "Planeta sprzeciwiła się tobie, próbują cię zrzucić z tronu, Królu Czasoprzestrzeni. Postanowiłeś ratować się, przyspieszając czas wszechświata gry, aby spowodować przedwczesny koniec. Udało się, lecz poleciałeś aż za granicę czasu, do której wpadliście ty i cywilizacja, przed którą uciekałeś."],
	4 => [10, 11, "Nękana przez asteroidy", "Asteroidy nawiedzają powierzchnię, burząc co się da i siejąc spustoszenie. Możesz przyspieszyć ich strumień, co spowoduje ich szybsze się wyczerpanie, albo odwrócić, aby zaczęły lecieć w przeciwnym kierunku.", "Asteroidy, które nawiedziły planetę, zaczęły lecieć w przeciwnym kierunku, zlepiać razem i tworzyć grubą warstwę na orbicie, przez którą nic się nie przeciśnie. Gruba skorupa asteroid blokuje promienie słoneczne. Planeta zamarza, a mieszkańcy dostają depresji. To koniec tej cywilizacji.", "Asteroidy, które nawiedziły planetę były tak szybkie, że zaczęły tworzyć dziury w podłożu planety, przez co wygląda teraz jak ser."],
	5 => [11, 12, "Wybita z orbity", "Planeta zbliżyła się do swojej gwiazdy, co spowodowało wzrost temperatury na jej powierzchni. Mieszkańcy zaczęli budować wiertła aby wwiercić się w skorupę i uciec przed gorącem. Możesz przyspieszyć wiertła w czasie, co pomoże cywilizacji, albo odwrócić w czasie, co spowoduje że prawdopodobnie wyjdą na powierzchnię.", "Cywilizacja zaczęła wiercić wielkimi wiertłami w ziemi, ale zmiana kierunku ich rotacji spowodowała ich katapultację w kosmos. Planeta wygląda jak dziurawa.", "Mieszkańcy zaczęli masowo wiercić wiertłami w swojej planecie. Wkręcające się wiertła spowodowały aktywność wulkaniczną, trzęsienia ziemi i potoki lawy nawiedzają cywilizację."],
	6 => [12, 22, "Spowita magią", "Færie zamieszkują planetę. Nadnaturalne istoty, których potrzeby życiowe są teraz zupełnie inne. Magiczne rytuały są teraz odprawiane przez całe społeczeństwo. Magia krąży w kręgach. Możesz odwrócić kierunek krążenia magii i zobaczyć co się stanie, albo przyspieszyć i zobaczyć co społeczeństwo planuje.", "Magia, którą mieszkańcy zaczęli stosować, odwróciła bieg i zachwiała równowagą czasoprzestrzeni. Ziemia poczęła się wykrzywiać w nienaturalne kształty, a trzęsienia trzęsą mieszkańcami.", "Rytuał magiczny, który postanowili przeprowadzić mieszkańcy, się powiódł. Cywilizacja osiągnęła czwartą gęstość i nie potrzebuje już króla do pomocy. Planeta została uratowana na zawsze."],
	7 => [22, 13, "Zidiociali mieszkańcy", "Mieszkańcy planety są zidioceni. Nie myślą za wiele i mają problemy z pojmowaniem wszystkiego, co bardziej skompilowane. Z chęcią za to wynaleźli telewizję i oglądają tylko ją, powoli zdychając z głodu. Możesz cofnąć lecący serial, aby ciągle leciały powtórki. Jeśli przyspieszysz telewizję, to ludzie obejrzą jej jeszcze więcej.", "Cywilizacja uzależniła się od telewizji. Ciągłe powtórki w niej lecące spowodowały, że cywilizacja tak się ich nauczyła na pamięć, że sami stali się telewizją. Nie potrzebują realnego świata, ani nawet telewizora aby oglądać telewizję. Można powiedzieć, że nie potrzebują nawet Króla Czasoprzestrzeni. Zostali ocaleni przed realnym światem na zawsze.", "Masowe oglądanie telewizji w przyspieszonej wersji spowodowało, że każdy obejrzał wszystko, co mógł i teraz zaczął się nudzić."],
	8 => [13, 14, "Czas płynie wstecz", "Czas płynie teraz wstecz. Jako Króla Czasoprzestrzeni, nie rusza cię to za bardzo, lecz mieszkańcy twojej planety żyją odwrotnie, umierają przy narodzinach i rodzą się w grobach. Ponadto chodzą wstecz, a jedzenie jedzą odbytem, wyrzygując pełne kawałki. Trochę cię to obrzydza, więc postanowiłeś coś z tym zrobić. Czas płynie wstecz, więc możesz go zapętlić w miejscu za pomocą jeszcze większego cofnięcia. Ale jeśli zdecydujesz się przyspieszyć cofanie się czasu, to może uda ci się odwrócić jego bieg.", "Czas zaczął biec wstecz, więc postanowiłeś go zapętlić w miejscu. Tacy zapętleni mieszkańcy planety byli skazani na wieczne powtarzanie tych samych czynności. Wkrótce wkradła się pośród nich nuda.", "Czas zaczął płynąć wstecz, ale przyspieszyłeś jego cofanie poprzez puszczenie wprzód. Trochę to skomplikowane, że aż sam się pogubiłeś. Wygląda na to, że teraz czas jest powiązany w supełki."],
	9 => [14, 15, "Poza granicami przestrzeni", "Ty i twoja planeta zostaliście usunięci z wszechświata. Wykatapultowani poza czas i przestrzeń. Narażeni na działanie materii pozakosmicznej, co nikomu się nie podoba z oczywistych przyczyn. Mógłbyś coś z tym zrobić, ale jeśli nie ma już czasu, to i tak nie ma już czym sterować. Jedynym czasem, jaki jest wokół ciebie, jesteś ty sam, Królu Czasoprzestrzeni. Więc postanawiasz spróbować cofnąć siebie samego, może coś uda się zrobić. Nie uratujesz już pewnie planety, ale może uratujesz sam siebie. Ale gdybyś zdecydował się przyspieszyć sam siebie, to może udało by cię uciec z tej pułapki nie-czasu.", "Wypadłeś poza czas i przestrzeń, Królu czasoprzestrzeni, a tam postanowiłeś cofnąć samego siebie, aby cofnąć swoje wypadnięcie. Jednak zapomniałeś, że cofanie samej mocy cofnięcia powoduje cofanie cofania. To co innego, niż przyspieszenie albo brak cofania. Zacząłeś się zastanawiać, jak cofnąć cofnięcie cofania, ale zaplątałeś się w czasoprzestrzenne supełki. Twoja planeta także tam jest.", "Byłeś poza wszechświatem, Królu Czasoprzestrzeni, i postanowiłeś przyspieszyć samego siebie. Jednak to spowodowało że zestarzałeś się i umarłeś. Myślałeś, że moce czasoprzestrzeni dają nieśmiertelność? Jaka szkoda. Twoja planeta spoczęła na twoich truchle, tak samo martwa jak ty."],
	10 => [10, 10, "Zasłonięta przez asteroidy", "Gruba skorupa asteroid blokuje promienie słoneczne. Planeta zamarza, a mieszkańcy dostają depresji. To koniec tej cywilizacji.", "", ""],
	11 => [16, 17, "Poziurawiona", "Planeta posiada wiele dziur w podłożu, przez które począł się ulatniać groźny gaz. Mieszkańcy poczęli budować wielkie wentylatory, aby przegonić gaz w niezamieszkałe rejony. Jeśli odwrócisz czas, cały gaz zostanie zassany w drugą stronę. Jeśli przyspieszysz czas, być może ktoś lub coś zostanie porwane.", "Gaz z wyziewów, które powstały w skorupie planety, został zassany do miast. Mieszkańcy duszą się i umierają masowo.", "Gaz, który począł się ulatniać z wnętrza planety, nie jest już problemem, bo został zdmuchnięty razem z atmosferą planety."],
	12 => [17, 18, "Katastrofa wulkaniczna", "Trzęsienia ziemi i wulkany zaczęły nawiedzać świat. Lawa wypływa z każdego miejsca. Jeśli odwrócisz proces stygnięcia lawy, to zwiększysz jej temperaturę na tyle, aby może mogła wyparować. W przeciwnym wypadku przyspieszysz proces jej solidyfikacji.", "Rosnąca temperatura wyciekającej z wulkanów lawy spowodowała wzrost temperatury atmosfery, przez co zwiększyła swoją objętość i odleciała w przestrzeń.", "Lawa wydobywająca się ze szczelin wulkanicznych bardzo szybko wystygła, zamieniając krajobraz nie do poznania. Wysokie góry i pionowe ściany teraz są powszechnym widokiem."],
	13 => [19, 20, "Znudzeni mieszkańcy", "Nuda wkradła się w umysły ludzkości. To spowodowało, że zaczęli dążyć do zboczeń najróżniejszego typu, aby urozmaicić sobie życie. Odwrócenie ich zboczeń może wywołać dziwne efekty na ludziach, ale może także pomóc. Jeśli przyspieszysz ruchy zboczeniowe, to możesz być pewny że coś dziwnego z tego wyniknie.", "Zboczenia i wypaczenia ludzkości doprowadziły do dokładnie odwrotnych efektów. Teraz wszyscy są perfekcjonistami i dążą do czystości duszy.", "Cywilizacja wpadła w zboczenia i fetysze, które tylko się pogłębiały. Ostatecznie nawet kanibalizm nie był niczym niezwykłym."],
	14 => [20, 21, "Zaplątana w supły czasoprzestrzenne", "Czas jest powiązany w supełki. Wszystko dzięki tobie, Królu Czasoprzestrzeni. Próbujesz je rozwiązać, ale tylko sobie połamałeś swoje czasoprzestrzenne paznokcie. Rozwiązanie jest tylko jedno, czyli użycie czasoprzestrzennego noża i połączenie pociętej czasoprzestrzeni. Możesz naostrzyć go w odwróceniu lub przyspieszeniu czasu. Odwracający nóż połączy, co pocięte, co pozwoli ci żmudnie ponaprawiać wszystkie żeglarskie węzły czasoprzestrzeni. I może także naprawi ci paznokcie. Jeśli jednak zaczniesz ciąć czasoprzestrzenne supły nożem przyspieszającym, to czas i przestrzeń tylko jeszcze bardziej się rozerwą na kawałki.", "Czas był powiązany w supełki, a za pomocą swojego noża, Królu Czasoprzestrzeni, udało ci się pociąć supełki i przywrócić łańcuchy czasoprzestrzenne do pierwotnego kształtu. Tylko z jednym coś ci się nie udało i mieszkańcy twojej planety zamiast być na szczycie łańcucha pokarmowego, są w pętli.", "Czasoprzestrzeń była w supłach, a ty, Królu Czasoprzestrzeni, użyłeś swojego czasoprzestrzennego noża jak blendera. W efekcie czas nie ma już żadnych węzłów, jest teraz zmiksowaną zupą. Creme à la Tiempo."],
	15 => [15, 15, "Zestarzona na proch", "Ty i planeta zestarzeliście się na amen.", "", ""],
	16 => [0, 0, "Zagazowana", "Miasta są wypełnione gazem. Ludzie duszą się i nie mają ratunku. Zaczęli się modlić do starożytnych bóstw o zakończenie cierpienia. Czy chcesz przyspieszyć czy odwrócić w czasie ich śpiewy?", "Religijne śpiewy śpiewane przez mieszkańców wspak nie spodobały się bogom. Za karę cisnęli w planetę wielkim lodowym głazem.", "Śpiewy ludzi do bogów zadziałały ze zdwojoną siłą. Na nieboskłonie pojawił się ich bóg. I zmierza na ratunek."],
	17 => [0, 1, "Zgubiła atmosferę", "Atmosfery już nie ma. Teraz istnieje tylko goła ziemia. Mieszkańcy cywilizacji przyzwyczaili się do chodzenia wszędzie w skafandrach. Używają reaktorów chemicznych do produkcji tlenu. Czy chcesz odwrócić reakcję chemiczną w tych reaktorach, czy może przyspieszyć jeszcze bardziej.", "Mieszkańcy muszą chodzić w skafandrach i produkować powietrze reakcjami chemicznymi, które działają wspak i zamiast powietrza produkują ciało stałe. Przerażeni mieszkańcy katapultują jego kawałki w kosmos, gdzie tworzą wielką kulę.", "Skafandry są noszone przez wszystkich mieszkańców. Przyspieszenie reakcji chemicznych do produkcji powietrza dało mieszkańcom go tak dużo, że aż zaczęli pękać. Rany i infekcje bakteryjne nękają wszystkich."],
	18 => [0, 2, "Spowita labiryntem", "Mieszkańcy chodzą codziennie w labiryncie skał. To trenuje ich inteligencję. Zaczęli tworzyć nowe i wspaniałe dzieła, a każdy jest teraz wykształcony na poziomie doktora. Możesz cofnąć naukę albo przyspieszyć ją aby jeszcze szybciej ludzie się uczyli.", "Nauka wśród mieszkańców została cofnięta w czasie, rakiety wysyłane w kosmos nie potrafiły wykonywać swoich misji i zamiast tego zawieszały się w przestrzeni i zlepiały razem, tworząc wielką bryłę.", "Mieszkańcy tak bardzo posunęli się w nauce, że zaczęli modyfikować samych siebie. Ciężko powiedzieć, czy są teraz jeszcze żywymi istotami."],
	19 => [1, 3, "Perfekcyjna", "Perfekcyjny człowiek. Perfekcyjne myśli. Perfekcyjne ubranie. Wszystko w cywilizacji jest perfekcyjne, z wyjątkiem otoczenia. Dlatego mieszkańcy planety postanowili zbudować perfekcyjne miasto, w którym wszyscy perfekcyjnie zamieszkają. Możesz odwrócić czas dla budowanej właśnie konstrukcji, co z pewnością nie pozwoli osiągnąć społeczeństwu perfekcji ostatecznej i może sprowadzi cywilizację na nogi. Albo także przyspieszyć budowę, aby jeszcze szybciej osiągnęli nirwanę.", "Mieszkańcy stali się perfekcyjni, lecz nie mogli zbudować perfekcyjnego miasta. Nieperfekcyjność tej jednej rzeczy spowodowała masowe histerie i podcinanie sobie kończyn. Przez rany, perfekcyjnie wycięte, wdarły się rozmaite zakażenia.", "Perfekcyjność, która ogarnęła planetę, była tak silna, że jedyna nieperfekcyjna rzecz, która została, to byłeś ty, Królu Czasoprzestrzeni. Mieszkańcy mają dość sterowania czasem przez ciebie."],
	20 => [2, 3, "Kanibalizowana", "Kanibalizm szerzy się wśród mieszkańców. Pożerani są wszyscy w całości, albo przygotowywani w eleganckie posiłki. Nikt nie jest już bezpieczny. Mieszkańcy zbudowali gigantyczny gar na szczycie wulkanu, aby ugotować jednocześnie połowę swojej cywilizacji. Ale zanim zdążyłeś cokolwiek z garem zrobić, to już przystąpili do konsumpcji na wpół ugotowanych pobratymców. Możesz odwrócić czas w ustach kanibali, aby ludzie przestali zjadać się tak łapczywie. Albo może przyspieszysz jedzenie, aby się ostatecznie najedli.", "Kanibalizm w cywilizacji spowodował obżeranie się ludzi z mięsa nawzajem, ale jako że ich usta poczęły wydalać zamiast pochłaniać, to nie mogli zjeść się ostatecznie. Brakujące części ciała zastępowali maszynami, a niektórzy w całości się transformowali aby nie zostać zjedzonymi.", "Mieszkańcy stali się kanibalami, a ich usta wciągały siebie nawzajem z taką prędkością, że wkrótce nie było na planecie niczego do zjedzenia. Oprócz jednego. Oprócz ciebie, Królu Czasoprzestrzeni."],
	21 => [3, 3, "Pływa w zupie", "Czasoprzestrzeń jest zupą krem. Ty, Królu Czasoprzestrzeni, i twoja planeta taplacie się w niej. Przestrzeń jest zimna, toteż zaraz cała ta zupa zmienia się w chłodnik, a potem zamarza. Boisz się, że zamarznięta czasoprzestrzeń będzie gorsza nawet od powiązanej w supełki. Możesz odwrócić zamarzanie, dzięki czemu na pewno czas nie stanie w miejscu. Ale jeśli przyspieszysz zamarzanie, to może uda ci się zrobić czasoprzestrzenne lody.", "Czasoprzestrzeń zaczęła się gotować i zamieniać w czasoprzestrzenną parę. Mieszkańcy planety pocą się w niej aż w końcu mają tego wszystkiego dość, Królu Czasoprzestrzeni, i chcą się przeciwstawić tobie.", "Czasoprzestrzeń zmieniła się w lody, za sprawą twojej interakcji, Królu Czasoprzestrzeni. Są bardzo pyszne twoim zdaniem. Jednak ludzie na twojej planecie są innego zdania. Nie lubią lodów o smaku czasowym z kawałkami przestrzeni, a przestrzenne w polewie czasowej. Chcą cię zniszczyć, aby stworzyć własne lody."],
	22 => [22, 22, "Osiągnęła czwartą gęstość", "Ludzkość została wyniesiona ponad płaszczyzny astralne", "", ""]
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

sub restartUniverse
{
	# Resetowanie wszechświata
	foreach(@sortids)
	{
		my $id = $_;
		$planetalive{$id} = 1;
		$planetproblem{$id} = int(rand(keys %PROBLEMLIST));
		appendLog($id, "Czasoprzestrzeń postanowiła zadbać o samą siebie poprzez zresetowanie wszechświata. Twoje próby powstrzymania jej skończyły się na tym, że każda planeta została nawiedzona przez losową katastrofę. Masz teraz dużo do roboty, Królu Czasoprzestrzeni.");
	}

	print "<h2>Wszechświat jest martwy. Twoje akcje, Królu Czasoprzestrzeni, spowodowały zagładę i ocalenie wszystkich planet, jakie istnieją.</h2>\n";
	print "<p>Czasoprzestrzeń postanowiła zresetować samą siebie, nie bacząc na ciebie, Królu Czasoprzestrzeni. Nie możesz nic z tym zrobić.</p>\n";
	print "<p><a href='?'>Możesz tylko stać i patrzeć</a></p>\n";
}

sub runCore
{
	my @freeplanets = ();
	my $universedead = 1;
	foreach(@sortids)
	{
		my $id = $_;
		if($planetalive{$id} >= 0 and $planetavailable{$id})
		{
			push(@freeplanets, $id);
		}
		if($planetalive{$id} >= 0)
		{
			$universedead = 0;
		}
	}
	
	if($universedead)
	{
		restartUniverse;
		return;
	}
	
	# Wypisz wszystkie światy
	print "<h1>Cywilizacja potrzebuje twojego ratunku</h1>\n";
	print "<h2>Światy wołające o pomoc:</h2>\n";
	print "<table>\n";
	foreach(@sortids)
	{
		my $id = $_;
		my $state = "";
		if(not $planetavailable{$id})
		{
			$state = "W wirze czasu";
		}
		else
		{
			my $planetproblem = $planetproblem{$id};
			my $problemshort = $PROBLEMLIST{$planetproblem}[2];
			$state = "$problemshort";
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
	my $problemtext = $PROBLEMLIST{$currentproblem}[3];

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
	my $problemtext = $PROBLEMLIST{$problem}[3];
	my $reversesolution = $PROBLEMLIST{$problem}[4];
	my $forwardsolution = $PROBLEMLIST{$problem}[5];
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
		$planetalive{$id} = -1;
	}
	if($PROBLEMFIX{$nextproblem})
	{
		print "<p>Cywilizacja planety $planetname{$id} została permanentnie ocalona.</p>";
		$planetalive{$id} = -2;
	}
	
	print "<a href='?'>Spróbuj ponownie</a>";
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

