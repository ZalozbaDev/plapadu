#!/usr/local/bin/perl -w -I/Users/edi/Documents/Projekty/tts
# Edward Wornar, 2020
# Published under the GNU Public License
# Q&D script for using the Polish voice to speak DSB output
# will be called by an Apple Script or similar (eg)

use strict;
use warnings;

use Number::Convert::Roman;
# use Roman; # this also accepts nonsense so we have to validate them ourselves

use TeX::Hyphen;

use utf8;
use open ":encoding(utf8)";
use open IN => ":encoding(utf8)", OUT => ":utf8";



sub display_help_and_exit {

    print STDERR <<EOF;
# $0, a  QnD tts preprocessor for Upper and Lower Sorbian using existing Polish voices
# by Eduard Werner, licensed under GPL
# Version 0.0 (pre-alpha), very buggy, could break just about anything 
#
# process command line arguments
# --tts <name of tts file> (default: patterns.tts)
# --tex <name of hyphenation patterns> (default: hyphen.tex)
# --mydict <name of user dict> (default: none)
# --help : display this message
# --lang <hsb/dsb> : select language
# --infile <file name> : select file to read from (default: STDIN)
# --outfile <file name> : select file to write to (default: STDOUT)
# --mute : don't send output to 'say'

EOF

    exit();

}



# dawkow klinči nazalizowane, snano lěpje dawkuł
# BUG l.pl -ach > ak ???
# problem dn žadna vs. žana


# nastajenja

my $debug = 0;
    

my $hsb = 1;

if ( $0 =~ m/dsb/ ) {
    $hsb = 0;
}

my $year = 1; # parse numbers as years, if appropriate

# not used yet, will go into file

my $exclude_XL = 1;
my $exclude_L = 1;

my $chatty = 0;
my $mute = 0;

my $tts_file =  "patterns.tts";

my $tex_file =   "hyphen.tex";

my $userdict_file; # same syntax as patterns.tts, but for user-specific stuff
# e.g. special abbreviations for certain text types would go here

my $infile = "";
my $outfile = "";



my $infile_h = *STDIN;
my $outfile_h = *STDOUT;



for ( my $i = 0; $i <= $#ARGV; $i++ ) {
    if ( $ARGV[$i] =~ m/--tts/ ) {    
	$tts_file = $ARGV[++$i];
    } elsif ( $ARGV[$i] =~ m/--tex/ ) {    
	$tex_file = $ARGV[++$i];
    } elsif ( $ARGV[$i] =~ m/--mydict/ ) {    
	$userdict_file = $ARGV[++$i];
    } elsif  ( $ARGV[$i] =~ m/--lang/ ) {
	if  ( $ARGV[++$i] =~ m/hsb/ ) {
	    $hsb = 1;
	} else {
	    $hsb = 0;
	}
    } elsif  ( $ARGV[$i] =~ m/--mute/ ) {
	$mute = 1;
    } elsif ( $ARGV[$i] =~ m/--infile/ ) {
	$infile = $ARGV[++$i];
	open( $infile_h, "<", $infile ) or die "Can't open $infile for reading: $!";
    } elsif  ( $ARGV[$i] =~ m/--outfile/ ) {
         $outfile = $ARGV[++$i];
	open( $outfile_h, ">", $outfile ) or die "Can't open $outfile for writing: $!";
    } elsif  ( $ARGV[$i] =~ m/--help/ ) {
    display_help_and_exit();
    } # if

} # for

# should be redundant, but still does not work when called from applescript
binmode($infile_h, ":utf8");
binmode($outfile_h, ":utf8");


if ($chatty ) {

    printf(STDERR  "Patterns: %s\n", $tts_file);
    printf(STDERR "Reading from: %s\n", $infile);
    printf(STDERR "Writing to: %s\n", $outfile);
}

my $hyp;

if ( -e $tex_file ) {
  $hyp = new TeX::Hyphen 'file' => $tex_file,
  'style' => 'utf8', leftmin => 1,
  rightmin => 2;
} else {
  die   "Hyphenation patterns not found";
}

if ( $userdict_file ) {
    if ( $chatty ) {
    printf(STDERR   "Patterns: %s\n", $userdict_file);
  }

  open( my $userpattern_fh, '<', $userdict_file ) or die $!;

  my @raw_userpatterns = <$userpattern_fh>;

  chomp( @raw_userpatterns );

  my %special_userpatterns = ();
  my @special_userkeys = (); # array to ensure that the rules are ordered

  my $y = 0;
  
  foreach my $r ( @raw_userpatterns ) {
    if ( $r !~ m/^#/ ) { # comments start with '#' as the first character
      (my $spelling, my $reading ) = split(/\@/,$r);
      $special_userpatterns{$spelling} = $reading;
      $special_userkeys[$y] = $spelling;
      $y++;
    }
  }
} else {
  if ( $chatty ) {
    printf(STDERR   "No user-defined dictionary\n");
  }
}

open( my $pattern_fh, '<', $tts_file ) or die $!;

my @raw_patterns = <$pattern_fh>;

chomp( @raw_patterns );

my %special_patterns = ();
my @special_keys = (); # array to ensure that the rules are ordered

my $x = 0;
  
foreach my $p ( @raw_patterns ) {
  if ( $p !~ m/^#/ ) { # comments start with '#' as the first character
    (my $spelling, my $reading ) = split(/\@/,$p);
    $special_patterns{$spelling} = $reading;
    $special_keys[$x] = $spelling;
    $x++;
  }
}

