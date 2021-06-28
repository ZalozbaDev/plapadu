#!/usr/local/bin/perl -w -I/Users/edi/Documents/Projekty/tts
# Edward Wornar, 2020

# Published under the GNU Public License

# Scans input text for balanced espressions (possible citations in different languages)
# and uses hunspell to determine the languages

use strict;
use warnings;


use utf8;
use open ":encoding(utf8)";
use open IN => ":encoding(utf8)", OUT => ":utf8";

use File::Temp qw/ tempfile tempdir /;

# initialize temporary file

my ($dir, $mydir, $fh, $filename, $suffix, $template);

$mydir = './plapadu-tmp';
mkdir $mydir unless -d $mydir;

$suffix = '.tmp';

$template = 'plap_XXXXXXX';

$dir = tempdir ( DIR => $mydir, CLEANUP => 1);



# use Text::Balanced; This does not work on my computer
# use Text::Hunspell; This does not build on my computer
# falling back to 

my $debug = 0;

chdir "/Users/edi/Documents/Projekty/tts"; # working directory

my @languages = ("hsb_DE", "dsb_DE", "de_DE", "en_GB"); # languages to be checked
my @lang_command = ("./hsb-tts.pl --infile", "./dsb-tts.pl --infile", " say -v Anna --input-file", "say -v Serena --input-file");

my @spellers;

my $extracted;
my $remainder;
my $prefix;


my $best_lang = 10000; # the language which gives least unknown words
my $best_result = 10000;
my @result;


# decision time: if we work with temp files
# we can just write everything and don´t have to clean the string
# but if we do, we can write ´spinku wočinić´  za ´(´ which is nice for reading
# unless, of course the bits occur in non-Sorbian texts ...
# so the @special_char_sub stuff should be language-dependent

my @special_chars =  ('\(','\)', '\[', '\]', '\<', '\>', '\{', '\}', '\`', '\"', '\*', '\/' ); #, '\!', '\?' );
my @special_chars_sub = (", kuloj tu spinku wočinć, ",
			 ", kuloj tu spinku začinć, ",
			 ", róžkoj tu spinku wočinć, ",
			 ", róžkoj tu spinku začinć, ",
			 ", kónčkoj tu spinku wočinć, ",
			 ", kónčkoj tu spinku začinć, ",
			 ", kwakla tu spinku wočinć, ",
			 ", kwakla tu spinku začinć, ",
			 ", bektik, ",
			 ", pazorki, ",
			 ", fěška, ",
			 ", nakos nasmužka, ",
			# ", prašak ",
			# ", wuwo łak"
			);

sub clean_string {
  my $string = $_[0];
  for ( my $i = 0; $i <= $#special_chars; $i++ ){
    $string =~ s/$special_chars[$i]/$special_chars_sub[$i]/g;
    
  }
  return $string;
}


my @kuski;
my @rece;

