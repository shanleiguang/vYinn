#!/usr/bin/perl
#从现有印章图片中选取区域，抠图并生成透明底色的印章图片
#by shanleiguang, 2025,06
use strict;
use warnings;

use Image::Magick;
use Getopt::Std;
use Encode;
use utf8;

binmode(STDIN, ':encoding(utf8)');
binmode(STDOUT, ':encoding(utf8)');
binmode(STDERR, ':encoding(utf8)');

my %opts;

getopts('tnves:a:b:c:d:r:', \%opts);

if(not defined $opts{'s'}) {
	print "\terror: no '-s', src yin image!\n"; exit;
}
if(not -f "src/$opts{'s'}") {
	print "\terror: 'src/$opts{'s'}' not exist!\n"; exit;
}

my $sf = $opts{'s'};
my $yc = (defined $opts{'c'}) ? $opts{'c'} : '#874434'; #印文前景色
my $sd = (defined $opts{'d'}) ? $opts{'d'} : 20; #测试辅助线间距，默认为20
my $rd = (defined $opts{'r'}) ? $opts{'r'} : 0; #原图旋转角度，正数为顺时针，默认为0
my ($df, $sw, $sh, $cx, $cy, $cw, $ch);
my $sy = Image::Magick->new();

$sy->ReadImage("src/$sf");

($sw, $sh) = ($sy->Get('Width'), $sy->Get('Height'));
print "$sw x $sh\n";
$sy->Rotate($rd) if(defined $opts{'r'});
($sw, $sh) = ($sy->Get('Width'), $sy->Get('Height'));
print "$sw x $sh\n";

if(defined $opts{'t'}) {
	my $tm = Image::Magick->new();
	my $tl = Image::Magick->new();

	$tm->Set(size => $sw.'x'.$sh);
	$tm->ReadImage('canvas:#999999');
	$tl->Set(size => $sw.'x'.$sh);
	$tl->ReadImage('canvas:transparent');
	foreach my $i (0..int($sw/$sd)) {
		$tl->Draw(primitive => 'line', points => get_2points($sd*$i, 0, $sd*$i, $sh), fill => '#666666');
		$tl->Annotate(text => $i, font => 'Courier', pointsize => $sd/2, x => $sd*$i, y => $sd, fill => 'black');
	}
	foreach my $j (0..int($sh/$sd)) {
		$tl->Draw(primitive => 'line', points => get_2points(0, $sd*$j, $sw, $sd*$j), fill => '#666666');
		$tl->Annotate(text => $j, font => 'Courier', pointsize => $sd/2, x => $sd, y => $sd*$j, fill => 'black');
	}

	if(defined $opts{'a'} and defined $opts{'b'}) {
		($cx, $cy) = split /\,/, $opts{'a'};
		($cw, $ch) = split /\,/, $opts{'b'};
		$tl->Annotate(text => "A($cx,$cy)", font => 'Courier', pointsize => $sd, x => $cx, y => $cy-$sd/2,
			fill => 'black', stroke => 'black', strokewidth => 1);
		$tl->Annotate(text => "B(+$cw,+$ch)", font => 'Courier', pointsize => $sd, x => $cx+$cw, y => $cy+$ch+$sd,
			fill => 'black', stroke => 'black', strokewidth => 1);
		$tl->Draw(primitive => 'rectangle', points => get_2points($cx, $cy, $cx+$cw, $cy+$ch),
			fill => 'transparent', stroke => 'black', strokewidth => 3);
	}

	$sy->Composite(image => $tm, compose => 'Screen');
	$sy->Composite(image => $tl, compose => 'Over');
	$df = (split /\./, $sf)[0].'_test.jpg';
	$sy->Write("src/$df");
	exit;
}

if(defined $opts{'a'} and defined $opts{'b'}) {
	($cx, $cy) = split /\,/, $opts{'a'};
	($cw, $ch) = split /\,/, $opts{'b'};
	$sy->Crop(x => $cx+$sw*$rd/180, y => $cy+$sh*$rd/180, width => $cw, height => $ch);
}

$sy->UnsharpMask(radius => 2, sigma => 1, gain => 1, threshold => 1);
$sy->Negate() if(defined $opts{'n'}); #阴阳文反转
$sy->AutoThreshold('OTSU');
$sy->Colorspace('RGB');
$sy->Opaque(color => 'black', fill => $yc, invert => 'false');
$sy->Opaque(color => 'white', fill => 'transparent', invert => 'false');
if(defined $opts{'v'}) {
	$sy->AdaptiveBlur(radius => 2.2, sigma => 0.5, bias => 1);
	#$sy->Spread(radius => 0.01, interpolate => 'spline');
}
$df = (defined $opts{'n'}) ? (split /\./, $sf)[0].'_ng.png' : (split /\./, $sf)[0].'.png';
$sy->Write("dst/$df");

if(defined $opts{'e'}) {
	my $eb = Image::Magick->new();

	$eb->ReadImage('paper.jpg');
	$eb->Crop(x => 0, y => 0, width => $cw*2, height => $ch*2);
	$eb->Composite(image => $sy, x => $cw/2, y => $ch/2, compose => 'Over');
	$df = (split /\./, $df)[0].'_paper.jpg';
	$eb->Write("dst/$df");
}

sub get_2points {
	my ($x1, $y1, $x2, $y2) = @_;
	return "$x1,$y1 $x2,$y2";
}

sub get_3points {
	my ($x1, $y1, $x2, $y2, $x3, $y3) = @_;
	return "$x1,$y1 $x2,$y2 $x3,$y3";
}

sub get_points_ellipse {
	my ($fx, $fy, $tx, $ty) = @_;
	return "$fx,$fy $tx,$ty 0,360";
}