# FEATURES:
# ličby: Romske a arabske ličby, heuristika za lětoličby a ordinale < 1000, 
# TODO: čas a datum  13:45 hodź. -> 13:45
# TODO: XL a L z romskich licbow won wzac jako opcija (we walidaciji romskich licbow)
# Ewa cita X = duze X, XII = dwunasty, L = duze L, LII= li
# Ewa cita 67. raz kaz 67 raz !!!
# pólska asimilacija: setmy (tohodla sedy my)
# prefiksy TODO: wotdźělić
# skrótšenki: TODO: jednotliwe pismiki
# Němske mjena -> du do patterns.tts



# WIP: skrótšenki, skrótšenki


# WIP: ličby (na př. l. 1945), daty, časy spóznać, romske licby, ličba-ličba

# Hanka (so ok wurjekuje)

my %pismiki = (
	       'a' => 'a',
	       'b' => 'bej',
	       'c' => 'cej',
	       'c' => 'cej',
	       'ć' => 'czet',
	       'č' => 'czej',
	       'd' => 'dej',
	       'e' => 'ej',
	       'ě' => 'iet',
	       'f' => 'ef',
	       'g' => 'gej',
	       'h' => 'ha',
	       'i' => 'i',
	       'j' => 'jot',
	       'k' => 'ka',
	       'l' => 'el',
	       'm' => 'em',
	       'n' => 'en',
	       'ń' => 'ejn',
	       'o' => 'oł',
	       'ó' => 'ut',
	       'p' => 'pej',
	       'q' => 'ku',
	       'er' => 'er',
	       'ř' => 'ersz',
	       's' => 'es',
	       'š' => 'esz',
	       'ś' => 'śej',
	       'ŕ' => 'mieke er',
	       't' => 'tej',
	       'u' => 'u',
	       'v' => 'fał',
	       'w' => 'łej',
	       'ł' => 'eł',
	       'x' => 'ikx',
	       'y' => 'ypsji lon',
	       'z' => 'zet',
	       'ź' => 'źet',
	       'ž' => 'žej',
	       'ä' => 'a-umlałt',
	       'ö' => 'o-umlałt',
	       'ü' => 'u-umlałt',
	       'ß' => 'escet',

);

my @licby = ("nul", "jaden", " dwa", " ći", " styri", " pieś", " szesć", " sedym", " wesym", " zieweś", " ziaseś", " jadna śćio", " dwana śćio", " tśina śćio", " styrna śćio", " pieśna śćio", " szesna śćio", " sedymna śćio", " łesymna śćio", " zieweśna śćio", " dwazia śćia");
my @zasetki = (" ", " ", " dwaźa śćia", " tśiźa śćia", " styrźa śćia", " pułsta", " szesdziaset", " sedym ziaset", " łesym ziaset", " ziewe ziaset"); # wažne: styrzia ścia so čita kaž styrzieścia, tuž dyrbi źa wostać

my @licby_ord = ("nulty", "predny", " drugi", " ćiesi", " stłerty", " piety", " szesty", " sedy my", " łesmy", " ziewety", " ziasety", " jadna sty", " dwana sty", " tśina sty", " styrna sty", " pieśna sty", " szesna sty", " sedymna sty", " łesymna sty", " zieweśna sty", " dwazia sty", "jaden a dwazia sty", "dłwaja dwazia sty", "ći a dwazia sty", "styri a dwazia sty"  );
my @zasetki_ord = (" ", " ", " dwaźa sty", " tśiźa sty", " styrźa sty", " pułsta ty", " szesdziase ty", " sedym ziase ty", " wesym ziase ty", " ziewe ziase ty"); # wažne: styrzia ścia so čita kaž styrzieścia, tuž dyrbi źa wostać

my @stotki = ( " ","sto","dwiysći","tsista","styri sta","pieś stoł","szesć stoł","sedym stoł","wesym stoł","zieweś stoł");

my @wulke_licby = (" "," tułzent"," miljołn"," miljar"," biljołn"," biljar"," triljołn"," triljar"," kładriljołn"," kładriljar");

my @miljon = ( "oł ", " ", "a ", "y ", "y "); # kóncowki za -liony 0, 1, 2, 3, 4
my @miljarda = ( "doł ", "da ", "źie ", "dy ", "dy "); # kóncowki za -ardy 0, 1, 2, 3, 4

# snano tež za dźělenje dla přizwuka
my @prefiksy = ( "do", "na", "nad", "nje", "pe", "pod", "psze", "pszed", "pszi", "roz", "s", "o", "ob", "łet", "łu", "za");

if ( $hsb ) {

    @licby_ord = ("nulty", "prienji", " druji", " tsjeći", " sztłurty", " piaty", " szesty", " sedy my", " łosmy", " dźejaty", " dżesaty", " jiydna ty", " dłana ty", " tsjina ty", " sztyrna ty", " piatna ty", " sziysna ty", " sydomna ty", " łosomna ty", " dżejatna ty", " dwace ty",  "jena dwace ty", "dłaja dwace ty", "tsjija dwace ty", "sztyri a dwace ty",);
    @zasetki_ord = (" ", " ", " dłace ty", " tsjice ty", " sztychce ty", " pułsta ty", " sziesdżesa ty", " sedymdżesa ty", " łosomdżesa ty", " dziełeć dżesa ty");

    @licby = ("nul", "jen", " dwaj", " tsji", " sztyri", " pecz", " sziysć", " sydom", " łosom", " dżełeć", " dżesać", " jiydna ćie", " dłana ćie", " tsjina ćie", " sztyrna ćie", " piatna ćie", " sziysna ćie", " sydom naćie", " łosom naćie", " dżejat naćie", " dwace ći");
    @zasetki = (" ", " ", " dłace ći", " tsjice ći", " sztychce ći", " pułsta", " sziesdżesat", " sydom dżesat", " łosom dżesat", " dżełejć dżesat");


    @stotki = ( " ","sto","dwiysći","tsjista","sztyri sta","pecz stoł","sziysć stoł","sydom stoł","łosom stoł","dziełeć stoł");

    $wulke_licby[1] = " tysac";

    @miljon = ( "oł ", " ", "aj ", "y ", "y "); # kóncowki za -liony 0, 1, 2, 3, 4
    @miljarda = ( "doł ", "da ", "dźie ", "dy ", "dy "); # kóncowki za -ardy 0, 1, 2, 3, 4

    # za determinowanje změny ch -> k, tohodla ´z´ njeje pódla. ups, snano tež za dźělenje dla přizwuka
    @prefiksy = ( "do", "na", "nad", "nje", "po", "pod", "psze", "pszed", "pszi", "roz", "s", "ło", "łob", "łot", "łu", "za");

} # if hsb