sub analyze_string {
  my $string = $_[0];
  my $lang;
  my $i;

  @kuski = ();
  @rece = ();
  
  $string =~ s/\#\!\#//g; # naša rezerwowana sekwenca 
  
  for ( $i = 0; $i <= $#special_chars; $i++ ){
    $string =~ s/$special_chars[$i]/\#\!\# $special_chars_sub[$i] \#\!\#/g;
  }

  # nětko na př.: to je # róžkatu spinku wočinć # zaso zno # róžkatu spinku začinić # to samsne.
  push(@kuski, split(/ *\#\!\# */, $string )); # now $kuski[2n-1] are Sorbian, the others have to be determined.
  
  for ( $i = 0; $i <= $#kuski; $i++ ) {
    $lang = check_language($kuski[$i]);
    if ( $lang != -1 ) { # check_language returns -1 for an empty string
      push( @rece, $lang );
      $i++; # we already know this one :-)
      push( @rece, 0 ); # 0 == horjoserbsce
    } else { # empty string so we throw this out and shorten @kuski
      splice( @kuski, $i, 1, ()); # now we are looking at the hsb bit
      push( @rece, 0 );
    }
  }
}

sub read_bits_aloud {
  my $tempfile;
  for ( my $i = 0; $i <= $#kuski; $i++ ) {
    # safest is tempfile again
    $tempfile = write_string_to_tempfile( $kuski[$i] );

    print STDERR "Reading aloud: ", $lang_command[$rece[$i]], " ", $tempfile, "\n";
    system "$lang_command[$rece[$i]] $tempfile";
  } 
}

sub write_string_to_tempfile { # takes string and returns tempfilename
  my $string = $_[0];
  my ($fh, $filename) = tempfile($template,
			       DIR => $dir,
			       SUFFIX => $suffix,
			      );

   print $fh $string;
   close($fh);

  return( $filename );
}

sub plapadu {
  my $string = $_[0];
  analyze_string( $_[0] );
  read_bits_aloud();
  # plapadu_cleanup();
}

sub check_language { # returns an integer, index of @languages which matches best
  my $string = $_[0];
  my $clean_string = $string;
  # $clean_string =~ s/[\(\)\[\]\<\>\$\%\`]/ /g; # so the echo command does not make bash choke
  # although it shouldn´t be a problem
  # well it is also for ?!' and all this stuff, so we have to work with tmp files!!!!
  
  my $tempfile;

  if ( $clean_string =~ m/^\s*$/ ) {
    return(-1); # empty string
  }
  $tempfile = write_string_to_tempfile( $clean_string );
  
  $best_result = 10000;
  $best_lang = 10000;
  for ( my $i = 0; $i <= $#languages; $i++ ) {
    if ( $debug ) {
      print STDERR "Checking for ", $languages[$i], " ... ";
    }
    my @result = `hunspell -d $languages[$i] -l $tempfile`;
    # my @result = `echo $clean_string^D | hunspell -d $languages[$i] -l`; # the Ctrl-D is important so the hunspell exits right away
    if ( $debug ) {
      print STDERR "\$\#result = ", $#result, "\n";
    }
    if ( $#result < $best_result ) {
      $best_result = $#result;
      $best_lang = $i;
      if ( $debug ) {
	print STDERR "\$best_lang = ", $best_lang, "\n";
      }
    }
    if ( $#result == -1 ) { # no unknown words in language $i
      print STDERR "Definite match: ", $languages[$best_lang], ": ";
      return($best_lang);
    }
  }
  print "Best match: ", $languages[$best_lang], ": ";
  return($best_lang);
}

my @tts_lang;
my @clean_string;

print STDERR <<EOF;
Plapadu, wrapper za multilingualne čitanje za serbskeho wužiwarja.
Wersija 0.1 
Edward Wornar, 2020
Zapodaj 
          plapadu wotleći

za porjadne zakónčenje (hewak wostanu dataje w plapadu-tmp).

EOF

while(<>){
  chomp();
  if ( $_ =~ m/plapadu wotleći/g ) {
    last;
  }
  plapadu($_);
}

 #  # should split into sentences and test them
#   # then split those for possible quotations
#   # (should also be done for bold and italic text)
#   # repeat with prefix, extracted and remainder until nothing is extracted any more
#   # needs to be reordered to get rid of the pauses between two bits
  
#   if (( $_ =~ m/([^\']*)\'([^\']+)*\'([^\']*)/ ) || ( $_ =~ m/([^\"]*)\"([^\"]+)*\"([^\"]*)/ )) {
#     $tts_lang[0] = check_language($1);
#     $tts_lang[1] = check_language($2);
#     $tts_lang[2] = check_language($3);
#     print $1, "\n";
#     # for the next bit we either have to work with temp files or clean up the strings
#     # maybe we want things like 'spinku wočinić´
#     # problem: tute wěcy so přez clean_string() nutř dóstanu, ale potom so njerespektuje, dokelž
#     # móže tts_lang[x] něšto druhe być hač serbšćina
#     # snano móže clean_string dwaj arrayej wróćić, jedyn z kuskami a jedyn z rěčemi, na př.
#     # @kuski = ( )
#     # @rece = ( );
#     # abo pjelnimy tu globalnej arrayjej
#     #
    
#     $clean_string[0] = clean_string($1);
#     print "Extracted: ", $2, "\n"; # could be a different language
#     $clean_string[1] = clean_string($2);
#     print  $3, "\n";
#     $clean_string[2] = clean_string($3);
    
#     `echo $clean_string[0] | $lang_command[$tts_lang[0]]`;
#     `echo $clean_string[1] | $lang_command[$tts_lang[1]]`;
#     `echo $clean_string[2] | $lang_command[$tts_lang[2]]`;
#   } else {
#     $tts_lang[0] = check_language($_);
#     print $_, "\n";
#     $clean_string[0] = clean_string($_);
#     `echo $clean_string[0] | $lang_command[$tts_lang[0]]`;

#   }
# }

