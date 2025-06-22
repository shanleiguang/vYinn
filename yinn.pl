#!/usr/bin/perl
#中文古籍印章设计与制作工具 V1.0
#by shanleiguang, 2025,06
use strict;
use warnings;

use Image::Magick;
use Font::FreeType;
use Getopt::Std;
use Encode;
use utf8;

binmode(STDIN, ':encoding(utf8)');
binmode(STDOUT, ':encoding(utf8)');
binmode(STDERR, ':encoding(utf8)');

my %opts;

getopts('tc:', \%opts);

if(not defined $opts{'c'} or not -f "config/$opts{'c'}.cfg") {
	print "error: no config, ./$0 -c 01\n";
	exit;
}

my $cid = $opts{'c'};
my $content;

open CONFIG, "< config/$cid.cfg";
{ local $/ = undef; $content = <CONFIG>; }
close(CONFIG);
$content =~ s/\/\n//g;

my @lines = split /\n/, $content;
my %yin;
foreach (@lines) {
	chomp;
	next if(m/^\s{0,}$/);
	next if(m/^#/);
	s/#.*$// if(not m/=#/);
	s/\s//g;
	my ($k, $v) = split /=/, $_;
	$v = decode('utf-8', $v);
	$yin{$k} = $v;
}

my ($cw, $ch, $cb, $cts) = ($yin{'canvas_width'}, $yin{'canvas_height'}, $yin{'canvas_background_image'}, $yin{'canvas_testline_spacing'});
my ($fac, $ft, $fw, $fh) = ($yin{'frame_autocrop'}, $yin{'frame_type'}, $yin{'frame_width'}, $yin{'frame_height'});
my ($fsr, $fcr, $flw) = ($yin{'frame_square_radius'}, $yin{'frame_circle_radius'}, $yin{'frame_line_width'});
my ($fea, $feb) = ($yin{'frame_ellipse_a'}, $yin{'frame_ellipse_b'});
my ($ytext, $ytype, $yfont, $ytsw) = ($yin{'yin_text'}, $yin{'yin_type'}, $yin{'yin_font'}, $yin{'yin_text_strokewidth'});
my ($ytc, $ybc) = ($yin{'yin_text_color'}, $yin{'yin_background_color'});
my ($rows, $cols) = ($yin{'test_rows'}, $yin{'test_cols'});
my @ycoords = split /\|/, $yin{'yin_coords'};
my @yfsizes = split /\|/, $yin{'yin_font_size'};
my @ytrans = split /\|/, $yin{'yin_trans'};
my ($ebr, $ebs) = ($yin{'effect_blur_radius'}, $yin{'effect_blur_sigma'});
my ($ev, $eo) = ($yin{'effect_vintage'}, $yin{'effect_oilpaint'});
my ($esr, $esi) = ($yin{'effect_spread_radius'}, $yin{'effect_spread_interpolate'});

#画布图层
my $yimg = Image::Magick->new();

$yimg->Set(size => $cw.'x'.$ch);
$yimg->ReadImage('canvas:black'); #画布背景黑色

#-t模式，打印辅助线
if($opts{'t'}) {
	foreach my $i (0..int($cw/$cts)) {
		$yimg->Draw(primitive => 'line', points => get_2points($cts*$i, 0, $cts*$i, $ch), stroke => '#999999', strokewidth => 1);
		$yimg->Annotate(text => $i, font => 'Courier', pointsize => 20, x => $cts*$i-30, y => 20, fill => 'white');
	}
	foreach my $j (0..int($ch/$cts)) {
		$yimg->Draw(primitive => 'line', points => get_2points(0, $cts*$j, $cw, $cts*$j), stroke => '#999999', strokewidth => 1);
		$yimg->Annotate(text => $j, font => 'Courier', pointsize => 20, x => 10, y => $cts*$j-5, fill => 'white');
	}
}

#印章草稿背景、前景色
my $ybcolor = ($ytype == 0) ? 'white' : 'black';
my $yfcolor = ($ytype == 0) ? 'black' : 'white';
#印框图层，框线等同文字
my $fimg = Image::Magick->new();

$fimg->Set(size => $fw.'x'.$fh);
$fimg->ReadImage("canvas:$ybcolor");
#打印印框
if($ft == 0) { #圆形
	$fimg->Draw(primitive => 'rectangle', points => get_2points(0,0,$fw,$fh), fill => $yfcolor);
}

if($ft == 1) { #方形
	$fimg->Draw(primitive => 'rectangle', points => get_2points($flw/2,$flw/2,$fw-$flw,$fh-$flw),
		fill => $ybcolor, stroke => $yfcolor, strokewidth => $flw);
	$yimg->Composite(image => $fimg, x => ($cw-$fw)/2, y => ($ch-$fh)/2);
}

if($ft == 2) { #圆角方形
	if($ytype == 0) {
		$fimg->Draw(primitive => 'rectangle', points => get_2points(0,0,$fw,$fh), fill => $yfcolor);
	}
	if($ytype == 1) {
		$fimg->Draw(primitive => 'roundRectangle', points => get_3points(0,0,$fw,$fh,$fsr,$fsr), fill => $yfcolor);
	}
	$fimg->Draw(primitive => 'roundRectangle', points => get_3points($flw,$flw,$fw-$flw,$fh-$flw,$fsr,$fsr), fill => $ybcolor);
	$yimg->Composite(image => $fimg, x => ($cw-$fw)/2, y => ($ch-$fh)/2);
}

if($ft == 3) { #椭圆形
	$fimg->Draw(primitive => 'ellipse', 
        points => get_points_ellipse($fw/2, $fh/2, $fea, $feb),
        fill => $ybcolor,
        stroke => $yfcolor,
        strokewidth => $flw,
        antialias => 'true'
    );
    $yimg->Composite(image => $fimg, x => ($cw-$fw)/2, y => ($ch-$fh)/2);
}

#-t模式，打印辅助线
if($opts{'t'}) {
	my ($ftw, $fth) = (($fw-$flw*2)/$cols, ($fh-$flw*2)/$rows);
	foreach my $i (0..$rows) {
		my $ly = ($ch-$fh)/2+$flw+$fth*$i;
		$yimg->Draw(primitive => 'line', points => get_2points(0,$ly,$cw,$ly), stroke => 'red', strokewidth => 1);
		$yimg->Annotate(text => 'y:'.int($ly), font => 'Courier', pointsize => 20, x => ($cw-$fw)/2-100, y => $ly-10, fill => 'white');
	}
	foreach my $j (0..$cols) {
		my $lx = ($cw-$fw)/2+$flw+$ftw*$j;
		$yimg->Draw(primitive => 'line', points => get_2points($lx,0,$lx,$ch), stroke => 'red', strokewidth => 1);
		$yimg->Annotate(text => 'x:'.int($lx), font => 'Courier', pointsize => 20, x => $lx, y => 50+($ch-$fh-$flw*2-100)/2/$cols*$j, fill => 'white');
	}
	my ($iw, $ih, $is) = (300, 80, 15);
	my ($ix, $iy) = ($cw-$iw-20, $ch-$ih-20);
	$yimg->Draw(primitive => 'rectangle', points => get_2points($ix, $iy, $ix+$iw, $iy+$ih), fill => 'white');
	$yimg->Annotate(text => "Canvas size: $cw x $ch", font => 'Courier', pointsize => $is, x => $ix+10, y => $iy+$is, fill => 'black');
	$yimg->Annotate(text => "Frame  size: $fw x $fh", font => 'Courier', pointsize => $is, x => $ix+10, y => $iy+$is*2, fill => 'black');
	$yimg->Annotate(text => "Frame line width: $flw", font => 'Courier', pointsize => $is, x => $ix+10, y => $iy+$is*3, fill => 'black');
	$yimg->Annotate(text => "Characters number: $rows x $cols", font => 'Courier', pointsize => $is, x => $ix+10, y => $iy+$is*4, fill => 'black');
	$yimg->Annotate(text => "Yinn type: $ytype", font => 'Courier', pointsize => $is, x => $ix+10, y => $iy+$is*5, fill => 'black');
} else {
	$yimg->Spread(radius => $esr, interpolate => $esi) if($esr and $esi); #添加印框边缘扩散效果
}

#打印印文文字
my @ychars = split //, $ytext;
my $freetype = Font::FreeType->new;
my $face = $freetype->face($yfont);

foreach my $cid (0..$#ychars) {
	my $cfs = $yfsizes[$cid];
	my $char = $ychars[$cid];
	my ($cwr, $chr, $crd) = split /\,/, $ytrans[$cid];

	$face->set_char_size($cfs, $cfs, 72, 72);
	#获取该字体文字图像的对齐上、左对齐数值
	my $glyph = $face->glyph_from_char($char);
	my $la = $glyph->left_bearing();
	my $ra = $glyph->right_bearing();
	my $va = $glyph->vertical_advance();
	#print "$char -> $la, $ra, $va\n";
	#每个字创建独立的图层
	my $cimg = Image::Magick->new();
	my ($chw, $chh) = ($cfs, $cfs+$va);

	$cimg->Set(size => $chw.'x'.$chh);
	$cimg->ReadImage('canvas:transparent');
	$cimg->Annotate(text => $char, font => '@'.$yfont, pointsize => $cfs, x => -$la, y => $cfs,
		fill => $yfcolor, stroke => $yfcolor, strokewidth => $ytsw, antialias => 'true', rotate => $crd);
	$cimg->AdaptiveResize(width => $chw*$cwr, height => $chh*$chr);
	$cimg->Edge(radius => 2.2) if($ev and rand(1) >= 0.75);
	$cimg->Write("tmp/$char$cid.png");
	my ($cx, $cy) = split /,/, $ycoords[$cid];

	$yimg->Composite(image => $cimg, x => $cx, y => $cy);
}

if(not $opts{'t'}) {
	if($ev == 1) { #做旧做残，增加随机大小的椭圆斑点图层
		my $pnum = 100;
		foreach my $i (1..$pnum) {
	    	my ($px, $py) = (int(rand($cw)), int(rand($ch)));
	    	my $size = 10+int(rand(10));    
	    	my $point = Image::Magick->new();
	    	my $pcolor = ($ytype == 0) ? $yfcolor : $ybcolor;

	    	$point->Set(size => $size.'x'.$size);
	    	$point->ReadImage('canvas:transparent');
	    	$point->Draw(primitive => 'ellipse', 
	        	points => get_points_ellipse($size/2, $size/2, $size*0.3, $size*0.2),
	        	fill => $pcolor, 
	    	);
	    	$point->Rotate(degrees => rand(45)-22.5);
	    	$point->OilPaint(radius => 1.5);
	    	$point->AdaptiveBlur(radius => 2.2, sigma => 1, bias => -1);
	    	$yimg->Composite(image => $point, x => $px-$size*0.4, y => $py, compose => 'Multiply');
		}
	}

	#印稿黑白色替换为印章设置的背景、前景色
	$yimg->AutoThreshold('OTSU');
	$yimg->Colorspace('RGB');
	$yimg->Opaque(color => 'white', fill => $ytc, invert => 'false');
	$yimg->Opaque(color => 'black', fill => $ybc, invert => 'false');
	#添加模糊、油墨效果
	$yimg->AdaptiveBlur(radius => $ebr, sigma => $ebs) if($ebr and $ebs);
	$yimg->OilPaint(radius => $eo) if($eo);
	#切除印框外的画布
	if($fac) {
		$yimg->Crop(width => $fw+4, height => $fh+4, x => ($cw-$fw)/2-2, y => ($ch-$fh)/2-2);
	}
	#如果印底为透明色且设置了宣纸背景图片，则单独生成一张宣纸背景的效果图
	if($cb and $ybc =~ m/^transparent$/i) {
		my $paper = Image::Magick->new();
		$paper->ReadImage($cb);
		$paper->Crop(width => $cw, height => $ch, x => rand(100), y => rand(100));
		$paper->Composite(image => $yimg);
		$paper->Write('image/'.$cid.'_'.$ytype.'_paper.jpg');
	}
}

my $yinfn = $cid.'_'.$ytype;

$yinfn.= '_test' if(defined $opts{'t'});
$yimg->Write("image/$yinfn.png");

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