my $commastring = " koma ";

# PISMIKOWANJE (NOT YET FULLY IMPLEMENTED)

sub pismikuj {
  my $abbrev = $_[0];
  # $abbrev =~ s/([[:upper:]])|([[:lower:]])/defined $1 ? lc $1 : uc $2/eg; # utf-8 conversion to lowercase
  $abbrev =~ s/([[:upper:]])/defined $1 ? lc $1 : $1/eg; # utf-8 conversion to lowercase
  $abbrev =~ s/ (\p{CWL}) /defined $1 ? lc $1 : $1/gex;
  my @pismikowanje = split('',$_[0]);
  foreach my $p (@pismikowanje)  {
    if ( $pismiki{$p} ) {
      print $pismiki{$p};
    }
  }
}


# NUMBER ROUTINES

sub is_roman {
    my $number = $_[0];
    if ( $number  =~ m/^(?=[MDCLXVI])M*(C[MD]|D?C{0,3})(X[CL]|L?X{0,3})(I[XV]|V?I{0,3})$/ ) {
	return(1);
    }
    return(0);
}

sub malpli_ol_mil {
    use integer;
    my $number = $_[0];
    my $is_ord = $_[1];
    my $numberstring =  " ";

    if ( $number > 999 ) {
	return(  " Eraro 0! $number" );
    }
    my $hundreds = $number / 100;
    my $rest = $number % 100;
    if ( $hundreds >= 1) { # JOW DALE
	$numberstring .= $stotki[$hundreds];
    } elsif ( $hundreds == 1 ) {
	$numberstring .= "sto";
    }
    $numberstring .= eta_nombro($rest, $is_ord);
    return( $numberstring );
}


sub eta_nombro { # for numbers < 100 
    # returns empty string for 0
    use integer;
    my $number = $_[0];
    my $is_ord = $_[1];
    # boundary checks
 
   if ( $number == 0 ) {
	return( " " ); # nic nul dla wulkich ličbow
    }
    if ( $number > 99 ) {
	return( " Eraro 1! $number" );
    }
    if ( $number < 21 ) {
	if ( $is_ord ) {
	    return( $licby_ord[$number] );
	} else {
	    return( $licby[$number] );
	}
    }
    my $tens = $number / 10;
    my $rest = $number % 10;
    #print $tens;
    #print "  ";
    #print $rest;

    if ( $tens >= 2 ) { # $tens is at least 2
    	if ( $rest > 0 ) {
	    if ( $is_ord ) {
		return( sprintf("%s a%s",$licby[$rest], $zasetki_ord[$tens]));
	    } else {
		return( sprintf("%s a%s",$licby[$rest], $zasetki[$tens]));
	    } # is_ord
	} else {
	    if ( $is_ord ) {
		return( $zasetki_ord[$tens] );
	    } else {
		return( $zasetki[$tens] );
	    }
	}
	    
    } else {
	return( " Eraro 2! $number " );
    }
}

sub spell_number {
    my $number = $_[0];
    my $numberstring = "";
    my @number_array = split(//,$number);
    for ( my $i = 0; $i <= $#number_array; $i++ ) {
	$numberstring .= $licby[$number_array[$i]];
    }
    return( $numberstring );
}


sub ordinala_nombro {   # jako ordinale spóznaja so jeno \d+.
  my $number = $_[0]; # hmmm, chcemy tu to samsne kaz za wulke kardinale ????
  return( malpli_ol_mil( $number, 1 ));
}

sub horo { # jako čas mamy podaća z ´hodź.´, opcionalnje slěduje \d\d mjeńš.
  my $string = $_[0];
  
}

sub jaro {
    use integer;
    my $number = $_[0]; # four digits, first is '1', first two from licby, second from zasetki and licby
    my $first = substr( $number, 0, 2 );
    my $second = substr( $number, -2 );
    my $numberstring;
    
    if ( $number > 1999 ) { # kak ma so to podać: tuchwilu so 2021 jako 21 wróći
	if ( $debug ) {
	    print  STDERR "DEBUG 4: jaro: lětoličba dyrbi być < 2000 ";
	}
	
    } else {
	$numberstring = $licby[$first];
	$numberstring .= " stoł ";
    }
    $numberstring .= eta_nombro( $second, 0 );
    
    return( $numberstring );
}

sub genitiw {
    my $nominatiw = $_[0];
    chop( $nominatiw ); # chop of final y/i
    if ( $hsb ) {
	return( $nominatiw . "o" );
    } else {
	return( $nominatiw . "ego" );
    }
}

sub plena_dato {
    my $date = $_[0];
    my @date_parts = split(/\./,$date);
    my $year_string;

    $year_string .= genitiw(ordinala_nombro( $date_parts[0] ));

    $year_string .= " ";
    
    $year_string .= genitiw(ordinala_nombro( $date_parts[1] ));
    
    $year_string .= " ";
    
    if ( length($date_parts[2]) == 4 ) {
	$year_string .= jaro( $date_parts[2] );
    } elsif  ( length($date_parts[2]) == 2 ) {
	$year_string .= eta_nombro( $date_parts[2] );
    } else {
	printf STDERR "Zmylk: plena_dato\n";
    }
    return( $year_string );
}

sub analizu_nombron {
    use integer;
    my $number = $_[0];
    my @groups_of_three;

    my $numberstring = ""; # collecting here with sprintf

    my $ordinal;

    # is it an ordinal number == does it have a dot at the end and only digits?
    # BUG: This will not be able to look at gender or inflexion
    # BUG: This does not work correctly with numbers at the end of a sentence, but there mainly years occur which is why we capture those first.


    if ( $year &&
	( ($ordinal) = $number =~ m/^\s*(1\d\d\d)\.?\s*$/ )) { # 1 and three more digits is a year by default
	return(jaro($ordinal));
    }

    if ( ($ordinal) = $number =~ m/^(\d+)\.$/ ) {
	return(ordinala_nombro($ordinal));
    }

    if ( ($ordinal) = $number =~ m/^(\d\d\.\d\d.\d\d(\d\d)?)$/ ) {
	return(plena_dato($ordinal));
    }

    # get rid of spaces and dots
    $number =~ s/[ .]+//g;

    my @around_comma = $number =~ m/(\d+),(\d+)/;

    if ( ! $around_comma[1] ) {
	$around_comma[0] = $number;
	$around_comma[1] = "";
    } else {
	$numberstring = spell_number($around_comma[1]);
	unshift(@groups_of_three, $numberstring);
	unshift(@groups_of_three, $commastring); # lang-dep
    }
    
    # printf("%s : %s\n", $around_comma[0], $around_comma[1]);

    my $three_digits;
    my $porjad = 0; # points to element of @grandaj_nombroj

    # take the last three digits and push
    $three_digits = substr($around_comma[0],-3,3,"");
    #printf("%s\n", $three_digits);
    while ( $three_digits ) {
	if ( $three_digits !~ m/000/i ) { 
	    $numberstring = malpli_ol_mil($three_digits, 0 );
	    $numberstring .= " ";
	    $numberstring .=  $wulke_licby[$porjad]; # '', mil, milijono ...

	    if ( $porjad >= 2 ) { # zane kóncowki za hundert, towzynt
		my $i = $three_digits % 10;
		if (($three_digits > 4) || ($i > 4 )) {
		    $i = 0;
		}
		if ( $wulke_licby[$porjad] =~ m/ar$/g ) {
		    $numberstring .= $miljarda[$i];
		} else {
		    $numberstring .= $miljon[$i];
		}
	    }
	    unshift( @groups_of_three, $numberstring);
	} # if 000
	$three_digits = substr($around_comma[0],-3,3,"");
	$porjad++;
    } # while
    return( join(", ", @groups_of_three));
} # sub analizu_nombron

# END OF NUMBER ROUTINES

# HYPHENATION ROUTINES

my @words;
my $hyphenated;
 
sub optimise_hyphens {
  my $hyphenated_word = $_[0];

  # get rid of obvious errors in the TeX::Hyphen output:
  # if the last letter is hyphenated, get rid of the hyphen
  #    dósta-ł (rightmin seems to be ignored)

  $hyphenated_word =~ s/-(.)$/$1/;

  # cases with -- need to be fixed

  $hyphenated_word =~ s/--+/-/g;

  # cases with following interpunction need to be fixed

  $hyphenated_word =~ s/-(.)([,.;:])$/$1$2/;

  # cases with hyphen and no vowels following

  $hyphenated_word =~ s/(.+)-([^aeiouyó]+)$/$1$2/g;

  # TODO: Problemy z Ewu
  
  $hyphenated_word =~ s/-ko/ko/g; # Ewa čita k.o.
  $hyphenated_word =~ s/-sko-/sko/g; # Ewa čita s-k-o
  $hyphenated_word =~ s/-kó-/kó/g; # Ewa čita k.o.

  # special case: if -ł-ł gets generated, it needs to become ł-ł

  $hyphenated_word =~ s/-ł-ł/ł-ł/g;

  # if there is a hyphen in front and after a non-vowel letter, get rid of one
  # (the first one for now)
  
  $hyphenated_word =~ s/-([^aeiouy])-/$1-/;

  # obvious errors are fixed now

  
  if ( $hyphenated_word =~ m/#/ ) {
      # then it could contain a hyphen or ´#´ as a marker for the accentuated syllable
      # in this case the hyphen before the # will not be deleted, the one after will, the next one will not
      # then the hash has to be removed
      # TODO: Prawidła horjeka, kiž manimuluja smužki, dyrbja 
      # gra#tulowacymi -> gra#tu-lo-wa-cy-mi gratulo-....
      if ( $debug ) {
	  print STDERR "DEBUG 0: Special accent (TBD): ", $hyphenated_word, "\n";
      }
      my @two_parts = split( /#/, $hyphenated_word );
      
      if ( $two_parts[1] =~ m/-/ ) {
	  
	  $two_parts[0] =~ s/-//g; # get rid of all hyphens before the accented syllable
	  # this could break cases in which the accented syllable is the last one, e.g. stu-dent
	  # so it should not delete all hyphens unless there is one in the second part of the word
	  # for which we have checked in the if-clause
	  $two_parts[1] =~ s/-//; # delete the first hyphen of the second part
	 # now there are two syllables after the accent which should work for Ewa
      } else { # no hyphens in the second part after the accent
	  # if there isn´t it should keep the last hyphen in $two_parts[0]
	  # so we check whether there are two hyphens, if yes delete one and repeat
	  while ( $two_parts[0] =~ m/-[^-]+-/ ) {
	      $two_parts[0] =~ s/-//;
	  }
      }
    $hyphenated_word = $two_parts[0];
    $hyphenated_word .= $two_parts[1];

      
  } else {
  
    # if there is only one hyphen, get rid of it
    
    my $count = ($hyphenated_word =~ tr/-//);
    if ( $count == 1 ) {
      $hyphenated_word =~ s/-//;
    } 
    
    # if there are two hyphens, keep the second one
    
    elsif ( $count == 2 ) {
      $hyphenated_word =~ s/-//;
    } 
    
    
    # if there are many, let's think about it
    # TODO: there should be foreign words with a fixed non-initial accent
    # ini-cjatiwa ini-cjatiwa-mi -> these go probably at the start of this
    # strategija
    
    # and there are long words we´ll just keep as-is for the time being
    # TODO: let´s try: leave the last, delete the second byt last, leave the third but last ...
    # -xxxx-yyy -> xxxx-yyy
    
    else {
      
      $hyphenated_word =~ s/([^-]+)-([^-]+)-([^-]+)-([^-]+)-([^-]+)-([^-]+)-([^-]+)/$1$2-$3$4-$5$6-$7/;
      $hyphenated_word =~ s/([^-]+)-([^-]+)-([^-]+)-([^-]+)-([^-]+)-([^-]+)/$1-$2$3-$4$5-$6/;
      $hyphenated_word =~ s/([^-]+)-([^-]+)-([^-]+)-([^-]+)-([^-]+)/$1$2-$3$4-$5/;
      $hyphenated_word =~ s/([^-]+)-([^-]+)-([^-]+)-([^-]+)/$1$2-$3-$4/;
    } # else count
  } # else (no special accent wit '#'
  return $hyphenated_word;
} # optimise_hyphens


      
sub check_hyph_exception {
  my $hyphenated = $_[0];

  # check whether it is an exeption !!!
  # BUG (fixed Nov 21, 2020): the hash is not sorted as an array, so we need two arrays to be sure the order of the rules is honored
  # BUG: this needs to be called before the hyphens are inserted, or the patterns won´t match -> optimise_hyphens

  for ( my $x = 0; $x <= $#special_keys; $x++ ) {
    if ( $hyphenated =~ $special_keys[$x] ) {
      $hyphenated =~  s/$special_keys[$x]/$special_patterns{$special_keys[$x]}/e;
      last;
    }
  }
  return( $hyphenated );
}


# END OF HYPHENATION ROUTINES


# main loop


while(<$infile_h>){
    chomp();

    s/(\d+)\s*-\s*(\d+)/$1 do $2/g; # add other hyphen charakters here

    # check special patterns z patterns.tts, kiž su w %special_patterns

    #foreach my $key ( keys %special_patterns ) {
	#s/$key/$special_patterns{$key}/ge;
    #}

    # stupid, since we are doing it twice (once again later)
    # for now we only want to check for stress and insert a marker for irregular stress
    # Later, we will deal with hyphenation which we want to do after converting the orthography
    # because it needs to deal with orthographically polonised Sorbian so it can be fed to Ewa
  
    s/-/ /g; # get rid of existing hyphens which do break hyphenation sometimes
    
    @words = split(/ +/);
    my $single_word;
    
    #for ( my $i = 0; $i <= $#words; $i++) {
    #  $single_word = check_hyph_exception($words[$i]);
    #  s/$words[$i]/$single_word/; # this is principielly buggy, but we might get away with it ...
    #}
    # end of documented stupidity

    
    #fix some words
    #s/charakt/ka-rakt/gi;
    s/(\b)chat/$1czet,/gi;
    s/(\b)chem/$1siem/gi;

    # cuze słowa za wobě rěči
    # te dyrbja hišće marker dóstać, zo so dale njemanipuluja
    s/serij/zejrij/gi;
    s/klawsur/klawzur/gi;
    s/([fF])onet/$1onejt/gi;
    s/[rR]egul/rejgul/gi;
    s/[zZ]ašł/zajšł/gi;
    s/[sS]aks/zaks/gi;
    s/[sS]alom/zalom/gi;
    s/jerusalem/jeruza-lem/gi;
    s/saněr([ou])/za-nier$1-/g;
    s/Saněr([ou])/Za-nier$1-/g;
    s/([tT])em([au])/$1ejm$2/gi;
    s/([tT])ejmati/$1ejmati-/gi;
    s/([tT])ermino([^l])/$1ermino-$2/gi;
    s/semest/zemest/gi;
    s/Semest/Zemest/gi;
    s/referat/refe-rat/gi;
    s/Referat/Refe-rat/gi;
    s/(\b)sub/$1zub/gi;
    s/konkret/konkrejt/gi;
    s/šlesk/šlejsk/gi;
    # s/ a /, a /g;
    s/(\b)t\. *r\./$1to rěka/gi;

    # fix misc stuff THIS HAS TO GO TO PATTERNS.TTS

    s/prestiž/pre-stiž/gi;
    s/system/zy-stejm/gi;
    s/bachel/becze-l/gi; # bachelor
    s/discipl/discjipl/gi; # disciplina
    s/uniwersi/unji-werZji/gi;# uniwersita
    s/uniwers/unji-werZ/gi;# uniwersum, uniwersalny etc.
    s/imersi/imerZji/gi; # imersija etc
    s/wersi/werZji/gi;
    s/sorab/zorab/gi; # sorabistika
    s/absolwe/abzolve/gi;
 
    s/([aouiey])ěr(ow|uj)/$1ir$2/gi;
    s/nosće/no-scie/gi;
    s/nosći/no-sci/gi;
 
    s/na pś\./na pśikład/gi; # njefunguje ????
    s/atd\./a tagdalej/gi;
    s/mj\. *dr\./mezdrujim/gi; 
    s/(\b)abc(\b)/$1abej cej$2/gi;

    # młody, młyn, błóto, płót, płokać

    s/młod/mod/gi;
    s/młyn/myn/gi;
    s/błót/bót/gi;
    s/płót/pót/gi;
    s/płók/pok/gi;

    if ( $hsb ) {
	# hołb, łubja
	
	s/hołb/hu-jib/g;
	s/łubj/łujb/g;

	# rěč, rěčeć, rěbl, Pětr

	s/rěč/rycz/gi;
	s/rěbl/rybl/gi;

	# kaž, tuž, kóždy, běžeć, stwě -> j epentheticum
	s/(\b)kaž(\b)/$1kajž$2/g;
	s/(\b)kóžd/$1kujžd/g;
	s/běž/bejž/g;
	s/lež/lejž/g;
	s/stwě/stwi/gi;
	s/(\b)tež(\b)/$1tejž$2/gi;
	s/jenož/jenojž/gi;
	s/(\b)w l\./$1w lěće/gi;
    }

    # s/(\b)njejs/$1nejs/gi; #njejsym

    # Pětr
    s/Pětr(\b)/Piytor$1/gi;
    s/Pětr/Piytr/gi;

    # VN na -enje, -eće
    s/enj([eau]\b)/ejnj$1/gi;

    # mječ, pječ, wječor
    s/ječ/ejč/gi;

    # find roman numbers and convert them before the v's and x's disappear ...

    my @all_roman_nums =  $_ =~ m/\b([MDCLXVI]+)\b/g; # jenož wulke romske ličby, zo njeby chaos přewulki był
    # TODO: Měli so do ordinalow konwertěrować, jeli slěduje dypk
    # TODO: Měli so do praweje gramatiskeje formy konwertěrować
    # PROBLEM: z mjezotami w regex, XI XIb so konwertuje na tycac a jedyn b
    # PROBLEM: hdyz so korektna romska licba jewi jako dzel dalseho wuraza, so globalnje sobu wuziwa:
    # XL XLL -> styrziascia, styrziasciaL
    # XL a L stej dzensa skerje wulkosci ...

    my $converter = Number::Convert::Roman->new;


    for my $i ( 0 .. $#all_roman_nums ) {
	if ( is_roman($all_roman_nums[$i]) ) { # valid roman number
	    my $result = $converter->arabic($all_roman_nums[$i]);
	    s/$all_roman_nums[$i]/$result/;
	}
    }

    # parse for arabic numbers

    my @all_nums = $_ =~ m/(\d[\d.]*(,\d+)*)/g; 


    for ( my $i = 0; $i < $#all_nums; $i++) { # for weird reasons, there may be uninstantiated bits, so we have to check
	# print $all_nums[$i];
	if ( $all_nums[$i] ) {
	    if ( $debug ) {
		print STDERR "DEBUG all_nums: ", $all_nums[$i], "\n";
	    }
	    my $result = analizu_nombron($all_nums[$i]);
	    #IMPORTANT: no /gi because only one element must be replaced
	    s/$all_nums[$i]/$result/;
	}
    } 


    if ( $hsb ) { 
        # wuwzaći zdźeržaneho g
	s/nahle/nagle/gi;
	s/kohlic/koglic/gi;
	s/bóh/bół/gi; # Ewa bó  pismikuje ...
	s/(\b)ćel(o|eć|at)/$1ćěl$2/gi; # wurjekowanje ćelo
	s/swjedź/słejdź/gi;

    } else {
	s/serbsk/sersk/gi;
	s/cas/tsas/gi;  # Ewa čita ´k´ ...
	s/prědn/predn/gi;
	s/slědn/sledn/gi;
    }

    # TOFO
    # ttsmp3(.com) a speech2go lěpje klinčitej z liarzecu, takie, kencz
    # apple say druhdy wuzwukowe e nazaluje ...

    # interpunkciske znamješka -> tuchwilu prosće won
    s/([.,;:?!])/ $1/gi;

    # cuze pismiki
    s/x/ks/gi;
    s/q/kw/gi;
    s/[äö]/e/gi;
    s/ü/i/gi;
    

    # po csz pólski algoritmus i hinak interpretuje ...
    #s/ci/cy/gi;
    #s/zi/zy/gi;
    #s/si/sy/gi;
    #s/([csz])i/$1ji/gi;
    #s/([csz])ij/$1j/gi; # funkcija -> funkcja
    s/([csz])ij/$1yj/gi; # funkcija -> funkcja
    s/([sz])ě/$1jie/gi; # kwalificěrować etc.
    s/([sz])i/$1ji/gi; # iniciatiwa
    s/cě/tsjie/gi; # kwalificěrować etc.
    s/ci/tsji/gi; # iniciatiwa
  
    # w etc

    s/ł/w/gi; # ł čini problemy za regex, njewěm čehodla ...


    s/([dtkgsz])w([\s\b])/$1$2/gi; #w/ł na kóncu słowa won - njas, wjaz

    s/ w([^jaěeoóiuyw ])/ $1/gi;  #w/ł před konsonantom
    s/ wj([aou])/ j$1/gi;  #w/ł před konsonantom
    s/wj([ěe])/w$1/gi;  #w/ł před e, ě


    s/([pbmn])j/$1i/gi;

    if ( $hsb ) {
	s/(\b)w([uo])/ł$2/gi; # w > 0 na spočatku słowa
	# stuff with h
	s/([^c])h([^aeiouěó ])/$1$2/gi; # remove h before consonant, but not word-final since Ewa might choke on it
	s/([^aeiouyóCc\s\b])h([aeiouyó])/$1$2/g; # remove h after consonant before vowel, but not after c!!
	s/([aoóu])h([aou])/$1ł$2/gi; 
	s/eho(\b)/oło$1/gi;
	s/([ei])h([aoui])/$1j$2/gi; # to njeklinči idealne za -eho
	s/([aou])hi/$1ji/gi; # druhich -> drujich
 
    } 


    s/(\b)w([uo])/$1$2/gi; # w > 0 na spočatku słowa
    
    s/ww/w/gi;
    #s/w([^i])/ł$1/gi; -> hakle na kóncu w -> ł


#    s/ej /eji /gi; fixed otherwise

    # ó a ě stej won, ¨nowe¨ i hišće njejsu nutřka, potajkim je kóždy wokal tež złóžka
    # dyrbi so pak prawje identifikować
    # s/ ([^aeiouy]*)([aeiouy])/ *$1$2*/gi;

    if ( ! $hsb ) {
	s/([^c])h /$1 /gi; # h na kóncu slowa
    }

    s/ŕ/r/gi;
    s/(\b)k\s/$1k/gi; # k tomu > ktomu

    s/tśi/ci/gi;
    s/tś([aeouyě])/ci$1/gi;
    s/tś/ć/gi;

    s/([pk])ři/$1szji/gi; # hsb tř dyrbi so ekstra činić
    s/([pk])ř/$1sz/gi;
    s/tř([io])/tsj$1/gi;
    s/třa/cza/gi;
    s/třěsk/ciysk/gi;
    s/třeć/tsejcz/gi;
    s/tře/cie/gi;

    # s/miy/mie/gi; # miy Ewa pismikuje
    s/ě/ie/gi; # iy klinči lěpje hač ie 

    s/ć([aěeouó])/ci$1/gi;
    s/ś([aěeouó])/si$1/gi;
    s/ź([aěeouó])/zi$1/gi;


    s/ći/ci/gi;
    s/śi/si/gi;
    s/źi/zi/gi;

    s/š/sz/gi;
    s/č/cz/gi;
    s/rz/rZ/gi; # RZ: haj, wulke z, zo by Ewa to jako r-z čitała
    s/ž/rz/gi;
    s/šć/szcz/gi;

    # velars
    s/(\s)k(\s)/$1k/gi; # fix preposition k
    s/([kg])e/$1ie/gi;

    # misc

    if ( $hsb ) {
	s/módr/modr/gi;
	s/wóń/łujn/gi;
	s/óh$/oł/gi;  # h we wuzwuku
	s/([^c])h([^aeiouyěó ])/$1$2/gi; # h před konsonantom
	s/(\b)chc/$1c/gi;   # chcyć
	s/(\b)ch/$1k/gi; # TODO prefiks + ch faluje hišće
	for (my $i = 0; $i <= $#prefiksy; $i++ ) {
	    s/($prefiksy[$i])ch([^c.,;:!?])/$1k$2/gi;
	}
    } else {
	s/ó/e/gi; # important, this must come after ->velars
    }
    s/([ri])ch/$1ś/gi; # ch po i

    s/lě/ly/gi;


    # złóžki dźělić

# złóžki dźělić
# ma słowo wjace hač dwě złóžce? jeli haj, po druhej złóžce dźělić
# wjele wuwzaćow: ilustracija funkcija atc
# nowa ideja !!!!! if syllable count is >2 hack into individual syllables

# hišće wopak: riednuszki-ma, obpsiestrie-łał, małuszko-łyma uza-pinany, sierzko-złotymi nadejszłe-ji FIXED

# najlěpje klinči: do niese siu/chu, łoni so łuło pra szowa chu

    # three syllables
    # kaž so zda, je ł problem,
    if ( $debug ) {
	printf(STDERR "DEBUG 1: %s\n", $_);
    }

    # třizłóžkowe słowa so dźěla baba-ba dla přizwukowanja
    # wugronjenju tej byś > ugro-nie-niu
    # slědowace dybi być default, jeli njeje hižo smužka w słowje 
    # tejma, tejmati- termino- kpez-niejsze-mu je wjele lěpje - snano prosće smužka před kóncowku ....? přikłady su horjeka nutřka

    # s/go(\b)/-go$1/gi;
    #s/mu(\b)/-mu$1/gi;
    
    #s/mi(\b)/-mi$1/gi;

    #s/li(\b)/-li$1/gi;

    #s/ni(\b)/-nji$1/gi;
    

    #s/([^\b])ni([aeu]\b)/$1-ni$2/gi; # BUGGY for d-nia
    #s/(\bd)-ni/$1ni/gi; # FIX the bug

    # psiemy-slołał-ła je naš cil za Ewu

    #s/aw([ao]\b)/ał-ł$1/gi;
    #s/([ou])w([ao]\b)/$1-ł$2/gi;

    #s/([ao])wa(.\b)/$1ł-ła$2/gi; # rozeznał-łać

    # RZ ale rz dyrbi so nětko někak škitać
    s/r-z/-rz/gi;
    s/s-z/-sz/gi; # fixing some things like that is easier
    s/z-w/-zw/gi; # 


    s/([a-z]) we /$1, we /gi; # dirty fix for weird contraction (must be done here since class doesn´t work with ł)

    s/w/ł/gi;
    
    if ( $debug ) {
	printf(STDERR "DEBUG 2: %s\n", $_);
    }


    # TODO: cyły tekst přečitać (buffer powjetšić?)
    # TODO: integracija z OS

    # TODO: jednotliwe pismiki (wulke pismiki) a druhe znamješka přečitać (opcija za interpunkciju -snano potom z druhim hłosom)
    # TODO: telefonowe čisła přečitać

    # insert sth befor interpunktion (DONE)



    # fix stuff quick and dirty for (some) prepositions and pronouns
    if ( $hsb ) {
	s/ ł / /gi; # delete w -> 0 hsb (we njeklinči derje)
    } else {
	s/ ł / łe /gi; 
	s/ (łe|łet|pe|za|na) (niej|niom|nas|was|mnio)/ $1$2/gi;
	s/ (łe|łet|pe|za|na) (naju|nama|waju|wama|wami|nami|mnio|tebie)/ $1$2/gi;
	s/ (łe|łet|pe|za|na) (na|wa)ju/ $1$2-ju/gi;
	s/ (łe|łet|pe|za|na) (wa|na)mi/ $1$2-mi/gi;
	s/ (łe|łet|pe|za|na) (t[oy]m?)/ $1$2/gi;
	s/ (łe|łet|pe|za|na) mn(io|u)/ $1mn$2/gi;
	s/ (łe|łet|pe|za|na) t(e|o)b(u|ie)/ $1t$2-b$3/gi;
    }

    s/(\b)(na|psze|za) szo(\b)/$1$2łszo$3/gi; # na wšo etc., wote wšeho etc. faluje

    if ( $hsb ) {
	s/(po|łu)słje(-?ci)/$1słej$2/gi; #poswjećić
	s/łja/ja/gi;
	s/łje/łe/gi;
    }else {
	# fix errors for apple tts: nagej -> nag(aogonek)
	# s/ej /e ji /gi; this gets now fixed much better by nagej -> nagiej
	s/ ak / ak/gi;
	s/pe droze/pedro-ze/gi;	
	s/słiet/sjiet/gi;
	s/kienrz/kencz/gi;
	s/ziołcz/ziułcz/gi;
    }


    s/ lił/ wlił/gi;
    # s/([^ ])łi/$1łwi/gi;
    s/łi/wi/gi;
    s/ łers/ wers/gi;
    s/ nałi/nawi/gi; # nawigacija etc.
    s/ pozic/pozjic/gi;
    s/kultu-r/kultur/gi;
    s/leksi/leksji/gi;
    s/konto-l/kon-trol/gi;
    s/sakra/zakra/gi;

    s/skie-go /skieg /gi;
    # s/e-go /e-go, /gi;  # dirty fix for weird contraction
    s/-bn/b-n/gi;

    #BUGGY: njewotwisnje wot licby, ale originalna Ewa na to tež njekedźbuje
    #BUGGY: dyrbi k tamnym skrótsenjam
    s/(\b)km²/$1kwadratnych kilomejtroł/gi;
    s/(\b)mm²/$1kwadratnych milimejtroł/gi;
    s/(\b)dm²/$1kwadratnych decimejtroł/gi;
    s/(\b)m²/$1kwadratnych mejtroł/gi;

    s/(\b)km(\b)/$1kilomejtroł$2/gi;
    s/(\b)mm(\b)/$1milimejtroł$2/gi;
    s/(\b)dm(\b)/$1decimejtroł$2/gi;
    s/(\b)m(\b)/$1mejtroł$2/gi;

    #s/(\b)na pś\.(\b)/$1na pśikład$2/gi; # njefunguje ????
    # s/na pś\./na pśikład/gi; # njefunguje ????

    # clean up
    s/--/-/g;
    s/-zia /zia /g;

    s/ +\././gi;

    if ( $hsb ) {
	s/dzierz/dziejsz/gi;
    }

  
    #@words = split(/ +/);
    #for ( my $i = 0; $i <= $#words; $i++) {

      # TODO: check whether it is an exeption !!!
      # then it should contain a hyphen or ´#´ as a marker for the accentuated syllable
      # in this case the hyphen before the # will not be deleted, the one after will, the next one will not
      # then the hash has to be removed
      # TODO: Prawidła horjeka, kiž manimuluja smužki, dyrbja 
      # gra#tulowacymi -> gra#tu-lo-wa-cy-mi gratulo-....

      # the following gets called 500 lines earlier as first thing so
      #we can work with Sorbian orthography
      ## $hyphenated = check_hyph_exception($words[$i]);
      ## $hyphenated =  $hyp->visualize($hyphenated);
      
  #    $hyphenated =  $hyp->visualize($words[$i]);

      # this has then to be pruned
   #   $hyphenated = optimise_hyphens($hyphenated);

   #   s/$words[$i]/$hyphenated/; # this is principielly buggy, but we might get away with it ...
  #  }

    print $outfile_h $_;
    
    if ( $debug ) {
      print STDERR "DEBUG: ", $_, "\n";
    }

    
    if ( ! $mute ) {
	system("say", $_, "\n" ); #ZMYLK: Input text is not UTF-8 encoded ????
    }
}
